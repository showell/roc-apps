## RoadAhead finds where the road ahead lies, from where the rider is, and
## where the segment just behind the rider lies. The road ahead is the line of
## segments the rider can see, the rider's own first, and a point on any of
## them, or on the segment just behind, is carried back round the bends between
## to the rider's own segment and into the rider's view.
import Pixels
import Across
import Along
import Distance
import Geom
import World

RoadAhead :: [].{

	## The road in view: the route's segments, the indices of those ahead
	## of the rider, and the rider's vantage.
	RoadView : {
		route_segments : List(World.Segment),
		segments_ahead : List(World.SegmentIndex),
		vantage : Geom.Vantage,
	}

	## What the camera sees in a frame: the road in view, and the camera's focal
	## length in pixels.
	CameraView : { road : RoadAhead.RoadView, cam_focal : Pixels }

	## What a thing measured on the road draws from: the road in view, and where
	## on it the thing stands.
	RoadContext : {
		road : RoadAhead.RoadView,
		place : RoadAhead.SegmentPlace,
		along : Along,
		across : Across,
	}

	## A segment's place on the road ahead, counted from the rider's own at 0. It
	## says how many segments ahead of the rider that segment is, where a
	## World.SegmentIndex says where it is in the route.
	Position :: U32.{

		number : U32 -> RoadAhead.Position
		number = |n| RoadAhead.Position.(n)

		to_i64 : RoadAhead.Position -> I64
		to_i64 = |RoadAhead.Position.(n)| n.to_i64()

		## The rider's own segment.
		first : RoadAhead.Position
		first = RoadAhead.Position.(0)

		next : RoadAhead.Position -> RoadAhead.Position
		next = |RoadAhead.Position.(n)| RoadAhead.Position.(n + 1)

		## Every position in `segments_ahead`, the rider's own first.
		positions_in : List(World.SegmentIndex) -> List(RoadAhead.Position)
		positions_in = |segments_ahead|
			List.from_iter(
				U32.until(0, segments_ahead.len().to_u32_wrap()),
			).map(RoadAhead.Position.number)

		## The segment at this position in `segments_ahead`.
		index_in : RoadAhead.Position, List(World.SegmentIndex) -> World.SegmentIndex
		index_in = |RoadAhead.Position.(n), segments_ahead|
			segments_ahead.get(n.to_u64()) ?? crash "RoadAhead.Position.index_in: past the road's end"

		## The segments of `segments_ahead` before this position, the rider's own first.
		segments_before : RoadAhead.Position, List(World.SegmentIndex) -> List(World.SegmentIndex)
		segments_before = |RoadAhead.Position.(n), segments_ahead|
			segments_ahead.take_first(n.to_u64())

		## Whether this position is the last one in `segments_ahead`.
		is_last_in : RoadAhead.Position, List(World.SegmentIndex) -> Bool
		is_last_in = |RoadAhead.Position.(n), segments_ahead| n.to_u64() + 1 >= segments_ahead.len()

		## Whether `segments_ahead` stops before this position.
		is_past_end_of : RoadAhead.Position, List(World.SegmentIndex) -> Bool
		is_past_end_of = |RoadAhead.Position.(n), segments_ahead| n.to_u64() >= segments_ahead.len()

		## Whether this position is among the first `count` of the road ahead.
		is_within_first : RoadAhead.Position, U32 -> Bool
		is_within_first = |RoadAhead.Position.(n), count| n < count

		is_eq : _
	}

	## Where a segment lies from the rider: at a position on the road ahead, or
	## just behind the rider, round the bend into the rider's segment.
	SegmentPlace : [Ahead(RoadAhead.Position), JustBehind(Geom.Bend)]

	## A segment in view: where it is in the route, the segment itself, and where
	## it lies from the rider.
	SegmentInView : {
		index : World.SegmentIndex,
		segment : World.Segment,
		place : RoadAhead.SegmentPlace,
	}

	## The most segments the road ahead holds.
	most_segments_ahead : U32
	most_segments_ahead = 7

	## The segment the rider is on, which is the road ahead's first.
	rider_segment : RoadAhead.RoadView -> World.SegmentIndex
	rider_segment = |road| RoadAhead.Position.first.index_in(road.segments_ahead)

	## The segment at `position` on the road ahead.
	segment_at : RoadAhead.RoadView, RoadAhead.Position -> World.Segment
	segment_at = |road, position|
		position.index_in(road.segments_ahead).segment_in(road.route_segments)

	## The segment behind the rider's, unless the rider's is the route's first.
	segment_behind : RoadAhead.RoadView -> [Previous(World.SegmentIndex), AtRouteStart]
	segment_behind = |road| rider_segment(road).previous()

	## The segments in view: those of the road ahead, the rider's own first, then
	## the one just behind the rider, unless the rider's is the route's first.
	segments_in_view : RoadAhead.RoadView -> List(RoadAhead.SegmentInView)
	segments_in_view = |road| {
		segments_ahead =
			RoadAhead.Position.positions_in(road.segments_ahead)
				.map(|position| segment_in_view_at(road, position))
		match segment_behind(road) {
			Previous(index) => {
				segment = index.segment_in(road.route_segments)
				segments_ahead.append({ index, segment, place: place_behind(segment) })
			}
			AtRouteStart => segments_ahead
		}
	}

	## The segment at `position` on the road ahead, as a segment in view.
	segment_in_view_at : RoadAhead.RoadView, RoadAhead.Position -> RoadAhead.SegmentInView
	segment_in_view_at = |road, position| {
		index = position.index_in(road.segments_ahead)
		{
			index,
			segment: index.segment_in(road.route_segments),
			place: Ahead(position),
		}
	}

	## Whether the road in view goes on round the bend at the end of `in_view`:
	## it does past every segment of the road ahead but the last, and past the
	## segment just behind, which bends into the rider's.
	has_bend_in_view : RoadAhead.RoadView, RoadAhead.SegmentInView -> Bool
	has_bend_in_view = |road, in_view|
		match in_view.place {
			Ahead(position) => !position.is_last_in(road.segments_ahead)
			JustBehind(_) => True
		}

	## How far ahead of the rider the segment at `position` on the road ahead starts.
	## The segments' lengths are added nearest first.
	gap_to_segment : RoadAhead.RoadView, RoadAhead.Position -> Distance
	gap_to_segment = |road, position|
		position.segments_before(road.segments_ahead).fold(
			road.vantage.along.from_start().opposite(),
			|gap, index| gap.plus(index.segment_in(road.route_segments).length),
		)

	## The road ahead from the segment at `start`: as far as the rider can see, or
	## to the route's end.
	indices_ahead : List(World.Segment), World.SegmentIndex -> List(World.SegmentIndex)
	indices_ahead = |route_segments, start| indices_onto(
		route_segments,
		{ index: start, segments_ahead: [] },
	)

	## The place of `segment`, which is just behind the rider.
	place_behind : World.Segment -> RoadAhead.SegmentPlace
	place_behind = |segment| JustBehind(World.bend_out_of(segment))

	## A point on the segment at `position` on the road ahead, in the rider's view.
	rider_point_ahead : RoadAhead.RoadView,
	{
		position : RoadAhead.Position,
		along : Along,
		across : Across,
	} -> Geom.RiderPoint
	rider_point_ahead = |road, { position, along, across }| {
		on_rider_segment = position.segments_before(road.segments_ahead).fold_rev(
			{ along, across },
			|index, point| Geom.point_in_segment_before(
				point,
				World.bend_out_of(index.segment_in(road.route_segments)),
			),
		)
		Geom.to_rider_point(on_rider_segment, road.vantage)
	}

	## A point on the segment at `place`, in the rider's view.
	rider_point_at : RoadAhead.RoadView,
	{
		place : RoadAhead.SegmentPlace,
		along : Along,
		across : Across,
	} -> Geom.RiderPoint
	rider_point_at = |road, { place, along, across }|
		match place {
			Ahead(position) =>
				rider_point_ahead(road, { position, along, across })
			JustBehind(bend) =>
				Geom.to_rider_point(
					Geom.point_in_segment_after({ along, across }, bend),
					road.vantage,
				)
		}
}

