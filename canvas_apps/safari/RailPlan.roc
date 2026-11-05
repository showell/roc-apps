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
import Scenery
import World

RailPlan :: [].{

	## The road in view: the world's segments, the chain of them ahead of
	## the rider, and the rider's pose.
	Road : {
		world : List(World.Segment),
		chain : List(I64),
		pose : Frame.Pose,
	}

	## The rails at every bend in view, for a rider on segment `segment` of
	## the world: the bends along the chain ahead, then the bend from the
	## segment behind.
	all_rails : RailPlan.Road, I64 -> List(GuardRail.RailPoly)
	all_rails = |road, segment| {
		bends_ahead = List.from_iter(I64.until(0, (road.chain.len().to_i64_wrap() - 1)))
		ahead = bends_ahead.join_map(|position| rails_at(road, bend_after(road, position)))
		if segment > 0 {
			ahead.concat(rails_behind(road, (segment - 1)))
		} else {
			ahead
		}
	}

	## The depth sort's key for each rail quad: how far ahead it is, and its
	## place in the list.
	rail_items : List(GuardRail.RailPoly) -> List(DepthSort.DepthKey)
	rail_items = |quads| quads.map_with_index(|quad, i| { forward: quad.forward, subject: Rail(i) })

	## How many steps a leg `distance` long is cut into: one a metre, and at
	## least one.
	leg_steps : F64 -> I64
	leg_steps = |distance| {
		steps = Num_.round_real(distance)
		F64.to_i64_wrap(if (steps < 1.0) 1.0 else steps)
	}

	## `steps` + 1 points evenly spaced from `from` to `to`, both included.
	evenly_spaced : {
		from : Geom.RiderPt,
		to : Geom.RiderPt,
		steps : I64,
	} -> List(Geom.RiderPt)
	evenly_spaced = |
		{
			from,
			to,
			steps,
		},
	| {
		dr = (to.right - from.right)
		df = (to.forward - from.forward)
		List.from_iter(I64.to(0, steps)).map(
			|step| {
				t = (step.to_f64() / steps.to_f64())
				{ right: (from.right + (dr * t)), forward: (from.forward + (df * t)) }
			},
		)
	}

	## A leg of rail from `from` to `to`: a point about every metre, the
	## last at `to`, and none at `from`, which ends the leg before it.
	leg : { from : Geom.RiderPt, to : Geom.RiderPt } -> List(Geom.RiderPt)
	leg = |{ from, to }| {
		dr = (to.right - from.right)
		df = (to.forward - from.forward)
		steps = RailPlan.leg_steps(DeviceMath.real_sqrt(((dr * dr) + (df * df))))
		RailPlan.evenly_spaced({
			from,
			to,
			steps,
		}).drop_first(1)
	}

	## The rail along the last `rail_runout` metres of a segment `length`
	## long, which is on the map at `place`, `across` from its left edge: a
	## point a metre, ending at the segment's end.
	run_up : RailPlan.Road,
	{
		place : Frame.Mapper,
		length : F64,
		across : F64,
	} -> List(Geom.RiderPt)
	run_up = |
		road,
		{
			place,
			length,
			across,
		},
	|
		List.from_iter(I64.to(0, GuardRail.rail_runout)).map(
			|metres_in| {
				metres_left = (GuardRail.rail_runout - metres_in)
				on_map(
					road,
					{
						place,
						along: (length - metres_left.to_f64()),
						across,
					},
				)
			},
		)

	## The rail along the first `rail_runout` metres of a segment on the map
	## at `place`, `across` from its left edge: a point a metre, the first a
	## metre in.
	run_out : RailPlan.Road, { place : Frame.Mapper, across : F64 } -> List(Geom.RiderPt)
	run_out = |road, { place, across }|
		List.from_iter(I64.to(1, GuardRail.rail_runout))
			.map(
				|metres_in| on_map(
					road,
					{
						place,
						along: metres_in.to_f64(),
						across,
					},
				),
			)
}

## A turn from one segment into the next: where each segment is on the
## map, how long the one before is, and which way the road turns.
Bend : {
	before : Frame.Mapper,
	after : Frame.Mapper,
	length_before : F64,
	exit_right : Bool,
}

## A point `along` a segment on the map at `place`, `across` from its left
## edge.
on_map : RailPlan.Road,
{
	place : Frame.Mapper,
	along : F64,
	across : F64,
} -> Geom.RiderPt
on_map = |
	road,
	{
		place,
		along,
		across,
	},
| Frame.map_pt(
	{
		world: road.world,
		chain: road.chain,
		pose: road.pose,
	},
	{
		mapper: place,
		along,
		across,
	},
)

## The bend at the end of the segment at `position` in the chain.
bend_after : RailPlan.Road, I64 -> Bend
bend_after = |road, position| {
	index = road.chain.get(position.to_u64_wrap())
		?? crash "RailPlan: a position past the chain's end"
	segment = road.world.get(index.to_u64_wrap())
		?? crash "RailPlan: a chain names a segment the world lacks"
	{
		before: Frame.chain_map(position),
		after: Frame.chain_map((position + 1)),
		length_before: segment.length,
		exit_right: segment.exit_right,
	}
}

## The rails at the bend into the rider's segment from world segment
## `index`.
rails_behind : RailPlan.Road, I64 -> List(GuardRail.RailPoly)
rails_behind = |road, index| {
	segment = road.world.get(index.to_u64_wrap())
		?? crash "RailPlan: the segment behind the rider is past the world's end"
	rails_at(
		road,
		{
			before: Frame.prev_map(segment),
			after: Frame.chain_map(0),
			length_before: segment.length,
			exit_right: segment.exit_right,
		},
	)
}

rails_at : RailPlan.Road, Bend -> List(GuardRail.RailPoly)
rails_at = |road, bend| GuardRail.quads_along(rail_path(road, bend))

## The path of the rail at a bend, along the road's outer edge: up to the
## bend, out to where the two outer edges meet, back to the next segment,
## and along it.
rail_path : RailPlan.Road, Bend -> List(Geom.RiderPt)
rail_path = |road, bend| {
	outer_edge = Joint.outer_cu(bend.exit_right)
	end_before = on_map(
		road,
		{
			place: bend.before,
			along: bend.length_before,
			across: outer_edge,
		},
	)
	start_after = on_map(
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
		RailPlan.leg({ from: end_before, to: apex }),
		RailPlan.leg({ from: apex, to: start_after }),
		RailPlan.run_out(road, { place: bend.after, across: outer_edge }),
	])
}
