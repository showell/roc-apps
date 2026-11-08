## TruckSighting finds the truck ahead of the rider in a frame: which segment of
## the road ahead it is on, and whether it is in front of the camera. Unlike the
## trees and the critters, the truck has no size test: it is drawn however
## small it stands.
import Distance
import RoadAhead
import RoutePlace
import SegmentPlace
import Geom
import Pipeline
import LitTruck

TruckSighting :: [].{

	## What became of the truck in a frame.
	TruckFate : Try(Pipeline.Sighted(LitTruck), [NoTruck, BehindCamera])

	## The truck at `route_position` along the route, looking as `lit_truck`
	## says, if it is on the road ahead and in front of the camera.
	truck_in_view : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, .. },
		route_position : Distance,
		lit_truck : LitTruck,
	} -> TruckSighting.TruckFate
	truck_in_view = |road, { camera, route_position, lit_truck }| {
		place = RoutePlace.at_distance(road.route(), route_position) ? |PastRouteEnd| NoTruck
		position = position_ahead(road, place) ? |NotFound| NoTruck
		placed_truck : Geom.Placed(LitTruck)
		placed_truck = {
			road_point: place.road_point(),
			lift: Distance.zero,
			kind: lit_truck,
		}
		vantage = camera.vantage
		Pipeline.sighting_of(placed_truck, { road, vantage, place: Ahead(position) })
	}
}

## Where `place`'s segment is on the road ahead, unless the road ahead doesn't
## hold it.
position_ahead : RoadAhead.RoadView, RoutePlace -> Try(SegmentPlace.Position, [NotFound])
position_ahead = |road, place|
	SegmentPlace.Position.positions_in(road.segments_ahead()).find_first(
		|position| RoadAhead.segment_in_view_at(road, position).index == place.segment_index,
	)
