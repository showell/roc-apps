## TruckSighting finds the truck ahead of the rider in a frame: which segment of
## the road ahead it is on, whether it is in front of the camera, and which way
## it heads. Unlike the trees and the animals, the truck has no size test: it
## is drawn however small it stands.
import Angle
import Distance
import Geom
import Pipeline
import RoadAhead
import RoutePlace
import SegmentFromRider
import Truck

TruckSighting :: [].{

	## What became of the truck in a frame.
	TruckFate : Try(Truck.SightedTruck, [NoTruck, BehindCamera])

	## The truck at its `route_position` along the route, looking as its
	## `truck` says, if it is on the road ahead and in front of the camera.
	truck_in_view : RoadAhead.RoadView,
	{
		camera : Pipeline.SightingCamera,
		truck : { route_position : Distance, truck : Truck },
	} -> TruckSighting.TruckFate
	truck_in_view = |road, { camera, truck }| {
		place = RoutePlace.at_distance(road.route(), truck.route_position) ? |PastRouteEnd| NoTruck
		position = RoadAhead.position_of(road, place.segment_index) ? |NotAhead| NoTruck
		placed_truck : Geom.Placed(Truck)
		placed_truck = {
			road_point: place.road_point,
			lift: Distance.zero,
			kind: truck.truck,
		}
		sighting = Pipeline.sighting_of(placed_truck, { road, camera, place: Ahead(position) })?
		heading = TruckSighting.road_heading(
			road,
			{
				vantage: camera.vantage,
				place: Ahead(position),
				road_point: place.road_point,
			},
		)
		Ok({ spot: sighting.spot, heading, lights: sighting.kind })
	}

	## Which way the road runs at `road_point` on the segment at `place`, against
	## the camera at `vantage`: zero straight away from it, positive to the
	## right. A segment is carried into the rider's view by turns and shifts
	## alone, so the way from the point to one a metre further along is the
	## road's way all along the segment.
	road_heading : RoadAhead.RoadView,
	{
		vantage : Geom.Vantage,
		place : SegmentFromRider,
		road_point : Geom.RoadPoint,
	} -> Angle.Turn
	road_heading = |road, { vantage, place, road_point }| {
		further_along = { ..road_point, along: road_point.along.plus(Distance.metres(1.0)) }
		here = RoadAhead.rider_point_at(road, { vantage, place, road_point })
		there = RoadAhead.rider_point_at(road, { vantage, place, road_point: further_along })
		Angle.Turn.radians(
			F64.atan2({
				x: there.forward.minus(here.forward).to_metres(),
				y: there.right.minus(here.right).to_metres(),
			}),
		)
	}
}
