## RoadAhead finds where the road ahead lies, and where the segment just behind
## the rider lies. The road ahead is the line of segments the rider can see, the
## rider's own first, and a point on any of them, or on the segment just behind,
## is carried back round the bends between to the rider's own segment and into
## the view of a camera standing there.
import Angle
import Distance
import Geom
import RiderView
import Route
import Segment
import SegmentFromRider

RoadAhead :: [].{

	## The road in view: the route, and the run of its segments ahead of the
	## rider. Only `ahead_of` builds one, so a road holds just what a rider on
	## its route can see.
	## It keeps how many segments lie ahead, the bends between them, and the
	## bend from the segment just behind, each worked out once from the route
	## by `ahead_of`: the count for every walk along the road ahead, and the
	## bends for all the points carried across them.
	RoadView :: {
		route : Route,
		segments_ahead : RoadAhead.SegmentsAhead,
		bends_ahead : List(Geom.WorkedBend),
		bend_behind : [Behind(Geom.WorkedBend), AtRouteStart],
	}.{

		## The road ahead of a rider on the route's segment at `rider_index`: as
		## far as the rider can see, or to the route's end.
		ahead_of : Route, Route.SegmentIndex -> RoadAhead.RoadView
		ahead_of = |route, rider_index| {
			segments_ahead = segments_ahead_of(route, rider_index)
			RoadAhead.RoadView.(
				{
					route,
					segments_ahead,
					bends_ahead: worked_bends_ahead(route, segments_ahead),
					bend_behind: worked_bend_behind(route, rider_index),
				},
			)
		}

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
		from_rider : SegmentFromRider,
	}

	## The segment at `position` on the road ahead.
	segment_at : RoadAhead.RoadView, SegmentFromRider.Position -> Segment
	segment_at = |road, position| road.route().segment_at(index_at(road, position))

	## The segments in view: those of the road ahead, the rider's own first, then
	## the one just behind the rider, unless the rider's is the route's first.
	segments_in_view : RoadAhead.RoadView -> List(RoadAhead.SegmentInView)
	segments_in_view = |road| {
		segments_ahead =
			SegmentFromRider.Position.positions_in(road.segments_ahead())
				.map(|position| segment_in_view_at(road, position))
		match previous_segment_index(road) {
			Previous(index) => {
				segment = road.route().segment_at(index)
				segments_ahead.append({ index, segment, from_rider: JustBehind })
			}
			AtRouteStart => segments_ahead
		}
	}

	## Where the route's segment at `index` is on the road ahead, or `NotAhead`
	## when the road ahead doesn't hold it.
	position_of : RoadAhead.RoadView, Route.SegmentIndex -> Try(SegmentFromRider.Position, _)
	position_of = |road, index| {
		positions = SegmentFromRider.Position.positions_in(road.segments_ahead())
		match positions.find_first(|position| index_at(road, position) == index) {
			Ok(position) => Ok(position)
			Err(NotFound) => Err(NotAhead)
		}
	}

	## The segment at `position` on the road ahead, as a segment in view.
	segment_in_view_at : RoadAhead.RoadView, SegmentFromRider.Position -> RoadAhead.SegmentInView
	segment_in_view_at = |road, position| {
		index = index_at(road, position)
		{
			index,
			segment: road.route().segment_at(index),
			from_rider: Ahead(position),
		}
	}

	## A point on the segment that lies at `from_rider`, as the camera at
	## `vantage` on the rider's segment sees it.
	rider_point_at : RoadAhead.RoadView,
	{
		vantage : Geom.Vantage,
		from_rider : SegmentFromRider,
		road_point : Geom.RoadPoint,
	} -> RiderView.RiderPoint
	rider_point_at = |road, { vantage, from_rider, road_point }|
		match from_rider {
			Ahead(position) =>
				rider_point_round_bends(road, { vantage, position, road_point })
			JustBehind =>
				match bend_behind(road) {
					Behind(bend) => {
						on_rider_segment = Geom.point_after_worked_bend(road_point, bend)
						to_rider_point(on_rider_segment, vantage)
					}
					AtRouteStart => crash "RoadAhead.rider_point_at: a rider on the route's first segment has no segment behind"
				}
		}

	## Which way the road runs at `road_point` on the segment that lies at
	## `from_rider`, as the camera at `vantage` sees it: zero straight away from
	## the camera, positive to the right. A segment comes into the rider's view
	## by a turn and a shift, so the road runs the same way all along it, and
	## two points a metre apart are enough to find which way that is.
	road_heading_at : RoadAhead.RoadView,
	{
		vantage : Geom.Vantage,
		from_rider : SegmentFromRider,
		road_point : Geom.RoadPoint,
	} -> Angle.Turn
	road_heading_at = |road, { vantage, from_rider, road_point }| {
		further_along = { ..road_point, along: road_point.along.plus(Distance.metres(1.0)) }
		here = RoadAhead.rider_point_at(road, { vantage, from_rider, road_point })
		there = RoadAhead.rider_point_at(road, { vantage, from_rider, road_point: further_along })
		Angle.Turn.radians(
			F64.atan2({
				x: there.forward.minus(here.forward).to_metres(),
				y: there.right.minus(here.right).to_metres(),
			}),
		)
	}
}

