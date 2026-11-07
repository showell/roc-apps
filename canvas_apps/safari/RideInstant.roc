import Animation
import BirdFlight
import Cat
import Clock
import Route
import RiderState
import Rider
import Segment
import Truck

## One instant of the ride, and all that is kept from one step to the next: the
## rider and the truck, each moved once a step from where it was, the clock,
## which counts the steps, and when the encounter on the rider's segment
## starts. Everything else that changes is worked out from these four.
RideInstant := {
	rider : RiderState,
	truck : Truck,
	clock : Clock,
	encounter_start : Animation.Start,
}.{

	initial : RideInstant
	initial = {
		rider: RiderState.initial,
		truck: Truck.initial,
		clock: Clock.start,
		encounter_start: Unplanned,
	}

	next_or_restart : Route, RideInstant -> RideInstant
	next_or_restart = |route, instant|
		if Rider.is_finished(instant.rider, route) {
			initial
		} else {
			next(route, instant)
		}

	## Where the encounter on the rider's segment stands at `instant`.
	encounter_timing : RideInstant -> Animation.Timing
	encounter_timing = |instant| Animation.timing_of(instant.encounter_start, instant.clock)
}

next : Route, RideInstant -> RideInstant
next = |route, instant| {
	nx = Rider.rider_state_at_next_step(
		instant.rider,
		{ route, encounter: RideInstant.encounter_timing(instant) },
	)
	dist = route.distance_along_route({ index: nx.segment_index, along: nx.motorcycle.along })
	clock = instant.clock.next()
	kept_start =
		if nx.segment_index == instant.rider.segment_index {
			instant.encounter_start
		} else {
			Unplanned
		}
	{
		rider: nx,
		truck: Truck.at_next_step(instant.truck, { rider_distance: dist, route }),
		clock,
		encounter_start: match kept_start {
			StartsAt(_) => kept_start
			Unplanned => planned_start(
				route.segment_at(nx.segment_index),
				{ rider: nx, now: clock },
			)
		},
	}
}

## The start the ride plans for `segment`'s encounter, with `rider` on it at
## `now`: unplanned until the rider comes within reach of it.
planned_start : Segment, { rider : RiderState, now : Clock } -> Animation.Start
planned_start = |segment, { rider, now }| {
	plan_for = |span, critter_along|
		Animation.planned_start(
			span,
			{
				approach: {
					gap: critter_along.distance_from(rider.motorcycle.along),
					speed: rider.motorcycle.speed,
				},
				now,
			},
		)
	match segment.encounter {
		CatCrosses(crossing) => plan_for(Cat.crossing_span, crossing.along)
		BirdHere(flight) => plan_for(BirdFlight.flight_span, flight.from.road_point.along)
		QuietRoad => Unplanned
	}
}
