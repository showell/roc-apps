## RailSighting lays out the guard rail at each bend in view. The rail follows
## the outer edge of the road for the last few metres before the bend,
## cuts across the bend's corner to where the two outer edges meet and
## back, and follows the next segment's outer edge for as far again.
import Across
import Along
import DepthSort
import lib.DeviceMath
import Distance
import Chain
import Geom
import GuardRail
import Joint
import Num_
import World

RailSighting :: [].{

	## The rails at every bend in view: the bends along the chain ahead, then
	## the bend from the segment behind.
	all_rails : Chain.RoadView -> List(GuardRail.RailPoly)
	all_rails = |road| {
		bends_ahead = Chain.Position.all_in(road.chain).drop_last(1)
		ahead = bends_ahead.join_map(|position| rails_at(road, bend_after(road, position)))
		match Chain.segment_behind(road) {
			Previous(segment_behind) => ahead.concat(rails_behind(road, segment_behind))
			AtRouteStart => ahead
		}
	}

	## The depth sort's key for each rail quad: how far ahead it is, and its
	## place in the list.
	depth_keys : List(GuardRail.RailPoly) -> List(DepthSort.DepthKey)
	depth_keys = |quads| quads.map_with_index(
		|quad, i| { forward: quad.forward, subject: Rail(i.to_u32_wrap()) },
	)

	## How many steps a leg `distance` long is cut into: one a metre, and at
	## least one.
	leg_steps : F64 -> U32
	leg_steps = |distance| {
		steps = Num_.round_real(distance)
		(
			if steps < 1.0 {
				1.0
			} else {
				steps
			}
		).to_u32_wrap()
	}

	## `steps` + 1 points evenly spaced from `from` to `to`, both included.
	evenly_spaced : {
		from : Geom.RiderPoint,
		to : Geom.RiderPoint,
		steps : U32,
	} -> List(Geom.RiderPoint)
	evenly_spaced = |{ from, to, steps }| {
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
		distance = DeviceMath.real_sqrt(rightward * rightward + forward * forward)
		steps = RailSighting.leg_steps(distance)
		RailSighting.evenly_spaced({ from, to, steps }).drop_first(1)
	}

	## The rail along the last `rail_runout` metres of a segment `length`
	## long, which lies at `place`, at `across`: a point a
	## metre, ending at the segment's end.
	run_up : Chain.RoadView,
	{
		place : Chain.SegmentPlace,
		length : Distance,
		across : Across,
	} -> List(Geom.RiderPoint)
	run_up = |road, { place, length, across }|
		List.from_iter(U32.to(0, GuardRail.rail_runout)).map(
			|metres_in| {
				metres_left = Distance.metres((GuardRail.rail_runout - metres_in).to_f64())
				Chain.rider_point_at(
					road,
					{
						place,
						along: Along.at(length.minus(metres_left)),
						across,
					},
				)
			},
		)

	## The rail along the first `rail_runout` metres of a segment at `place`,
	## at `across`: a point a metre, the first a metre in.
	run_out : Chain.RoadView,
	{
		place : Chain.SegmentPlace,
		across : Across,
	} -> List(Geom.RiderPoint)
	run_out = |road, { place, across }|
		List.from_iter(U32.to(1, GuardRail.rail_runout)).map(
			|metres_in| Chain.rider_point_at(
				road,
				{ place, along: Along.metres(metres_in.to_f64()), across },
			),
		)
}

## The bend at the end of the segment at `position` in the chain.
bend_after : Chain.RoadView, Chain.Position -> Joint.PlacedBend
bend_after = |road, position|
	Joint.bend_out_of(
		position.index_in(road.chain).segment_in(road.world),
		{ before: InChain(position), after: InChain(position.next()) },
	)

## The rails at the bend into the rider's segment from the segment at `index`.
rails_behind : Chain.RoadView, World.SegmentIndex -> List(GuardRail.RailPoly)
rails_behind = |road, index| {
	segment = index.segment_in(road.world)
	before = Chain.place_behind(segment)
	after = InChain(Chain.Position.first)
	rails_at(road, Joint.bend_out_of(segment, { before, after }))
}

rails_at : Chain.RoadView, Joint.PlacedBend -> List(GuardRail.RailPoly)
rails_at = |road, bend| GuardRail.quads_along(rail_path(road, bend))

## The path of the rail at a bend, along the road's outer edge: up to the
## bend, out to where the two outer edges meet, back to the next segment,
## and along it.
rail_path : Chain.RoadView, Joint.PlacedBend -> List(Geom.RiderPoint)
rail_path = |road, bend| {
	outer_edge = Joint.outer_edge(bend.turn)
	end_before = Chain.rider_point_at(
		road,
		{
			place: bend.before,
			along: Along.at(bend.length_before),
			across: outer_edge,
		},
	)
	start_after = Chain.rider_point_at(
		road,
		{
			place: bend.after,
			along: Along.start,
			across: outer_edge,
		},
	)
	apex = Joint.joint_apex(road, bend)
	[
		RailSighting.run_up(
			road,
			{
				place: bend.before,
				length: bend.length_before,
				across: outer_edge,
			},
		),
		RailSighting.rail_leg({ from: end_before, to: apex }),
		RailSighting.rail_leg({ from: apex, to: start_after }),
		RailSighting.run_out(road, { place: bend.after, across: outer_edge }),
	].join()
}

expect
	[
		(0.0, 1),
		(0.4, 1),
		(0.5, 1),
		(1.0, 1),
		(1.4, 1),
		(1.5, 2),
		(2.5, 3),
		(10.0, 10),
		(49.6, 50),
		(50.0, 50),
	].all(|(distance, want)| RailSighting.leg_steps(distance).to_i64() == want)

origin_pt : Geom.RiderPoint
origin_pt = { right: 0.0, forward: 0.0 }

point_at : List(Geom.RiderPoint), U64 -> Geom.RiderPoint
point_at = |points, i| points.get(i) ?? crash "RailSighting: an index past the leg's end"

straight : List(Geom.RiderPoint)
straight = RailSighting.rail_leg({ from: origin_pt, to: { right: 0.0, forward: 10.0 } })

expect straight.len() == 10
expect point_at(straight, 0).forward == 1.0
expect point_at(straight, 4).forward == 5.0
expect point_at(straight, 9).forward == 10.0
expect point_at(straight, 0).right == 0.0
expect point_at(straight, 9).right == 0.0

diagonal : List(Geom.RiderPoint)
diagonal = RailSighting.rail_leg({ from: origin_pt, to: { right: 30.0, forward: 40.0 } })

expect diagonal.len() == 50
expect point_at(diagonal, 49).right == 30.0
expect point_at(diagonal, 49).forward == 40.0
expect point_at(diagonal, 24).right == 15.0
expect point_at(diagonal, 24).forward == 20.0
expect {
	in_place = RailSighting.rail_leg({
		from: { right: 3.0, forward: 4.0 },
		to: { right: 3.0, forward: 4.0 },
	})
	in_place.len() == 1 and point_at(in_place, 0) == { right: 3.0, forward: 4.0 }
}

expect {
	spaced = RailSighting.evenly_spaced({
		from: origin_pt,
		to: { right: 0.0, forward: 10.0 },
		steps: 10,
	})
	spaced.len() == 11
		and point_at(spaced, 0).forward == 0.0
		and point_at(spaced, 10).forward == 10.0
}

expect GuardRail.rail_runout.to_i64() == 10
