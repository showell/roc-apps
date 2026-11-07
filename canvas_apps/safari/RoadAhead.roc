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
import Route
import Segment
import SegmentPlace
import World

RoadAhead :: [].{

	## The road in view: the route, the run of its segments ahead of the rider,
	## and the rider's vantage.
	RoadView : {
		route : Route,
		segments_ahead : RoadAhead.SegmentsAhead,
		vantage : Geom.Vantage,
	}

	## The segments of the route ahead of the rider: the index of the rider's
	## own, which is the first, and how many there are, one after another from
	## it.
	SegmentsAhead : { first_index : Route.SegmentIndex, count : U32 }

	## What the camera sees in a frame: the road in view, and the camera's focal
	## length in pixels.
	CameraView : { road : RoadAhead.RoadView, cam_focal : Pixels }

	## A segment in view: where it is in the route, the segment itself, and where
	## it lies from the rider.
	SegmentInView : {
		index : Route.SegmentIndex,
		segment : Segment,
		place : SegmentPlace,
	}

	## The most segments the road ahead holds.
	most_segments_ahead : U32
	most_segments_ahead = 7

	## The segment the rider is on, which is the road ahead's first.
	rider_segment : RoadAhead.RoadView -> Route.SegmentIndex
	rider_segment = |road| road.segments_ahead.first_index

	## The segment at `position` on the road ahead.
	segment_at : RoadAhead.RoadView, SegmentPlace.Position -> Segment
	segment_at = |road, position| road.route.segment_at(index_at(road, position))

	## The segment behind the rider's, unless the rider's is the route's first.
	segment_behind : RoadAhead.RoadView -> [Previous(Route.SegmentIndex), AtRouteStart]
	segment_behind = |road| rider_segment(road).previous()

	## The segments in view: those of the road ahead, the rider's own first, then
	## the one just behind the rider, unless the rider's is the route's first.
	segments_in_view : RoadAhead.RoadView -> List(RoadAhead.SegmentInView)
	segments_in_view = |road| {
		segments_ahead =
			SegmentPlace.Position.positions_in(road.segments_ahead)
				.map(|position| segment_in_view_at(road, position))
		match segment_behind(road) {
			Previous(index) => {
				segment = road.route.segment_at(index)
				segments_ahead.append({ index, segment, place: place_behind(segment) })
			}
			AtRouteStart => segments_ahead
		}
	}

	## The segment at `position` on the road ahead, as a segment in view.
	segment_in_view_at : RoadAhead.RoadView, SegmentPlace.Position -> RoadAhead.SegmentInView
	segment_in_view_at = |road, position| {
		index = index_at(road, position)
		{
			index,
			segment: road.route.segment_at(index),
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

	## How far ahead of the rider, along the road, a segment in view starts. The
	## lengths of the road ahead's segments are added nearest first, and the
	## segment just behind starts its own length behind the rider's.
	gap_to_segment : RoadAhead.RoadView, RoadAhead.SegmentInView -> Distance
	gap_to_segment = |road, in_view| {
		gap_to_rider_segment = road.vantage.along.from_start().opposite()
		match in_view.place {
			Ahead(position) =>
				segments_before(road, position).fold(
					gap_to_rider_segment,
					|gap, index| gap.plus(road.route.segment_at(index).length),
				)
			JustBehind(_) => gap_to_rider_segment.minus(in_view.segment.length)
		}
	}

	## The road ahead of a rider on the segment at `start`: as far as the rider
	## can see, or to the route's end.
	indices_ahead : Route, Route.SegmentIndex -> RoadAhead.SegmentsAhead
	indices_ahead = |route, start| {
		left_on_route = route.segment_count() - start.count_before()
		{
			first_index: start,
			count: left_on_route.min(RoadAhead.most_segments_ahead.to_u64()).to_u32_wrap(),
		}
	}

	## The place of `segment`, which is just behind the rider.
	place_behind : Segment -> SegmentPlace
	place_behind = |segment| JustBehind(segment.bend_out_of())

	## A point on the segment at `position` on the road ahead, in the rider's view.
	rider_point_ahead : RoadAhead.RoadView,
	{
		position : SegmentPlace.Position,
		road_point : Geom.RoadPoint,
	} -> Geom.RiderPoint
	rider_point_ahead = |road, { position, road_point }| {
		on_rider_segment = segments_before(road, position).fold_rev(
			road_point,
			|index, point| Geom.point_in_segment_before(
				point,
				road.route.segment_at(index).bend_out_of(),
			),
		)
		Geom.to_rider_point(on_rider_segment, road.vantage)
	}

	## A point on the segment at `place`, in the rider's view.
	rider_point_at : RoadAhead.RoadView,
	{
		place : SegmentPlace,
		road_point : Geom.RoadPoint,
	} -> Geom.RiderPoint
	rider_point_at = |road, { place, road_point }|
		match place {
			Ahead(position) =>
				rider_point_ahead(road, { position, road_point })
			JustBehind(bend) =>
				Geom.to_rider_point(Geom.point_in_segment_after(road_point, bend), road.vantage)
		}
}

## The route's index of the segment at `position` on the road ahead.
index_at : RoadAhead.RoadView, SegmentPlace.Position -> Route.SegmentIndex
index_at = |road, position|
	if position.is_past_end_of(road.segments_ahead) {
		crash "RoadAhead.index_at: past the road's end"
	} else {
		Route.SegmentIndex.number(road.segments_ahead.first_index.to_u32() + position.to_u32())
	}

## The route's indices of the segments of the road ahead before `position`, the
## rider's own first.
segments_before : RoadAhead.RoadView, SegmentPlace.Position -> List(Route.SegmentIndex)
segments_before = |road, position| {
	first = road.segments_ahead.first_index.to_u32()
	List.from_iter(U32.until(0, position.to_u32())).map(|n| Route.SegmentIndex.number(first + n))
}

expect RoadAhead.most_segments_ahead.to_i64() == 7

## How many segments the road ahead holds for a rider on the route's segment
## `number`.
count_ahead_of : U32 -> U32
count_ahead_of = |number| RoadAhead.indices_ahead(
	World.route,
	Route.SegmentIndex.number(number),
).count

expect
	[
		(0, 7),
		(12, 7),
		(13, 6),
		(15, 4),
		(18, 1),
	].all(|(number, want)| count_ahead_of(number) == want)
expect World.route.segment_count() == 19