## `segments_ahead` with the segment at `index` and those after it added, up to the
## limit. An accumulator is linear, where appending a recursive call's answer
## is quadratic.
indices_onto : List(World.Segment),
{
	index : World.SegmentIndex,
	segments_ahead : List(World.SegmentIndex),
} -> List(World.SegmentIndex)
indices_onto = |route_segments, { index, segments_ahead }|
	if segments_ahead.len() >= RoadAhead.most_segments_ahead.to_u64() {
		segments_ahead
	} else {
		more_segments_ahead = segments_ahead.append(index)
		match index.segment_in(route_segments).ending {
			Continues({ next }) => indices_onto(
				route_segments,
				{ index: next, segments_ahead: more_segments_ahead },
			)
			Terminates => more_segments_ahead
		}
	}

expect RoadAhead.most_segments_ahead.to_i64() == 7
expect RoadAhead.indices_ahead(World.segments, World.SegmentIndex.first).len() == 7

route_facts : List(World.Segment) -> List(U64)
route_facts = |segments| [
	segments.len(),
	RoadAhead.indices_ahead(segments, World.SegmentIndex.first).len(),
	RoadAhead.indices_ahead(segments, World.SegmentIndex.number(15)).len(),
	RoadAhead.indices_ahead(segments, World.SegmentIndex.number(18)).len(),
]

expect route_facts(World.segments) == [19, 7, 4, 1]

expect RoadAhead.Position.number(3).to_i64() == 3
expect RoadAhead.Position.first.next().to_i64() == 1
