## TruckSighting finds the truck ahead of the rider in a frame: how far along
## the road ahead it is, and whether it is in front of the camera.
import Across
import Along
import Distance
import RoadAhead
import SegmentPlace
import Geom
import Pipeline
import TruckAhead

TruckSighting :: [].{

	## What became of the truck in a frame.
	TruckFate : Try(Pipeline.Sighted(TruckAhead), [NoTruck, BehindCamera])

	## The truck `lead` ahead of the rider, looking as `truck_ahead` says, if it
	## is ahead of the rider, on the road ahead, and in front of the camera.
	truck_in_view : RoadAhead.RoadView,
	{
		lead : Distance,
		truck_ahead : TruckAhead,
	} -> TruckSighting.TruckFate
	truck_in_view = |road, { lead, truck_ahead }|
		if lead > Distance.zero {
			start = { along: road.vantage.along.plus(lead), position: SegmentPlace.Position.first }
			match truck_from(road, start) {
				Ok({ along, position }) => {
					placed_truck : Geom.Placed(TruckAhead)
					placed_truck = { along, across: Across.middle, kind: truck_ahead }
					Pipeline.sighting_of(placed_truck, { road, place: Ahead(position) })
				}
				Err(NoTruck) => Err(NoTruck)
			}
		} else {
			Err(NoTruck)
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
	if position.is_past_end_of(road.segments_ahead) {
		Err(NoTruck)
	} else {
		segment = RoadAhead.segment_at(road, position)
		if along > Along.at(segment.length) {
			truck_from(road, { along: along.minus(segment.length), position: position.next() })
		} else {
			Ok({ along, position })
		}
	}
