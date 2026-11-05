## TruckPlan finds the truck ahead of the rider in a frame: how far along
## the chain of segments ahead it is, whether it is in front of the camera,
## and which of its lights the drawing shows.
import DepthSort
import Frame
import Geom
import Scenery
import Truck
import World

TruckPlan :: [].{

	## The truck, if it is in view: the position in the chain of the segment it
	## is on, how far along and across that segment it is, how far ahead of the
	## rider, and which of its lights are on.
	TruckAt : [
		Ahead(
			{
				position : Frame.ChainPosition,
				along : F64,
				across : F64,
				forward : F64,
				lights : Truck.Lights,
			},
		),
		NoTruck,
	]

	## What the truck is seen from: the world's segments, the chain of them
	## ahead of the rider, the rider's pose, how far along its segment the
	## rider is, how far ahead of the rider the truck is, and which of its
	## lights are on.
	View : {
		world : List(World.Segment),
		chain : List(World.SegmentIndex),
		pose : Frame.Pose,
		rider_along : F64,
		lead : F64,
		lights : Truck.Lights,
	}

	## The truck, if it is ahead of the rider, on the chain, and in front of
	## the camera.
	in_view : TruckPlan.View -> TruckPlan.TruckAt
	in_view = |view|
		if view.lead > 0.0 {
			truck_from(
				view,
				{ remaining: (view.rider_along + view.lead), position: Frame.ChainPosition.first },
			)
		} else {
			NoTruck
		}

	## The truck as the depth sort sees it: its distance ahead, if it is in
	## view.
	depth_keys : TruckPlan.TruckAt -> List(DepthSort.DepthKey)
	depth_keys = |truck|
		match truck {
			Ahead(truck_ahead) => [{ forward: truck_ahead.forward, subject: Truck }]
			NoTruck => []
		}
}

## The truck `remaining` metres past the start of the segment at `position` in
## the chain, found by walking on through the segments it is past.
truck_from : TruckPlan.View,
{
	remaining : F64,
	position : Frame.ChainPosition,
} -> TruckPlan.TruckAt
truck_from = |view, { remaining, position }|
	if position.is_past_end_of(view.chain) {
		NoTruck
	} else {
		segment = position.index_in(view.chain).segment_in(view.world)
		if remaining > segment.length {
			truck_from(view, { remaining: (remaining - segment.length), position: position.next() })
		} else {
			truck_on_segment(view, { along: remaining, position })
		}
	}

## The truck `along` metres into the segment at `position` in the chain, in
## the middle of the lane, if it is in front of the camera.
truck_on_segment : TruckPlan.View,
{
	along : F64,
	position : Frame.ChainPosition,
} -> TruckPlan.TruckAt
truck_on_segment = |view, { along, position }| {
	across = Scenery.lane_width / 2.0
	center = Frame.rider_point_ahead(
		{
			world: view.world,
			chain: view.chain,
			pose: view.pose,
		},
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
