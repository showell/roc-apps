## TruckSighting finds the truck ahead of the rider in a frame: how far along
## the road ahead it is, whether it is in front of the camera,
## and which of its lights the drawing shows.
import Across
import Along
import Distance
import RoadAhead
import Geom
import Pipeline
import Truck
import TruckAhead

TruckSighting :: [].{

	## What became of the truck in a frame.
	TruckFate : Try(Pipeline.Sighted(TruckAhead), [NoTruck, BehindCamera])

	## The truck `lead` ahead of the rider with `lights` on, if it is ahead of the
	## rider, on the road ahead, and in front of the camera.
	truck_in_view : RoadAhead.RoadView,
	{
		lead : Distance,
		lights : Truck.Lights,
	} -> TruckSighting.TruckFate
	truck_in_view = |road, { lead, lights }|
		if lead > Distance.zero {
			truck_from(
				road,
				{
					along: road.vantage.along.plus(lead),
					position: RoadAhead.Position.first,
					lights,
				},
			)
		} else {
			Err(NoTruck)
		}
}

## The truck at `along` measured from the start of the segment at
## `position` on the road ahead, found by walking on through the segments it
## is past.
truck_from : RoadAhead.RoadView,
{
	along : Along,
	position : RoadAhead.Position,
	lights : Truck.Lights,
} -> TruckSighting.TruckFate
truck_from = |road, { along, position, lights }|
	if position.is_past_end_of(road.segments_ahead) {
		Err(NoTruck)
	} else {
		segment = RoadAhead.segment_at(road, position)
		if along > Along.at(segment.length) {
			truck_from(
				road,
				{
					along: along.minus(segment.length),
					position: position.next(),
					lights,
				},
			)
		} else {
			truck_on_segment(road, { along, position, lights })
		}
	}

## The truck at `along` on the segment at `position` on the road ahead, in
## the middle of the road, if it is in front of the camera.
truck_on_segment : RoadAhead.RoadView,
{
	along : Along,
	position : RoadAhead.Position,
	lights : Truck.Lights,
} -> TruckSighting.TruckFate
truck_on_segment = |road, { along, position, lights }| {
	placed_truck : Geom.Placed(TruckAhead)
	placed_truck = { along, across: Across.middle, kind: { lights } }
	Pipeline.sighting_of(placed_truck, { road, place: Ahead(position) })
}
