import Clock
import Route
import RiderState
import Rider
import Truck

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
