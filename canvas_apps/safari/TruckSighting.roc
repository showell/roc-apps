## TruckSighting finds the truck ahead of the rider in a frame: how far along
## the chain of segments ahead it is, whether it is in front of the camera,
## and which of its lights the drawing shows.
import Across
import Along
import Distance
import Chain
import Geom
import Truck
import TruckAhead

TruckSighting :: [].{

	## What the truck is seen from: the road in view, how far ahead of the
	## rider the truck is, and which of its lights are on.
	Viewpoint : {
		road : Chain.RoadView,
		lead : Distance,
		lights : Truck.Lights,
	}

	## What became of the truck in a frame.
	Fate : Try(Geom.Sighted(TruckAhead), [NoTruck])

	## The truck, if it is ahead of the rider, on the chain, and in front of
	## the camera.
	truck_in_view : TruckSighting.Viewpoint -> TruckSighting.Fate
	truck_in_view = |view|
		if view.lead > Distance.zero {
			truck_from(
				view,
				{ along: view.road.vantage.along.plus(view.lead), position: Chain.Position.first },
			)
		} else {
			Err(NoTruck)
		}
}

## The truck at `along` measured from the start of the segment at
## `position` in the chain, found by walking on through the segments it is
## past.
truck_from : TruckSighting.Viewpoint,
{
	along : Along,
	position : Chain.Position,
} -> TruckSighting.Fate
truck_from = |view, { along, position }|
	if position.is_past_end_of(view.road.chain_indices) {
		Err(NoTruck)
	} else {
		segment = position.index_in(view.road.chain_indices).segment_in(view.road.route_segments)
		if along > Along.at(segment.length) {
			truck_from(view, { along: along.minus(segment.length), position: position.next() })
		} else {
			truck_on_segment(view, { along, position })
		}
	}

## The truck at `along` on the segment at `position` in the chain, in the
## middle of the road, if it is in front of the camera.
truck_on_segment : TruckSighting.Viewpoint,
{
	along : Along,
	position : Chain.Position,
} -> TruckSighting.Fate
truck_on_segment = |view, { along, position }| {
	across = Across.middle
	center = Chain.rider_point_ahead(view.road, { position, along, across })
	if center.forward > Geom.near_plane {
		Ok({
			right: center.right,
			forward: center.forward,
			kind: { position, along, across, lights: view.lights },
		})
	} else {
		Err(NoTruck)
	}
}
