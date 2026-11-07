## RoadAhead finds where the road ahead lies, and where the segment just behind
## the rider lies. The road ahead is the line of segments the rider can see, the
## rider's own first, and a point on any of them, or on the segment just behind,
## is carried back round the bends between to the rider's own segment and into
## the view of a camera standing there.
import Geom
import Route
import Segment
import SegmentPlace

RoadAhead :: [].{

	## The road in view: the route, and the run of its segments ahead of the
	## rider. Only `ahead_of` builds one, so a road holds just what a rider on
	## its route can see.
	RoadView :: { route : Route, segments_ahead : RoadAhead.SegmentsAhead }.{

		## The road ahead of a rider on the route's segment at `rider_index`: as
		## far as the rider can see, or to the route's end.
		ahead_of : Route, Route.SegmentIndex -> RoadAhead.RoadView
		ahead_of = |route, rider_index|
			RoadAhead.RoadView.({ route, segments_ahead: segments_ahead_of(route, rider_index) })

		## The route the road is on.
		route : RoadAhead.RoadView -> Route
		route = |RoadAhead.RoadView.(road)| road.route

		## The segments of the route the road ahead holds.
		segments_ahead : RoadAhead.RoadView -> RoadAhead.SegmentsAhead
		segments_ahead = |RoadAhead.RoadView.(road)| road.segments_ahead
	}

	## The segments of the route ahead of the rider: the index of the rider's
	## own, which is the first, and how many there are, one after another from
	## it.
	SegmentsAhead : { first_index : Route.SegmentIndex, count : U32 }

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
	rider_segment = |road| road.segments_ahead().first_index

	## The segment at `position` on the road ahead.
	segment_at : RoadAhead.RoadView, SegmentPlace.Position -> Segment
	segment_at = |road, position| road.route().segment_at(index_at(road, position))

	## The segments in view: those of the road ahead, the rider's own first, then
	## the one just behind the rider, unless the rider's is the route's first.
	segments_in_view : RoadAhead.RoadView -> List(RoadAhead.SegmentInView)
	segments_in_view = |road| {
		segments_ahead =
			SegmentPlace.Position.positions_in(road.segments_ahead())
				.map(|position| segment_in_view_at(road, position))
		match segment_behind(road) {
			Previous(index) => {
				segment = road.route().segment_at(index)
				segments_ahead.append({ index, segment, place: JustBehind })
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
			segment: road.route().segment_at(index),
			place: Ahead(position),
		}
	}

	## A point on the segment at `place`, as the camera at `vantage` on the
	## rider's segment sees it.
	rider_point_at : RoadAhead.RoadView,
	{
		vantage : Geom.Vantage,
		place : SegmentPlace,
		road_point : Geom.RoadPoint,
	} -> Geom.RiderPoint
	rider_point_at = |road, { vantage, place, road_point }|
		match place {
			Ahead(position) =>
				rider_point_ahead(road, { vantage, position, road_point })
			JustBehind =>
				Geom.to_rider_point(
					Geom.point_in_segment_after(road_point, bend_behind(road)),
					vantage,
				)
		}
}

## The road ahead of a rider on the segment at `start`: as far as the rider can
## see, or to the route's end.
segments_ahead_of : Route, Route.SegmentIndex -> RoadAhead.SegmentsAhead
segments_ahead_of = |route, start| {
	left_on_route = route.segment_count() - start.count_before()
	{
		first_index: start,
		count: left_on_route.min(RoadAhead.most_segments_ahead.to_u64()).to_u32_wrap(),
	}
}

## The segment behind the rider's, unless the rider's is the route's first.
segment_behind : RoadAhead.RoadView -> [Previous(Route.SegmentIndex), AtRouteStart]
segment_behind = |road| RoadAhead.rider_segment(road).previous()

## A point on the segment at `position` on the road ahead, as the camera at
## `vantage` on the rider's segment sees it.
rider_point_ahead : RoadAhead.RoadView,
{
	vantage : Geom.Vantage,
	position : SegmentPlace.Position,
	road_point : Geom.RoadPoint,
} -> Geom.RiderPoint
rider_point_ahead = |road, { vantage, position, road_point }| {
	on_rider_segment = segments_before(road, position).fold_rev(
		road_point,
		|index, point| Geom.point_in_segment_before(
			point,
			road.route().segment_at(index).bend_out_of(),
		),
	)
	Geom.to_rider_point(on_rider_segment, vantage)
}

## The route's index of the segment at `position` on the road ahead.
index_at : RoadAhead.RoadView, SegmentPlace.Position -> Route.SegmentIndex
index_at = |road, position| {
	segments_ahead = road.segments_ahead()
	if position.is_within_first(segments_ahead.count) {
		Route.SegmentIndex.number(segments_ahead.first_index.to_u32() + position.to_u32())
	} else {
		crash "RoadAhead.index_at: past the road's end"
	}
}

## The bend from the segment just behind the rider into the rider's own.
bend_behind : RoadAhead.RoadView -> Geom.Bend
bend_behind = |road|
	match segment_behind(road) {
		Previous(index) => road.route().segment_at(index).bend_out_of()
		AtRouteStart => crash "RoadAhead.bend_behind: a rider on the route's first segment has no segment behind"
	}

## The route's indices of the segments of the road ahead before `position`, the
## rider's own first.
segments_before : RoadAhead.RoadView, SegmentPlace.Position -> List(Route.SegmentIndex)
segments_before = |road, position| {
	first = road.segments_ahead().first_index.to_u32()
	List.from_iter(U32.until(0, position.to_u32())).map(|n| Route.SegmentIndex.number(first + n))
}
