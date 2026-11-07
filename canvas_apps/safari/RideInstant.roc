import Clock
import Chain
import Ground
import GroundSighting
import SceneShapes
import Mountains
import RiderState
import Scene
import RideFocal
import Rider
import Sky
import Sun
import Truck
import ViewYaw
import World
import lib.Shapes

## One instant of the ride, and all that is kept from one step to the next: the
## rider and the truck, each moved once a step from where it was, and the
## clock, which counts the steps. Everything else that changes is worked out
## from these three.
RideInstant := {
	rider : RiderState,
	truck : Truck.TruckState,
	clock : Clock,
}.{

	initial : RideInstant
	initial = {
		rider: RiderState.initial,
		truck: Truck.initial_truck,
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
			{ index: nx.segment_index, along: nx.along },
		)
		{
			rider: nx,
			truck: Truck.truck_state_at_next_step(
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
	## the mountains, and its brake lights as its last step left them.
	truck_lights : RideInstant -> Truck.Lights
	truck_lights = |instant| {
		headlights: if Mountains.is_sun_behind_mountains(instant.clock) {
			On
		} else {
			Off
		},
		brake_lights: instant.truck.brake_lights,
	}

	shapes : List(World.Segment), RideInstant -> List(Shapes.Shape)
	shapes = |route_segments, instant| {
		s = instant.rider
		view = {
			road: {
				route_segments,
				chain_indices: Chain.indices_ahead(route_segments, s.segment_index),
				vantage: ViewYaw.vantage_for(s),
			},
			cam_focal: RideFocal.ride_focal(route_segments, s),
		}
		scene = Scene.scene_in_view(
			view,
			{
				speed: s.speed,
				truck: {
					route_position: instant.truck.route_position,
					lights: truck_lights(instant),
				},
				clock: instant.clock,
			},
		)
		ground = GroundSighting.patches_in_view(view.road)
		[
			Mountains.mountain_shapes({
				heading: ViewYaw.heading_for(s),
				dusk: Sky.dusk_at(instant.clock),
				cam_focal: view.cam_focal,
			}),
			ground.keep_oks(|patch| Ground.patch_shape(patch, view.cam_focal)),
			SceneShapes.scene_shapes(scene, view),
		].join()
	}

	sun : List(World.Segment), RideInstant -> Sun.Sighting
	sun = |route_segments, instant| {
		cf = RideFocal.ride_focal(route_segments, instant.rider)
		Sun.sighting({
			heading: ViewYaw.heading_for(instant.rider),
			clock: instant.clock,
			cam_focal: cf,
		})
	}
}

expect RideInstant.initial.clock.to_f64() == 0.0
expect RideInstant.initial.rider.along.to_metres() == 0.0
expect RideInstant.initial.rider.across.to_metres() == 0.0
expect RideInstant.initial.rider.speed.to_metres_a_step() == 0.3
expect RideInstant.initial.truck.route_position.to_metres() == 500.0
expect RideInstant.initial.truck.speed.to_metres_a_step() == 0.3
expect RideInstant.initial.rider.segment_index.to_i64() == 0
expect RideInstant.initial.truck.brake_lights == Off
expect !Rider.is_finished(RideInstant.initial.rider, World.segments)

after_one_step : RideInstant
after_one_step = RideInstant.next_or_restart(World.segments, RideInstant.initial)

after_two_steps : RideInstant
after_two_steps = RideInstant.next_or_restart(World.segments, after_one_step)

expect after_one_step.clock.to_f64() == 1.0
expect after_two_steps.clock.to_f64() == 2.0
expect after_two_steps.clock.to_f64() - after_one_step.clock.to_f64() == 1.0
expect after_one_step.rider.along > RideInstant.initial.rider.along
expect after_one_step.truck.route_position > RideInstant.initial.truck.route_position
expect after_two_steps.rider.along > after_one_step.rider.along
expect {
	old_dist = World.distance_along_route(
		World.segments,
		{ index: RideInstant.initial.rider.segment_index, along: RideInstant.initial.rider.along },
	)
	new_dist = World.distance_along_route(
		World.segments,
		{ index: after_one_step.rider.segment_index, along: after_one_step.rider.along },
	)
	against_new = Truck.truck_state_at_next_step(
		RideInstant.initial.truck,
		{
			rider_distance: new_dist,
			route_segments: World.segments,
			route_length: World.route_length(World.segments),
		},
	)
	against_old = Truck.truck_state_at_next_step(
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
expect RideInstant.sun(World.segments, RideInstant.initial) == OutOfView

## A clock with the sun behind the mountains.
after_sunset : Clock
after_sunset = Clock.at_step(5700)

## The truck's lights at `clock`, with its brake lights left as given.
lights_at : { clock : Clock, brake_lights : [On, Off] } -> Truck.Lights
lights_at = |{ clock, brake_lights }|
	RideInstant.truck_lights({
		..RideInstant.initial,
		truck: { ..RideInstant.initial.truck, brake_lights },
		clock,
	})

expect
	lights_at({ clock: Clock.start, brake_lights: Off })
		== { headlights: Off, brake_lights: Off }
expect lights_at({ clock: Clock.start, brake_lights: On }) == { headlights: Off, brake_lights: On }
expect
	lights_at({ clock: after_sunset, brake_lights: Off })
		== { headlights: On, brake_lights: Off }
expect lights_at({ clock: after_sunset, brake_lights: On }) == { headlights: On, brake_lights: On }
