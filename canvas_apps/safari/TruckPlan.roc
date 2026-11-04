## TruckPlan finds the truck ahead of the rider in a frame: how far along
## the chain of segments ahead it is, and whether it is in front of the
## camera.
import DepthSort
import Frame
import Geom
import Scenery
import World

TruckPlan :: [].{

	## The truck, if it is in view: the place in the chain of the segment it
	## is on, how far along that segment it is, and how far ahead of the
	## rider.
	TruckAt : [
		Ahead(
			{
				place : I64,
				along : F64,
				fwd : F64,
			},
		),
		NoTruck,
	]

	## What the truck is seen from: the world's segments, the chain of them
	## ahead of the rider, the rider's pose, how far along its segment the
	## rider is, and how far ahead of the rider the truck is.
	View : {
		world : List(World.Segment),
		chain : List(I64),
		pose : Frame.Pose,
		rider_along : F64,
		lead : F64,
	}

	## The truck, if it is ahead of the rider, on the chain, and in front of
	## the camera.
	in_view : TruckPlan.View -> TruckPlan.TruckAt
	in_view = |view|
		if view.lead > 0.0 {
			truck_from(view, { remaining: (view.rider_along + view.lead), place: 0 })
		} else {
			NoTruck
		}

	## The truck as the depth sort sees it: its distance ahead, if it is in
	## view.
	depth_keys : TruckPlan.TruckAt -> List(DepthSort.DepthKey)
	depth_keys = |truck|
		match truck {
			Ahead(truck_ahead) => [{ forward: truck_ahead.fwd, subject: Truck }]
			NoTruck => []
		}
}

## The truck `remaining` metres past the start of the segment at `place` in
## the chain, found by walking on through the segments it is past.
truck_from : TruckPlan.View, { remaining : F64, place : I64 } -> TruckPlan.TruckAt
truck_from = |view, { remaining, place }|
	match view.chain.get(I64.to_u64_wrap(place)) {
		Err(OutOfBounds) => NoTruck
		Ok(seg_index) => {
			segment = view.world.get(I64.to_u64_wrap(seg_index)) ?? crash "TruckPlan: no such segment"
			if remaining > segment.length {
				truck_from(view, { remaining: (remaining - segment.length), place: (place + 1) })
			} else {
				truck_on_segment(view, { along: remaining, place })
			}
		}
	}

## The truck `along` metres into the segment at `place` in the chain, in
## the middle of the lane, if it is in front of the camera.
truck_on_segment : TruckPlan.View, { along : F64, place : I64 } -> TruckPlan.TruckAt
truck_on_segment = |view, { along, place }| {
	center = Frame.at(
		{
			world: view.world,
			chain: view.chain,
			pose: view.pose,
		},
		{
			segments_ahead: place,
			along: along,
			across: (Scenery.lane_width / 2.0),
		},
	)
	if center.forward > Geom.near {
		Ahead({
			place,
			along,
			fwd: center.forward,
		})
	} else {
		NoTruck
	}
}
