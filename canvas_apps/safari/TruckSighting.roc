## TruckSighting finds the truck ahead of the rider in a frame: how far along
## the road ahead it is, and whether it is in front of the camera. Unlike the
## trees and the critters, the truck has no size test: it is drawn however
## small it stands.
import Across
import Along
import Angle
import Distance
import RoadAhead
import Route
import SegmentPlace
import Geom
import Pipeline
import LitTruck
import Pixels
import World

TruckSighting :: [].{

	## What became of the truck in a frame.
	TruckFate : Try(Pipeline.Sighted(LitTruck), [NoTruck, BehindCamera])

	## The truck at `route_position` along the route, looking as `lit_truck`
	## says, if it is ahead of the camera, on the road ahead, and in front of
	## the camera.
	truck_in_view : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
		route_position : Distance,
		lit_truck : LitTruck,
	} -> TruckSighting.TruckFate
	truck_in_view = |road, { camera, route_position, lit_truck }| {
		vantage = camera.vantage
		rider_distance = road.route().distance_along_route(
			{ index: RoadAhead.rider_segment(road), along: vantage.along },
		)
		lead = route_position.minus(rider_distance)
		if lead > Distance.zero {
			start = { along: vantage.along.plus(lead), position: SegmentPlace.Position.first }
			match truck_from(road, start) {
				Ok({ along, position }) => {
					placed_truck : Geom.Placed(LitTruck)
					placed_truck = {
						road_point: { along, across: Across.middle },
						lift: Distance.zero,
						kind: lit_truck,
					}
					Pipeline.sighting_of(placed_truck, { road, vantage, place: Ahead(position) })
				}
				Err(NoTruck) => Err(NoTruck)
			}
		} else {
			Err(NoTruck)
		}
	}
}

## Where the truck is on the road ahead: `along` measured from the start of the
## segment at `position`.
TruckPlace : { along : Along, position : SegmentPlace.Position }

## Where the truck at `along`, measured from the start of the segment at
## `position` on the road ahead, really is, found by walking on through the
## segments it is past.
truck_from : RoadAhead.RoadView, TruckPlace -> Try(TruckPlace, [NoTruck])
truck_from = |road, { along, position }|
	if position.is_within_first(road.segments_ahead().count) {
		segment = RoadAhead.segment_at(road, position)
		if along > Along.at(segment.length) {
			truck_from(road, { along: along.minus(segment.length), position: position.next() })
		} else {
			Ok({ along, position })
		}
	} else {
		Err(NoTruck)
	}

## The rider at the start of the route, looking straight down the road.
origin : Geom.Vantage
origin = {
	along: Along.metres(0.0),
	across: Across.metres(0.0),
	yaw: Angle.straight_ahead,
}

## The route's first three segments, a route of their own, and the road ahead
## of a rider on the first of them.
first_road : RoadAhead.RoadView
first_road = RoadAhead.RoadView.ahead_of(
	Route.from_segments([
		World.route.segment_at(Route.SegmentIndex.number(0)),
		World.route.segment_at(Route.SegmentIndex.number(1)),
		{ ..World.route.segment_at(Route.SegmentIndex.number(2)), ending: RouteEnds },
	]),
	Route.SegmentIndex.first,
)

## What becomes of a truck `lead` metres ahead of a rider on the route's first
## segment, seen from `vantage`, with its lights off. On the first segment the
## rider's distance along the route is the vantage's `along`.
truck_seen_from : Geom.Vantage, F64 -> TruckSighting.TruckFate
truck_seen_from = |vantage, lead|
	TruckSighting.truck_in_view(
		first_road,
		{
			camera: { vantage, cam_focal: Pixels.of(500.0) },
			route_position: Distance.metres(vantage.along.to_metres() + lead),
			lit_truck: { headlights: Off, brake_lights: Off },
		},
	)

lead_of : F64 -> TruckSighting.TruckFate
lead_of = |lead| truck_seen_from(origin, lead)

## Where the truck is, for a lead that puts it in view.
lit_truck_of : F64 -> Pipeline.Sighted(LitTruck)
lit_truck_of = |lead| lead_of(lead) ?? crash "TruckSighting: this lead puts the truck in view"

expect
	[
		(100.0, True),
		(499.0, True),
		(600.0, True),
		(900.0, True),
		(2000.0, False),
		(0.0, False),
		(-50.0, False),
	].all(|(lead, want)| lead_of(lead).is_ok() == want)

expect
	[
		(100.0, 0),
		(499.0, 0),
		(600.0, 1),
		(900.0, 2),
	].all(
		|(lead, want)| {
			place = lit_truck_of(lead).spot.place()
			place == Ahead(SegmentPlace.Position.number(want))
		},
	)

expect
	[
		(100.0, 100.0),
		(499.0, 499.0),
		(600.0, 100.0),
		(900.0, 80.0),
	].all(|(lead, want)| lit_truck_of(lead).spot.road_point().along.to_metres() == want)

expect
	[
		(100.0, 0.0),
		(499.0, 0.0),
		(600.0, 0.0),
		(900.0, 0.0),
	].all(|(lead, want)| lit_truck_of(lead).spot.road_point().across.to_metres() == want)

## The lights a truck in view shows, when it has `lights` on.
lights_shown = |lights| {
	truck = TruckSighting.truck_in_view(
		first_road,
		{
			camera: { vantage: origin, cam_focal: Pixels.of(500.0) },
			route_position: Distance.metres(100.0),
			lit_truck: lights,
		},
	) ?? crash "TruckSighting: this lead puts the truck in view"
	truck.kind
}

expect
	[
		{ headlights: Off, brake_lights: Off },
		{ headlights: Off, brake_lights: On },
		{ headlights: On, brake_lights: Off },
		{ headlights: On, brake_lights: On },
	].all(|lights| lights_shown(lights) == lights)

expect
	[
		(lit_truck_of(100.0).spot.foot().forward().to_metres(), 100.0),
		(lit_truck_of(499.0).spot.foot().forward().to_metres(), 499.0),
		(lit_truck_of(100.0).spot.foot().right().to_metres(), 0.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect lead_of(2000.0).is_err()
expect truck_seen_from({ ..origin, along: Along.metres(100.0) }, 0.25).is_err()
expect truck_seen_from({ ..origin, along: Along.metres(100.0) }, 1.0).is_ok()
