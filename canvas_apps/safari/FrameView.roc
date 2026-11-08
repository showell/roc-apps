## FrameView works out what the camera shows at one instant of the ride: the
## backdrop, the ride's shapes in paint order, and the roll, from the camera it
## places for the rider.
import Angle
import Clock
import Grass
import GroundPatch
import GroundSighting
import RideInstant
import RoadAhead
import RiderCamera
import Route
import Scene
import Sky
import Skyline
import Sun
import Truck
import lib.Shapes

## What the camera shows at one instant of the ride, worked out from the
## instant RideInstant keeps: the backdrop, the ride's layers, and the roll the
## camera is held at. `FrameView.ride_shape_lists` puts the layers in paint
## order. It is nominal, not opaque: other modules read its fields, and the
## frame widget builds a view of some of the layers to draw them alone.
FrameView := {
	## What the ride is drawn over.
	backdrop : FrameView.Backdrop,

	## The mountains, darkened as far as the sky is.
	mountain_shapes : List(Shapes.Shape),

	## The road itself and its ponds.
	ground_patch_shapes : List(Shapes.Shape),

	## The things beside the road.
	scene : Scene,

	## The camera's roll: the whole frame, backdrop and shapes, turns by minus
	## this about the screen's centre.
	roll : Angle.Lean,
}.{

	## What the ride is drawn over: the sky and the sun.
	Backdrop : {
		## The sky's colors, at the top of the frame and at the horizon.
		sky_colors : Sky.Colors,

		## Where the sun stands in the sky, if it is in view.
		sun_sighting : Sun.Sighting,
	}

	## The frame at `instant`. The camera is worked out once, for the shapes,
	## the sun and the roll.
	frame_view_at : Route, RideInstant -> FrameView
	frame_view_at = |route, instant| {
		camera = FrameView.camera_at(route, instant)
		road = RoadAhead.RoadView.ahead_of(route, camera.route_place.segment_index)
		{
			backdrop: {
				sky_colors: Sky.colors_at(instant.clock),
				sun_sighting: Sun.sun_in_view(camera, instant.clock),
			},
			mountain_shapes: FrameView.skyline_shapes(camera, instant.clock),
			ground_patch_shapes: FrameView.ground_shapes(road, camera),
			scene: Scene.scene_in_view(
				road,
				{ camera: camera.sighting_camera(), facts: FrameView.ride_facts(route, instant) },
			),
			roll: camera.roll,
		}
	}

	## The ride's shapes in paint order, in the lists they are made in: the
	## skyline, the ground, then each thing beside the road, far to near.
	ride_shape_lists : FrameView -> List(List(Shapes.Shape))
	ride_shape_lists = |view|
		[view.mountain_shapes, view.ground_patch_shapes].concat(Scene.scene_shape_lists(view.scene))

	## The camera the frame at `instant` is seen through.
	camera_at : Route, RideInstant -> RiderCamera
	camera_at = |route, instant|
		RiderCamera.of(
			instant.rider,
			{ route, encounter_stage: RideInstant.encounter_stage(route, instant) },
		)

	## The backdrop's shapes in paint order: the sky, the sun, then the grass,
	## which covers whatever of the sun has set.
	backdrop_shapes : FrameView.Backdrop -> List(Shapes.Shape)
	backdrop_shapes = |backdrop|
		[
			[Sky.sky_shape(backdrop.sky_colors)],
			Sun.sun_shapes(backdrop.sun_sighting),
			[Grass.grass_shape],
		].join()

	## The whole frame in `space`, in paint order: the backdrop, then the
	## ride's shapes, which start with the mountains.
	framed_shapes : FrameView, Shapes.Space -> List(Shapes.Shape)
	framed_shapes = |view, space|
		FrameView.painted_shapes({
			backdrop: view.backdrop,
			ride_shape_lists: FrameView.ride_shape_lists(view),
			space,
		})

	## `ride_shape_lists`, already in paint order, over `backdrop`, all in
	## `space`.
	painted_shapes : {
		backdrop : FrameView.Backdrop,
		ride_shape_lists : List(List(Shapes.Shape)),
		space : Shapes.Space,
	} -> List(Shapes.Shape)
	painted_shapes = |painted| {
		backdrop = FrameView.backdrop_shapes(painted.backdrop)
		Shapes.lists_in_space(painted.space, [backdrop].concat(painted.ride_shape_lists))
	}

	## What the sightings read from `instant` on `route` beyond the road: where
	## the encounter on the rider's segment has got to, where the truck is and
	## which of its lights are on, and the clock.
	ride_facts : Route, RideInstant -> Scene.RideFacts
	ride_facts = |route, instant| {
		encounter_stage: RideInstant.encounter_stage(route, instant),
		truck: {
			route_position: instant.truck.route_position,
			truck: Truck.at(instant.truck.pace, Sky.darkness_at(instant.clock)),
		},
		clock: instant.clock,
	}

	## The skyline `camera` sees at `clock`, darkened as far as the sky is.
	skyline_shapes : RiderCamera, Clock -> List(Shapes.Shape)
	skyline_shapes = |camera, clock| {
		sky_darkness = Sky.darkness_at(clock)
		Skyline.skyline_shapes(camera, { darkness: sky_darkness })
	}

	## The road's ground that `camera` sees of `road`: the road itself and its
	## ponds.
	ground_shapes : RoadAhead.RoadView, RiderCamera -> List(Shapes.Shape)
	ground_shapes = |road, camera|
		GroundSighting.patches_in_view(road, { vantage: camera.vantage() }).keep_oks(
			|patch| GroundPatch.patch_shape(patch, camera.focal_length),
		)
}
