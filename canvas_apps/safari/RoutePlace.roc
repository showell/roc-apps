## A place on the route: the segment it is on, and where it is on that segment,
## along it and across it. The place's coordinates mean something only with
## their segment, so the three travel together, and crossing a bend moves all
## three at once.
import Across
import Along
import Distance
import Geom
import Route
import Segment

## The segment, and the place on it. It is nominal, not opaque: every segment
## index with every place on it is a place on the route, so there is nothing to
## guard, and other modules read its fields.
RoutePlace := {
	## The segment of the route the place is on.
	segment_index : Route.SegmentIndex,

	## How far along that segment the place is.
	along : Along,

	## How far across that segment's road the place is.
	across : Across,
}.{

	## The start of the route, on the middle of the road.
	route_start : RoutePlace
	route_start = {
		segment_index: Route.SegmentIndex.first,
		along: Along.start,
		across: Across.middle,
	}

	## The segment of `route` this place is on.
	segment_on : RoutePlace, Route -> Segment
	segment_on = |place, route| route.segment_at(place.segment_index)

	## How far along `route` this place is.
	distance_along : RoutePlace, Route -> Distance
	distance_along = |place, route|
		route.distance_along_route({ index: place.segment_index, along: place.along })

	## Where this place is on its segment, without the segment.
	road_point : RoutePlace -> Geom.RoadPoint
	road_point = |place| { along: place.along, across: place.across }

	## This place carried over `bend`, the bend out of its segment, onto the next
	## segment and measured there. Nothing here asks whether that puts it on the
	## next segment's road.
	route_place_past_bend : RoutePlace, Geom.Bend -> RoutePlace
	route_place_past_bend = |place, bend| {
		on_next = Geom.point_in_segment_after(place.road_point(), bend)
		{
			segment_index: place.segment_index.next(),
			along: on_next.along,
			across: on_next.across,
		}
	}

	## Whether this place is on its segment's road, between the edges.
	is_on_road : RoutePlace -> Bool
	is_on_road = |place| place.across.distance_from_middle() < Geom.road_half_width

	is_eq : _
}

## A place at the route's start, `across` metres from the middle of the road.
place_across : F64 -> RoutePlace
place_across = |across| { ..RoutePlace.route_start, across: Across.metres(across) }

# The road's edges are off the road, and just inside them is on it.
expect
	[
		(-2.0, False),
		(-1.99, True),
		(0.0, True),
		(1.99, True),
		(2.0, False),
	].all(|(across, is_on)| place_across(across).is_on_road() == is_on)
