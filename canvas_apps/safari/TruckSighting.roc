## TruckSighting finds the truck ahead of the rider in a frame: which segment of
## the road ahead it is on, and whether it is in front of the camera. Unlike the
## trees and the animals, the truck has no size test: it is drawn however small
## it stands, so the sighting needs no lens. It is worked out each frame from
## where the rider's camera stands, the route, the truck's progress and the
## clock.
import Distance
import Geom
import Pipeline
import RoadAhead
import RoutePlace
import Truck

TruckSighting :: [].{

	## What became of the truck in a frame.
	TruckFate : Try(Pipeline.Sighted(Truck), [OutOfSight])

	## The truck at its `route_position` along the route, with its `lights`, if
	## it is on the road ahead and in front of the camera.
	truck_in_view : RoadAhead.RoadView,
	{
		vantage : Geom.Vantage,
		truck : { route_position : Distance, lights : Truck },
	} -> TruckSighting.TruckFate
	truck_in_view = |road, { vantage, truck }| {
		route = road.route()
		place = RoutePlace.at_distance(route, truck.route_position) ? |PastRouteEnd| OutOfSight
		position = RoadAhead.position_of(road, place.segment_index) ? |NotAhead| OutOfSight
		placed_truck : Geom.Placed(Truck)
		placed_truck = {
			road_point: place.road_point,
			lift: Distance.zero,
			kind: truck.lights,
		}
		sighting = Pipeline.sighting_of(
			placed_truck,
			{ road, vantage, from_rider: Ahead(position) },
		)?
		Ok(sighting)
	}
}