## The road ahead of a rider on the segment at `start`: as far as the rider can
## see, or to the route's end.
segments_ahead_of : Route, Route.SegmentIndex -> RoadAhead.SegmentsAhead
segments_ahead_of = |route, start| {
	left_on_route = route.segment_count() - start.count_before()
	{ first_index: start, count: left_on_route.min(most_segments_ahead.to_u64()).to_u32_wrap() }
}

## The most segments the road ahead holds.
most_segments_ahead : U32
most_segments_ahead = 7

## The bend out of each segment of the road ahead but its last, the rider's
## own first, worked out.
bends_ahead : RoadAhead.RoadView -> List(Geom.WorkedBend)
bends_ahead = |RoadAhead.RoadView.(road)| road.bends_ahead

## The bend from the segment just behind the rider into the rider's own,
## worked out, unless the rider's is the route's first.
bend_behind : RoadAhead.RoadView -> [Behind(Geom.WorkedBend), AtRouteStart]
bend_behind = |RoadAhead.RoadView.(road)| road.bend_behind

## The index of the segment the rider is on, which is the road ahead's first.
rider_segment_index : RoadAhead.RoadView -> Route.SegmentIndex
rider_segment_index = |road| road.segments_ahead().first_index

## The segment behind the rider's, unless the rider's is the route's first.
previous_segment_index : RoadAhead.RoadView -> [Previous(Route.SegmentIndex), AtRouteStart]
previous_segment_index = |road| rider_segment_index(road).previous()

## A point on the segment at `position` on the road ahead, carried back round
## each bend between it and the rider's segment, as the camera at `vantage`
## there sees it.
rider_point_round_bends : RoadAhead.RoadView,
{
	vantage : Geom.Vantage,
	position : SegmentFromRider.Position,
	road_point : Geom.RoadPoint,
} -> RiderView.RiderPoint
rider_point_round_bends = |road, { vantage, position, road_point }| {
	bends = bends_ahead(road)
	var $point = road_point
	var $bends_left = position.to_u32().to_u64()
	while $bends_left > 0 {
		$bends_left = $bends_left - 1
		bend = bends.get($bends_left) ?? crash "RoadAhead.rider_point_round_bends: past the road's end"
		$point = Geom.point_before_worked_bend($point, bend)
	}
	to_rider_point($point, vantage)
}

## A point on the rider's segment, as the camera at `vantage` sees it.
to_rider_point : Geom.RoadPoint, Geom.Vantage -> RiderView.RiderPoint
to_rider_point = |{ along, across }, vantage| {
	ahead = along.distance_from(vantage.along).to_metres()
	aside = across.distance_from(vantage.across).to_metres()
	cos_yaw = vantage.yaw.to_radians().cos()
	sin_yaw = vantage.yaw.to_radians().sin()
	{
		forward: Distance.metres(ahead * cos_yaw + aside * sin_yaw),
		right: Distance.metres((0.0 - ahead) * sin_yaw + aside * cos_yaw),
	}
}

## The route's index of the segment at `position` on the road ahead.
index_at : RoadAhead.RoadView, SegmentFromRider.Position -> Route.SegmentIndex
index_at = |road, position| {
	segments_ahead = road.segments_ahead()
	if position.is_within_first(segments_ahead.count) {
		Route.SegmentIndex.number(segments_ahead.first_index.to_u32() + position.to_u32())
	} else {
		crash "RoadAhead.index_at: past the road's end"
	}
}

## The bends out of the segments of `segments_ahead` but the last, worked out.
worked_bends_ahead : Route, RoadAhead.SegmentsAhead -> List(Geom.WorkedBend)
worked_bends_ahead = |route, { first_index, count }| {
	first = first_index.to_u32()
	List.from_iter(U32.until(0, count - 1)).map(
		|n| Geom.worked_bend(route.segment_at(Route.SegmentIndex.number(first + n)).bend_out_of()),
	)
}

## The bend from the segment behind the one at `rider_index` into it, worked
## out, unless that is the route's first.
worked_bend_behind : Route, Route.SegmentIndex -> [Behind(Geom.WorkedBend), AtRouteStart]
worked_bend_behind = |route, rider_index|
	match rider_index.previous() {
		Previous(index) => Behind(Geom.worked_bend(route.segment_at(index).bend_out_of()))
		AtRouteStart => AtRouteStart
	}
