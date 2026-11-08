## RideInstant is one step of the ride, and how the ride moves from one step to
## the next: the rider and the truck each move once, the clock ticks, and the
## encounter on the rider's segment is planned as the rider nears it. A ride
## that has finished starts again from the beginning.
import EncounterPlan
import BirdFlight
import Cat
import Clock
import Distance
import Route
import Rider
import Segment
import Truck

## One instant of the ride, and all that is kept from one step to the next: the
## rider and the truck, each moved once a step from where it was, the clock,
## which counts the steps, and when the encounter on the rider's segment
## starts. Everything else that changes is worked out from these four. It is
## nominal, not opaque: other modules read its fields.
RideInstant := {
	rider : Rider,
	truck : Truck,
	clock : Clock,
	encounter_start : EncounterPlan.Start,
}.{

	initial : RideInstant
	initial = {
		rider: Rider.initial,
		truck: Truck.initial,
		clock: Clock.start,
		encounter_start: Unplanned,
	}

	## The instant a step after `instant`, or the ride's start again once the
	## rider has finished; the tag says which.
	next_or_restart : Route, RideInstant -> [Continued(RideInstant), Restarted(RideInstant)]
	next_or_restart = |route, instant|
		if instant.rider.is_finished(route) {
			Restarted(initial)
		} else {
			Continued(next(route, instant))
		}

	## How far along `route` the rider of `instant` is.
	rider_distance : Route, RideInstant -> Distance
	rider_distance = |route, instant| instant.rider.motorcycle.route_place.distance_along(route)

	## Where the encounter on the rider's segment stands at `instant`.
	encounter_timing : RideInstant -> EncounterPlan.Timing
	encounter_timing = |instant| EncounterPlan.timing_of(instant.encounter_start, instant.clock)
}

## The instant a step after `instant`. The rider steps with the encounter's
## timing at the old clock: the hand of god moves the cat, then the rider reacts.
next : Route, RideInstant -> RideInstant
next = |route, instant| {
	next_rider = instant.rider.next(
		{ route, encounter_timing: RideInstant.encounter_timing(instant) },
	)
	clock = instant.clock.next()
	from = instant.rider.motorcycle.route_place
	to = next_rider.motorcycle.route_place
	kept_start =
		if to.segment_index == from.segment_index {
			instant.encounter_start
		} else {
			Unplanned
		}
	{
		rider: next_rider,
		truck: Truck.truck_at_next_step(
			instant.truck,
			{ rider_distance: to.distance_along(route), route },
		),
		clock,
		encounter_start: match kept_start {
			StartsAt(_) => kept_start
			Unplanned => planned_start(to.segment_on(route), { rider: next_rider, now: clock })
		},
	}
}

## The start the ride plans for `segment`'s encounter, with `rider` on it at
## `now`: unplanned until the rider comes within reach of it.
planned_start : Segment, { rider : Rider, now : Clock } -> EncounterPlan.Start
planned_start = |segment, { rider, now }| {
	plan_for = |span, animal_along|
		EncounterPlan.planned_start(
			span,
			{
				gap: animal_along.distance_from(rider.motorcycle.route_place.along),
				speed: rider.motorcycle.speed,
				now,
			},
		)
	match segment.encounter {
		CatCrosses(crossing) => plan_for(Cat.crossing_span, crossing.along())
		BirdHere(flight) => plan_for(BirdFlight.flight_span, flight.from.road_point.along)
		QuietRoad => Unplanned
	}
}
