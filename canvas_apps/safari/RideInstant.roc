import Clock
import Route
import RiderState
import Rider
import Steps
import Truck
import World

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

	next_or_restart : Route, RideInstant -> RideInstant
	next_or_restart = |route, instant|
		if Rider.is_finished(instant.rider, route) {
			initial
		} else {
			next(route, instant)
		}
}

next : Route, RideInstant -> RideInstant
next = |route, instant| {
	nx = Rider.rider_state_at_next_step(instant.rider, route)
	dist = route.distance_along_route({ index: nx.segment_index, along: nx.motorcycle.along })
	{
		rider: nx,
		truck: Truck.at_next_step(
			instant.truck,
			{ rider_distance: dist, route, route_length: route.route_length() },
		),
		clock: instant.clock.next(),
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
expect !Rider.is_finished(RideInstant.initial.rider, World.route)

after_one_step : RideInstant
after_one_step = RideInstant.next_or_restart(World.route, RideInstant.initial)

after_two_steps : RideInstant
after_two_steps = RideInstant.next_or_restart(World.route, after_one_step)

expect after_one_step.clock.to_f64() == 1.0
expect after_two_steps.clock.to_f64() == 2.0
expect after_two_steps.clock.steps_since(after_one_step.clock) == Steps.one_step
expect after_one_step.rider.motorcycle.along > RideInstant.initial.rider.motorcycle.along
expect after_one_step.truck.route_position > RideInstant.initial.truck.route_position
expect after_two_steps.rider.motorcycle.along > after_one_step.rider.motorcycle.along
expect {
	old_dist = World.route.distance_along_route({
		index: RideInstant.initial.rider.segment_index,
		along: RideInstant.initial.rider.motorcycle.along,
	})
	new_dist = World.route.distance_along_route(
		{ index: after_one_step.rider.segment_index, along: after_one_step.rider.motorcycle.along },
	)
	against_new = Truck.at_next_step(
		RideInstant.initial.truck,
		{
			rider_distance: new_dist,
			route: World.route,
			route_length: World.route.route_length(),
		},
	)
	against_old = Truck.at_next_step(
		RideInstant.initial.truck,
		{
			rider_distance: old_dist,
			route: World.route,
			route_length: World.route.route_length(),
		},
	)
	new_position = against_new.route_position
	old_position = against_old.route_position
	after_one_step.truck.route_position == new_position
		and new_dist > old_dist
		and new_position != old_position
}

expect after_one_step.clock != Clock.start
expect !Rider.is_finished(after_one_step.rider, World.route)
