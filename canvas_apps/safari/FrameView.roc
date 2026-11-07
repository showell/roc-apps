import Angle
import Grass
import Ground
import GroundSighting
import LitTruck
import Mountains
import RideInstant
import RoadAhead
import RiderCamera
import Route
import Scene
import SceneShapes
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

	## Which of the truck's lights are on: its headlights once the sun is behind
	## the mountains, and its brake lights while its last step slowed it.
	lit_truck : RideInstant -> LitTruck
	lit_truck = |instant| {
		headlights: if Mountains.is_sun_behind_mountains(instant.clock) {
			On
		} else {
			Off
		},
		brake_lights: match instant.truck.pace {
			Slowing => On
			NotSlowing => Off
		},
	}
}

shapes : RiderCamera, { instant : RideInstant, route : Route } -> List(Shapes.Shape)
shapes = |camera, { instant, route }| {
	s = instant.rider
	road = RoadAhead.RoadView.ahead_of(route, camera.segment_index)
	scene = Scene.scene_in_view(
		road,
		{
			camera,
			facts: {
				speed: s.motorcycle.speed,
				truck: {
					route_position: instant.truck.route_position,
					lit_truck: FrameView.lit_truck(instant),
				},
				clock: instant.clock,
			},
		},
	)
	ground = GroundSighting.patches_in_view(road, camera)
	[
		Mountains.mountain_shapes(camera, Sky.dusk_at(instant.clock)),
		ground.keep_oks(|patch| Ground.patch_shape(patch, camera.cam_focal)),
		SceneShapes.scene_shapes(scene, { road, camera }),
	].join()
}

# The space's first mark, the sky, the grass, the shapes, and the mark back to
# the screen.
expect {
	dot = Rect({
		x: 0.0,
		y: 0.0,
		width: 1.0,
		height: 1.0,
		fill: Flat({
			r: 0.0,
			g: 0.0,
			b: 0.0,
			a: 1.0,
		}),
	})
	view = {
		shapes: [dot],
		sun_sighting: OutOfView,
		sky_colors: Sky.colors_at(RideInstant.initial.clock),
		roll: Angle.upright,
	}
	FrameView.framed_shapes(view, Screen).len() == 5
}
