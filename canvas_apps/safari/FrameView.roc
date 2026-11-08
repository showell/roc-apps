## FrameView works out what the camera shows at one instant of the ride: the
## backdrop, the ride's shapes in paint order, and the roll, from the camera it
## places for the rider. It also gives the space the whole frame leans in at
## that roll.
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
import Screen
import Sky
import Sun
import lib.Shapes

## What the camera shows at one instant of the ride, worked out from the
## instant RideInstant keeps: the backdrop, the ride's shapes in paint order,
## and the roll the camera is held at. It is nominal, not opaque: other
## modules read its fields.
FrameView := {
	## What the ride is drawn over.
	backdrop : FrameView.Backdrop,

	## The ride's shapes in paint order, drawn over the backdrop, in the lists
	## they are made in: the skyline, the ground, then each thing beside the
	## road. The frame joins them with the backdrop's, copying each shape once.
	ride_shape_lists : List(List(Shapes.Shape)),

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
		{
			backdrop: {
				sky_colors: Sky.colors_at(instant.clock),
				sun_sighting: Sun.sun_in_view(camera, instant.clock),
			},
			ride_shape_lists: ride_shape_lists(camera, { instant, route }),
			roll: camera.roll,
		}
	}

	## The camera the frame at `instant` is seen through.
	camera_at : Route, RideInstant -> RiderCamera
	camera_at = |route, instant|
		RiderCamera.of(
			instant.rider,
			{ route, encounter_timing: RideInstant.encounter_timing(instant) },
		)

	## The backdrop's shapes in paint order: the sky, the sun, then the grass,
	## which covers whatever of the sun has set.
	backdrop_shapes : FrameView -> List(Shapes.Shape)
	backdrop_shapes = |view|
		[
			[Sky.sky_shape(view.backdrop.sky_colors)],
			Sun.sun_shapes(view.backdrop.sun_sighting),
			[Grass.grass_shape],
		].join()

	## The whole frame in `space`, in paint order: the backdrop, then the
	## ride's shapes, which start with the mountains.
	framed_shapes : FrameView, Shapes.Space -> List(Shapes.Shape)
	framed_shapes = |view, space| {
		backdrop = FrameView.backdrop_shapes(view)
		Shapes.lists_in_space(space, [backdrop].concat(view.ride_shape_lists))
	}

	## The space the whole frame leans in, at the camera's `roll`.
	lean_space : Angle.Lean -> Shapes.Space
	lean_space = |roll| {
		center = { x: Screen.width.to_f64() / 2.0, y: Screen.height.to_f64() / 2.0 }
		World({
			target: center,
			offset: center,
			rotation: 0.0 - roll.to_degrees(),
			zoom: 1.0,
		})
	}

	## What the sightings read from `instant` beyond the road: where the
	## encounter on the rider's segment stands, where the truck is and which of
	## its lights are on, and the clock.
	ride_facts : RideInstant -> Scene.RideFacts
	ride_facts = |instant| {
		encounter_timing: RideInstant.encounter_timing(instant),
		truck: {
			route_position: instant.truck.route_position,
			lit_truck: LitTruck.at(instant.truck.pace, Sky.darkness_at(instant.clock)),
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
		GroundSighting.patches_in_view(road, { vantage: camera.vantage() }).keep_oks(
			|patch| GroundPatch.patch_shape(patch, camera.focal_length),
		)
}

## The ride's shapes in paint order, in the lists they are made in: the
## skyline, the ground, then each thing beside the road.
ride_shape_lists : RiderCamera, { instant : RideInstant, route : Route } -> List(List(Shapes.Shape))
ride_shape_lists = |camera, { instant, route }| {
	road = RoadAhead.RoadView.ahead_of(route, camera.route_place.segment_index)
	scene = Scene.scene_in_view(
		road,
		{ camera: camera.sighting_camera(), facts: FrameView.ride_facts(instant) },
	)
	[
		FrameView.skyline_shapes(camera, instant.clock),
		FrameView.ground_shapes(road, camera),
	].concat(Scene.scene_shape_lists(scene))
}
