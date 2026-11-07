import Angle
import Clock
import Grass
import GroundPatch
import GroundSighting
import LitTruck
import Mountains
import RideInstant
import RoadAhead
import RiderCamera
import Route
import Scene
import Sky
import Sun
import lib.Shapes

## What the camera shows at one instant of the ride, worked out from the
## instant RideInstant keeps: the shapes in paint order, the sun, the sky's two
## colors, and the roll the camera is held at.
FrameView := {
	## The ride's shapes in paint order, drawn over the backdrop.
	shapes : List(Shapes.Shape),

	## Where the sun stands in the sky, if it is in view.
	sun_sighting : Sun.Sighting,

	## The sky's colors, at the top of the frame and at the horizon.
	sky_colors : Sky.Colors,

	## The camera's roll: the whole frame, backdrop and shapes, turns by minus
	## this about the screen's centre.
	roll : Angle.Lean,
}.{

	## The frame at `instant`. The camera is worked out once, for the shapes,
	## the sun and the roll.
	frame_view_at : Route, RideInstant -> FrameView
	frame_view_at = |route, instant| {
		camera = RiderCamera.of(instant.rider, route)
		{
			shapes: shapes(camera, { instant, route }),
			sun_sighting: Sun.sighting(camera, instant.clock),
			sky_colors: Sky.colors_at(instant.clock),
			roll: camera.roll,
		}
	}

	## The whole frame in `space`, in paint order: the sky, the sun, the grass,
	## then the ride's shapes, which start with the mountains. The grass covers
	## whatever of the sun has set.
	framed_shapes : FrameView, Shapes.Space -> List(Shapes.Shape)
	framed_shapes = |view, space|
		Shapes.in_space(
			space,
			[
				[Sky.sky_shape(view.sky_colors)],
				Sun.sun_shapes(view.sun_sighting),
				[Grass.grass_shape],
				view.shapes,
			].join(),
		)

	## What the sightings read from `instant` beyond the road: the rider's
	## speed, where the truck is and which of its lights are on, and the clock.
	ride_facts : RideInstant -> Scene.RideFacts
	ride_facts = |instant| {
		speed: instant.rider.motorcycle.speed,
		truck: {
			route_position: instant.truck.route_position,
			lit_truck: LitTruck.at(instant.truck, instant.clock),
		},
		clock: instant.clock,
	}

	## The skyline `camera` sees at `clock`, darkened as far as the sky is.
	skyline_shapes : RiderCamera, Clock -> List(Shapes.Shape)
	skyline_shapes = |camera, clock| Mountains.mountain_shapes(camera, Sky.darkness_at(clock))

	## The road's ground that `camera` sees of `road`: the road itself and its
	## ponds.
	ground_shapes : RoadAhead.RoadView, RiderCamera -> List(Shapes.Shape)
	ground_shapes = |road, camera|
		GroundSighting.patches_in_view(road, camera).keep_oks(
			|patch| GroundPatch.patch_shape(patch, camera.cam_focal),
		)
}

shapes : RiderCamera, { instant : RideInstant, route : Route } -> List(Shapes.Shape)
shapes = |camera, { instant, route }| {
	road = RoadAhead.RoadView.ahead_of(route, camera.segment_index)
	scene = Scene.scene_in_view(road, { camera, facts: FrameView.ride_facts(instant) })
	[
		FrameView.skyline_shapes(camera, instant.clock),
		FrameView.ground_shapes(road, camera),
		Scene.scene_shapes(scene),
	].join()
}
