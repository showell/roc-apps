## RailPlan lays out the guard rail at each bend in view. The rail follows
## the outer edge of the road for the last few metres before the bend,
## cuts across the bend's corner to where the two outer edges meet and
## back, and follows the next segment's outer edge for as far again.
import DepthSort
import lib.DeviceMath
import Frame
import Geom
import GuardRail
import Joint
import Num_
import World

RailPlan :: [].{

	## The rails at every bend in view: the bends along the chain ahead, then
	## the bend from the segment behind.
	all_rails : Frame.RoadView -> List(GuardRail.RailPoly)
	all_rails = |road| {
		bends_ahead = Frame.ChainPosition.all_in(road.chain).drop_last(1)
		ahead = bends_ahead.join_map(|position| rails_at(road, bend_after(road, position)))
		match Frame.segment_behind(road) {
			Previous(segment_behind) => ahead.concat(rails_behind(road, segment_behind))
			AtRouteStart => ahead
		}
	}

	## The depth sort's key for each rail quad: how far ahead it is, and its
	## place in the list.
	depth_keys : List(GuardRail.RailPoly) -> List(DepthSort.DepthKey)
	depth_keys = |quads| quads.map_with_index(
		|quad, i| {
			forward: quad.forward,
			subject: Rail(i.to_u32_wrap()),
		},
	)

	## How many steps a leg `distance` long is cut into: one a metre, and at
	## least one.
	leg_steps : F64 -> U32
	leg_steps = |distance| {
		steps = Num_.round_real(distance)
		F64.to_u32_wrap(if (steps < 1.0) 1.0 else steps)
	}

	## `steps` + 1 points evenly spaced from `from` to `to`, both included.
	evenly_spaced : {
		from : Geom.RiderPoint,
		to : Geom.RiderPoint,
		steps : U32,
	} -> List(Geom.RiderPoint)
	evenly_spaced = |
		{
			from,
			to,
			steps,
		},
	| {
		rightward = to.right - from.right
		forward = to.forward - from.forward
		List.from_iter(U32.to(0, steps)).map(
			|step| {
				fraction = step.to_f64() / steps.to_f64()
				{
					right: from.right + rightward * fraction,
					forward: from.forward + forward * fraction,
				}
			},
		)
	}

	## A leg of rail from `from` to `to`: a point about every metre, the
	## last at `to`, and none at `from`, which ends the leg before it.
	rail_leg : { from : Geom.RiderPoint, to : Geom.RiderPoint } -> List(Geom.RiderPoint)
	rail_leg = |{ from, to }| {
		rightward = to.right - from.right
		forward = to.forward - from.forward
		steps = RailPlan.leg_steps(DeviceMath.real_sqrt(rightward * rightward + forward * forward))
		RailPlan.evenly_spaced({
			from,
			to,
			steps,
		}).drop_first(1)
	}

	## The rail along the last `rail_runout` metres of a segment `length`
	## long, which lies at `place`, `across` from its left edge: a point a
	## metre, ending at the segment's end.
	run_up : Frame.RoadView,
	{
		place : Frame.SegmentPlace,
		length : F64,
		across : F64,
	} -> List(Geom.RiderPoint)
	run_up = |
		road,
		{
			place,
			length,
			across,
		},
	|
		List.from_iter(U32.to(0, GuardRail.rail_runout)).map(
			|metres_in| {
				metres_left = GuardRail.rail_runout - metres_in
				Frame.rider_point_at(
					road,
					{
						place,
						along: length - metres_left.to_f64(),
						across,
					},
				)
			},
		)

	## The rail along the first `rail_runout` metres of a segment at `place`,
	## `across` from its left edge: a point a metre, the first a metre in.
	run_out : Frame.RoadView, { place : Frame.SegmentPlace, across : F64 } -> List(Geom.RiderPoint)
	run_out = |road, { place, across }|
		List.from_iter(U32.to(1, GuardRail.rail_runout)).map(
			|metres_in| Frame.rider_point_at(
				road,
				{
					place,
					along: metres_in.to_f64(),
					across,
				},
			),
		)
}

## The bend at the end of the segment at `position` in the chain.
bend_after : Frame.RoadView, Frame.ChainPosition -> Joint.PlacedBend
bend_after = |road, position|
	Joint.bend_out_of(
		position.index_in(road.chain).segment_in(road.world),
		{ before: InChain(position), after: InChain(position.next()) },
	)

## The rails at the bend into the rider's segment from the segment at `index`.
rails_behind : Frame.RoadView, World.SegmentIndex -> List(GuardRail.RailPoly)
rails_behind = |road, index| {
	segment = index.segment_in(road.world)
	before = Frame.place_behind(segment)
	after = InChain(Frame.ChainPosition.first)
	rails_at(road, Joint.bend_out_of(segment, { before, after }))
}

rails_at : Frame.RoadView, Joint.PlacedBend -> List(GuardRail.RailPoly)
rails_at = |road, bend| GuardRail.quads_along(rail_path(road, bend))

## The path of the rail at a bend, along the road's outer edge: up to the
## bend, out to where the two outer edges meet, back to the next segment,
## and along it.
rail_path : Frame.RoadView, Joint.PlacedBend -> List(Geom.RiderPoint)
rail_path = |road, bend| {
	outer_edge = Joint.outer_edge(bend.turn)
	end_before = Frame.rider_point_at(
		road,
		{
			place: bend.before,
			along: bend.length_before,
			across: outer_edge,
		},
	)
	start_after = Frame.rider_point_at(
		road,
		{
			place: bend.after,
			along: 0.0,
			across: outer_edge,
		},
	)
	apex = Joint.joint_apex(road, bend)
	List.join([
		RailPlan.run_up(
			road,
			{
				place: bend.before,
				length: bend.length_before,
				across: outer_edge,
			},
		),
		RailPlan.rail_leg({ from: end_before, to: apex }),
		RailPlan.rail_leg({ from: apex, to: start_after }),
		RailPlan.run_out(road, { place: bend.after, across: outer_edge }),
	])
}
