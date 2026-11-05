## TruckSighting finds the truck ahead of the rider in a frame: how far along
## the chain of segments ahead it is, whether it is in front of the camera,
## and which of its lights the drawing shows.
import Across
import Along
import DepthSort
import Distance
import Frame
import Geom
import Scenery
import Truck

TruckSighting :: [].{

	## The truck, if it is in view: the position in the chain of the segment it
	## is on, how far along and across that segment it is, how far ahead of the
	## rider, and which of its lights are on.
	TruckAt : [
		Ahead(
			{
				position : Frame.ChainPosition,
				along : Along,
				across : Across,
				forward : F64,
				lights : Truck.Lights,
			},
		),
		NoTruck,
	]

	## What the truck is seen from: the road in view, how far ahead of the
	## rider the truck is, and which of its lights are on.
	View : {
		road : Frame.RoadView,
		lead : Distance,
		lights : Truck.Lights,
	}

	## The truck, if it is ahead of the rider, on the chain, and in front of
	## the camera.
	in_view : TruckSighting.View -> TruckSighting.TruckAt
	in_view = |view|
		if view.lead > Distance.zero {
			truck_from(
				view,
				{
					remaining: view.road.pose.along.plus(view.lead),
					position: Frame.ChainPosition.first,
				},
			)
		} else {
			NoTruck
		}

	## The truck as the depth sort sees it: its distance ahead, if it is in
	## view.
	depth_keys : TruckSighting.TruckAt -> List(DepthSort.DepthKey)
	depth_keys = |truck|
		match truck {
			Ahead(truck_ahead) => [{ forward: truck_ahead.forward, subject: Truck }]
			NoTruck => []
		}
}

## The truck at `remaining` measured from the start of the segment at
## `position` in the chain, found by walking on through the segments it is
## past.
truck_from : TruckSighting.View,
{
	remaining : Along,
	position : Frame.ChainPosition,
} -> TruckSighting.TruckAt
truck_from = |view, { remaining, position }|
	if position.is_past_end_of(view.road.chain) {
		NoTruck
	} else {
		segment = position.index_in(view.road.chain).segment_in(view.road.world)
		if remaining > Along.at(segment.length) {
			truck_from(
				view,
				{ remaining: remaining.minus(segment.length), position: position.next() },
			)
		} else {
			truck_on_segment(view, { along: remaining, position })
		}
	}

## The truck at `along` on the segment at `position` in the chain, in the
## middle of the lane, if it is in front of the camera.
truck_on_segment : TruckSighting.View,
{
	along : Along,
	position : Frame.ChainPosition,
} -> TruckSighting.TruckAt
truck_on_segment = |view, { along, position }| {
	across = Scenery.from_left_edge(Across.middle)
	center = Frame.rider_point_ahead(
		view.road,
		{
			position: position,
			along: along,
			across,
		},
	)
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
