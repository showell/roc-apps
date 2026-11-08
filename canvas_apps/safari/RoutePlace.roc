## A place on the route: the segment it is on, and the point on that segment,
## along it and across it. The point means something only with its segment, so
## the two travel together, and crossing a bend moves both at once.
import Across
import Along
import Distance
import Geom
import Route
import Segment

## The segment, and the point on it. It is nominal, not opaque: every segment
## index with every point on it is a place on the route, so there is nothing to
## guard, and other modules read its fields.
RoutePlace := {
	## The segment of the route the place is on.
	segment_index : Route.SegmentIndex,

	## Where on that segment the place is, along it and across its road.
	road_point : Geom.RoadPoint,
}.{

	## The start of the route, on the middle of the road.
	route_start : RoutePlace
	route_start = {
		segment_index: Route.SegmentIndex.first,
		road_point: { along: Along.start, across: Across.middle },
	}

	## The segment of `route` this place is on.
	segment_on : RoutePlace, Route -> Segment
	segment_on = |place, route| route.segment_at(place.segment_index)

	## How far along `route` this place is.
	distance_along : RoutePlace, Route -> Distance
	distance_along = |place, route|
		route.distance_along_route({ index: place.segment_index, along: place.road_point.along })

	## The place `distance` along `route`, on the middle of the road: the inverse
	## of `distance_along`. A distance at a segment's end is on that segment,
	## at its end, not at the start of the next.
	at_distance : Route, Distance -> Try(RoutePlace, [PastRouteEnd])
	at_distance = |route, distance|
		match route.segments_with_ends().find_first_index(|stretch| distance <= stretch.end) {
			Ok(count_before) => {
				index = Route.SegmentIndex.number(
					count_before.to_u32_try() ?? crash "RoutePlace.at_distance: a route holds fewer than 2^32 segments",
				)
				start = route.distance_along_route({ index, along: Along.start })
				Ok({
					segment_index: index,
					road_point: { along: Along.at(distance.minus(start)), across: Across.middle },
				})
			}
			Err(NotFound) => Err(PastRouteEnd)
		}

	## This place carried over `bend`, the bend out of its segment, onto the next
	## segment and measured there. Nothing here asks whether that puts it on the
	## next segment's road.
	route_place_past_bend : RoutePlace, Geom.Bend -> RoutePlace
	route_place_past_bend = |place, bend| {
		segment_index: place.segment_index.next(),
		road_point: Geom.point_in_segment_after(place.road_point, bend),
	}

	## Whether this place is on its segment's road, between the edges.
	is_on_road : RoutePlace -> Bool
	is_on_road = |place| place.road_point.across.distance_from_middle() < Geom.road_half_width

	is_eq : _
}

## A place at the route's start, `across` metres from the middle of the road.
place_across : F64 -> RoutePlace
place_across = |across| {
	..RoutePlace.route_start,
	road_point: { ..RoutePlace.route_start.road_point, across: Across.metres(across) },
}

# The road's edges are off the road, and just inside them is on it.
expect
	[
		(-2.0, False),
		(-1.99, True),
		(0.0, True),
		(1.99, True),
		(2.0, False),
	].all(|(across, is_on)| place_across(across).is_on_road() == is_on)
