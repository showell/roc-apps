import Clock
import RoadAhead
import Ground
import GroundSighting
import Lens
import SceneShapes
import Mountains
import RiderState
import Scene
import RideFocal
import Rider
import Sky
import Steps
import Sun
import Truck
import LitTruck
import ViewYaw
import World
import lib.Shapes

## One instant of the ride, and all that is kept from one step to the next: the
## rider and the truck, each moved once a step from where it was, and the
## clock, which counts the steps. Everything else that changes is worked out
## from these three.
RideInstant := {
	rider : RiderState,
	truck : Truck,
	clock : Clock,
}.{

	initial : RideInstant
	initial = {
		rider: RiderState.initial,
		truck: Truck.initial,
		clock: Clock.start,
	}

	next_or_restart : List(World.Segment), RideInstant -> RideInstant
	next_or_restart = |route_segments, instant|
		if Rider.is_finished(instant.rider, route_segments) {
			initial
		} else {
			next(route_segments, instant)
		}

	next : List(World.Segment), RideInstant -> RideInstant
	next = |route_segments, instant| {
		nx = Rider.rider_state_at_next_step(instant.rider, route_segments)
		dist = World.distance_along_route(
			route_segments,
			{ index: nx.segment_index, along: nx.motorcycle.along },
		)
		{
			rider: nx,
			truck: Truck.at_next_step(
				instant.truck,
				{
					rider_distance: dist,
					route_segments,
					route_length: World.route_length(route_segments),
				},
			),
			clock: instant.clock.next(),
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

	## What the camera shows at one instant: the shapes in paint order, and the
	## sun.
	FrameContent : { shapes : List(Shapes.Shape), sun : Sun.Sighting }

	## The frame at `instant`. The camera's heading and focal length are worked
	## out once, for both the shapes and the sun.
	frame_content : List(World.Segment), RideInstant -> RideInstant.FrameContent
	frame_content = |route_segments, instant| {
		aim = {
			heading: ViewYaw.heading_for(instant.rider),
			cam_focal: RideFocal.ride_focal(instant.rider, route_segments),
		}
		{ shapes: shapes(instant, { route_segments, aim }), sun: Sun.sighting(aim, instant.clock) }
	}

	shapes : RideInstant,
	{
		route_segments : List(World.Segment),
		aim : Lens.CameraAim,
	} -> List(Shapes.Shape)
	shapes = |instant, { route_segments, aim }| {
		cam_focal = aim.cam_focal
		s = instant.rider
		view = {
			road: {
				route_segments,
				segments_ahead: RoadAhead.indices_ahead(route_segments, s.segment_index),
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
					lit_truck: lit_truck(instant),
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
}

expect RideInstant.initial.clock.to_f64() == 0.0
expect RideInstant.initial.rider.motorcycle.along.to_metres() == 0.0
expect RideInstant.initial.rider.motorcycle.across.to_metres() == 0.0
expect RideInstant.initial.rider.motorcycle.speed.to_metres_a_step() == 0.3
expect RideInstant.initial.truck.route_position.to_metres() == 500.0
expect RideInstant.initial.truck.speed.to_metres_a_step() == 0.3
expect RideInstant.initial.rider.segment_index.to_i64() == 0
expect RideInstant.initial.truck.pace == NotSlowing
expect !Rider.is_finished(RideInstant.initial.rider, World.segments)

after_one_step : RideInstant
after_one_step = RideInstant.next_or_restart(World.segments, RideInstant.initial)

after_two_steps : RideInstant
after_two_steps = RideInstant.next_or_restart(World.segments, after_one_step)

expect after_one_step.clock.to_f64() == 1.0
expect after_two_steps.clock.to_f64() == 2.0
expect after_two_steps.clock.steps_since(after_one_step.clock) == Steps.one_step
expect after_one_step.rider.motorcycle.along > RideInstant.initial.rider.motorcycle.along
expect after_one_step.truck.route_position > RideInstant.initial.truck.route_position
expect after_two_steps.rider.motorcycle.along > after_one_step.rider.motorcycle.along
expect {
	old_dist = World.distance_along_route(
		World.segments,
		{
			index: RideInstant.initial.rider.segment_index,
			along: RideInstant.initial.rider.motorcycle.along,
		},
	)
	new_dist = World.distance_along_route(
		World.segments,
		{ index: after_one_step.rider.segment_index, along: after_one_step.rider.motorcycle.along },
	)
	against_new = Truck.at_next_step(
		RideInstant.initial.truck,
		{
			rider_distance: new_dist,
			route_segments: World.segments,
			route_length: World.route_length(World.segments),
		},
	)
	against_old = Truck.at_next_step(
		RideInstant.initial.truck,
		{
			rider_distance: old_dist,
			route_segments: World.segments,
			route_length: World.route_length(World.segments),
		},
	)
	new_position = against_new.route_position
	old_position = against_old.route_position
	after_one_step.truck.route_position == new_position
		and new_dist > old_dist
		and new_position != old_position
}

expect after_one_step.clock != Clock.start
expect !Rider.is_finished(after_one_step.rider, World.segments)

# The ride starts facing away from the sun.
expect RideInstant.frame_content(World.segments, RideInstant.initial).sun == OutOfView

## A clock with the sun behind the mountains.
after_sunset : Clock
after_sunset = Clock.at_step(5700)

## The truck's lights at `clock`, with the truck's pace as given.
lights_at : { clock : Clock, pace : [Slowing, NotSlowing] } -> LitTruck
lights_at = |{ clock, pace }|
	RideInstant.lit_truck({
		..RideInstant.initial,
		truck: { ..RideInstant.initial.truck, pace },
		clock,
	})

expect lights_at({ clock: Clock.start, pace: NotSlowing }) == { headlights: Off, brake_lights: Off }
expect lights_at({ clock: Clock.start, pace: Slowing }) == { headlights: Off, brake_lights: On }
expect lights_at({ clock: after_sunset, pace: NotSlowing }) == { headlights: On, brake_lights: Off }
expect lights_at({ clock: after_sunset, pace: Slowing }) == { headlights: On, brake_lights: On }
