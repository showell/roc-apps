import Angle
import CanvasRoll
import Ground
import GroundSighting
import Lens
import LitTruck
import Mountains
import RideFocal
import RideInstant
import RoadAhead
import Route
import Scene
import SceneShapes
import Sky
import Sun
import ViewYaw
import lib.Shapes

## What the camera shows at one instant of the ride, worked out from the
## instant RideInstant keeps: the shapes in paint order, the sun, the sky's two
## colors, and the roll the camera is held at.
FrameView := {
	## The ride's shapes in paint order, drawn over the backdrop.
	shapes : List(Shapes.Shape),

	## Where the sun stands in the sky, if it is in view.
	sun : Sun.Sighting,

	## The sky's colors, at the top of the frame and at the horizon.
	sky_colors : Sky.Colors,

	## The camera's roll: the whole frame, backdrop and shapes, turns by minus
	## this about the screen's centre.
	roll : Angle.Lean,
}.{

	## The frame at `instant`. The camera's heading and focal length are worked
	## out once, for both the shapes and the sun.
	frame_view_at : Route, RideInstant -> FrameView
	frame_view_at = |route, instant| {
		aim = {
			heading: ViewYaw.heading_for(instant.rider),
			cam_focal: RideFocal.ride_focal(instant.rider, route),
		}
		{
			shapes: shapes(instant, { route, aim }),
			sun: Sun.sighting(aim, instant.clock),
			sky_colors: Sky.colors_at(instant.clock),
			roll: CanvasRoll.rider_roll(instant.rider.motorcycle.lean),
		}
	}

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

shapes : RideInstant, { route : Route, aim : Lens.CameraAim } -> List(Shapes.Shape)
shapes = |instant, { route, aim }| {
	cam_focal = aim.cam_focal
	s = instant.rider
	view = {
		road: {
			route,
			segments_ahead: RoadAhead.indices_ahead(route, s.segment_index),
			vantage: ViewYaw.vantage_for(s),
		},
		cam_focal,
	}
	scene = Scene.scene_in_view(
		view,
		{
			speed: s.motorcycle.speed,
			truck: {
				route_position: instant.truck.route_position,
				lit_truck: FrameView.lit_truck(instant),
			},
			clock: instant.clock,
		},
	)
	ground = GroundSighting.patches_in_view(view.road)
	[
		Mountains.mountain_shapes(aim, Sky.dusk_at(instant.clock)),
		ground.keep_oks(|patch| Ground.patch_shape(patch, cam_focal)),
		SceneShapes.scene_shapes(scene, view),
	].join()
}
