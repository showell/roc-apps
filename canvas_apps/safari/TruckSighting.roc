## TruckSighting finds the truck ahead of the rider in a frame: how far along
## the chain of segments ahead it is, whether it is in front of the camera,
## and which of its lights the drawing shows.
import Across
import Along
import DepthSort
import Distance
import Chain
import Geom
import Truck

## The truck, if it is in view: the position in the chain of the segment it
## is on, how far along and across that segment it is, how far ahead of the
## rider, and which of its lights are on.
TruckSighting := [
	Ahead(
		{
			position : Chain.Position,
			along : Along,
			across : Across,
			forward : F64,
			lights : Truck.Lights,
		},
	),
	NoTruck,
].{

	## What the truck is seen from: the road in view, how far ahead of the
	## rider the truck is, and which of its lights are on.
	Viewpoint : {
		road : Chain.RoadView,
		lead : Distance,
		lights : Truck.Lights,
	}

	## The truck, if it is ahead of the rider, on the chain, and in front of
	## the camera.
	in_view : TruckSighting.Viewpoint -> TruckSighting
	in_view = |view|
		if view.lead > Distance.zero {
			truck_from(
				view,
				{ along: view.road.vantage.along.plus(view.lead), position: Chain.Position.first },
			)
		} else {
			NoTruck
		}

	## The truck as the depth sort sees it: its distance ahead, if it is in
	## view.
	depth_keys : TruckSighting -> List(DepthSort.DepthKey)
	depth_keys = |truck|
		match truck {
			Ahead(truck_ahead) => [
				{ forward: Distance.metres(truck_ahead.forward), subject: Truck },
			]
			NoTruck => []
		}
}

## The truck at `along` measured from the start of the segment at
## `position` in the chain, found by walking on through the segments it is
## past.
truck_from : TruckSighting.Viewpoint, { along : Along, position : Chain.Position } -> TruckSighting
truck_from = |view, { along, position }|
	if position.is_past_end_of(view.road.chain) {
		NoTruck
	} else {
		segment = position.index_in(view.road.chain).segment_in(view.road.route)
		if along > Along.at(segment.length) {
			truck_from(view, { along: along.minus(segment.length), position: position.next() })
		} else {
			truck_on_segment(view, { along, position })
		}
	}

## The truck at `along` on the segment at `position` in the chain, in the
## middle of the lane, if it is in front of the camera.
truck_on_segment : TruckSighting.Viewpoint,
{
	along : Along,
	position : Chain.Position,
} -> TruckSighting
truck_on_segment = |view, { along, position }| {
	across = Across.middle
	center = Chain.rider_point_ahead(view.road, { position: position, along: along, across })
	if center.forward > Geom.near_plane {
		Ahead({
			position,
			along,
			across,
			forward: center.forward,
			lights: view.lights,
		})
	} else {
		NoTruck
	}
}
