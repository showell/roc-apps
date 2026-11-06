## Chain finds where the road lies from where the rider is. The chain is the
## line of segments the rider can see, the rider's own first, and a point on
## any segment of it, or on the segment just behind the rider, is carried
## back round the bends between to the rider's own segment and into the
## rider's view.
import Pixels
import Across
import Along
import Distance
import Geom
import Scenery
import World

Chain :: [].{

	## The road in view: the route's segments, the chain of them ahead of
	## the rider, and the rider's vantage.
	RoadView : {
		route : List(World.Segment),
		chain : List(World.SegmentIndex),
		vantage : Geom.Vantage,
	}

	## What a frame is seen from: the road in view, and the camera's focal
	## length in pixels.
	Viewpoint : { road : Chain.RoadView, cam_focal : Pixels }

	## A segment's place in the chain, counted from the rider's own at 0. It
	## says how many segments ahead of the rider that segment is, where a
	## World.SegmentIndex says where it is in the route.
	Position :: U32.{

		number : U32 -> Chain.Position
		number = |n| Chain.Position.(n)

		to_i64 : Chain.Position -> I64
		to_i64 = |Chain.Position.(n)| n.to_i64()

		## The rider's own segment.
		first : Chain.Position
		first = Chain.Position.(0)

		next : Chain.Position -> Chain.Position
		next = |Chain.Position.(n)| Chain.Position.(n + 1)

		## Every position in `chain`, the rider's own first.
		all_in : List(World.SegmentIndex) -> List(Chain.Position)
		all_in = |chain|
			List.from_iter(U32.until(0, chain.len().to_u32_wrap())).map(Chain.Position.number)

		## The segment at this position in `chain`.
		index_in : Chain.Position, List(World.SegmentIndex) -> World.SegmentIndex
		index_in = |Chain.Position.(n), chain|
			chain.get(n.to_u64()) ?? crash "Chain.Position.index_in: past the chain's end"

		## The segments of `chain` before this position, the rider's own first.
		before_in : Chain.Position, List(World.SegmentIndex) -> List(World.SegmentIndex)
		before_in = |Chain.Position.(n), chain| chain.take_first(n.to_u64())

		## Whether this position is the last one in `chain`.
		is_last_in : Chain.Position, List(World.SegmentIndex) -> Bool
		is_last_in = |Chain.Position.(n), chain| n.to_u64() + 1 >= chain.len()

		## Whether `chain` stops before this position.
		is_past_end_of : Chain.Position, List(World.SegmentIndex) -> Bool
		is_past_end_of = |Chain.Position.(n), chain| n.to_u64() >= chain.len()

		## Whether this position is among the first `count` of a chain.
		is_within_first : Chain.Position, U32 -> Bool
		is_within_first = |Chain.Position.(n), count| n < count

		is_eq : _
	}

	## Where a segment lies from the rider: at a position in the chain, or
	## just behind the rider, round the bend into the rider's segment.
	SegmentPlace : [InChain(Chain.Position), JustBehind(Geom.Bend)]

	## The most segments a chain holds.
	max_length : U32
	max_length = 7

	## The segment the rider is on, which is the chain's first.
	rider_segment : Chain.RoadView -> World.SegmentIndex
	rider_segment = |road| Chain.Position.first.index_in(road.chain)

	## The segment behind the rider's, unless the rider's is the route's first.
	segment_behind : Chain.RoadView -> [Previous(World.SegmentIndex), AtRouteStart]
	segment_behind = |road| rider_segment(road).previous()

	## How far ahead of the rider the segment at `position` in the chain starts.
	## The segments' lengths are added nearest first.
	gap_to_segment : Chain.RoadView, Chain.Position -> Distance
	gap_to_segment = |road, position|
		position.before_in(road.chain).fold(
			road.vantage.along.from_start().opposite(),
			|gap, index| gap.plus(index.segment_in(road.route).length),
		)

	## The chain from the segment at `start`: as far as the rider can see, or
	## to the route's end.
	chain_ahead : List(World.Segment), World.SegmentIndex -> List(World.SegmentIndex)
	chain_ahead = |route, start| chain_onto(route, { index: start, chain: [] })

	## The bend at the end of `segment`.
	bend_out_of : World.Segment -> Geom.Bend
	bend_out_of = |segment| {
		segment_length: segment.length,
		turn: segment.exit_turn,
		road_width: Scenery.road_width,
	}

	## The place of `segment`, which is just behind the rider.
	place_behind : World.Segment -> Chain.SegmentPlace
	place_behind = |segment| JustBehind(bend_out_of(segment))

	## A point on the segment at `position` in the chain, in the rider's view.
	rider_point_ahead : Chain.RoadView,
	{
		position : Chain.Position,
		along : Along,
		across : Across,
	} -> Geom.RiderPoint
	rider_point_ahead = |road, { position, along, across }| {
		on_rider_segment = position.before_in(road.chain).fold_rev(
			edge_point({ along, across }),
			|index, point| Geom.in_segment_before(point, bend_out_of(index.segment_in(road.route))),
		)
		Geom.to_rider_point(on_rider_segment, road.vantage)
	}

	## A point on the segment at `place`, in the rider's view.
	rider_point_at : Chain.RoadView,
	{
		place : Chain.SegmentPlace,
		along : Along,
		across : Across,
	} -> Geom.RiderPoint
	rider_point_at = |road, { place, along, across }|
		match place {
			InChain(position) =>
				rider_point_ahead(road, { position, along, across })
			JustBehind(bend) => {
				on_segment_behind = edge_point({ along, across })
				Geom.to_rider_point(Geom.in_segment_after(on_segment_behind, bend), road.vantage)
			}
		}
}

## A road point, measured from the lane's left edge.
edge_point : Geom.RoadPoint -> Geom.EdgePoint
edge_point = |{ along, across }| { along, from_left: across.distance_from(Scenery.left_edge) }

## `chain` with the segment at `index` and those after it added, up to the
## limit. An accumulator is linear, where appending a recursive call's answer
## is quadratic.
chain_onto : List(World.Segment),
{
	index : World.SegmentIndex,
	chain : List(World.SegmentIndex),
} -> List(World.SegmentIndex)
chain_onto = |route, { index, chain }|
	if chain.len() >= Chain.max_length.to_u64() {
		chain
	} else {
		longer_chain = chain.append(index)
		match index.segment_in(route).ending {
			Continues({ next }) => chain_onto(route, { index: next, chain: longer_chain })
			Terminates => longer_chain
		}
	}

expect Chain.max_length.to_i64() == 7
expect Chain.chain_ahead(World.segments, World.SegmentIndex.first).len() == 7

route_facts : List(World.Segment) -> List(U64)
route_facts = |segments| [
	segments.len(),
	Chain.chain_ahead(segments, World.SegmentIndex.first).len(),
	Chain.chain_ahead(segments, World.SegmentIndex.number(15)).len(),
	Chain.chain_ahead(segments, World.SegmentIndex.number(18)).len(),
]

expect route_facts(World.segments) == [19, 7, 4, 1]

expect Chain.Position.number(3).to_i64() == 3
expect Chain.Position.first.next().to_i64() == 1

expect
	[
		(Scenery.left_edge, 0.0),
		(Across.middle, 2.0),
		(Scenery.right_edge, 4.0),
	].all(|(across, want)| edge_point({ along: Along.start, across }).from_left.to_metres() == want)

expect edge_point({ along: Along.metres(1.0), across: Across.middle }).along == Along.metres(1.0)
