## RideInstant is one step of the ride, and how the ride moves from one step to
## the next: the rider and the truck each move once, the clock ticks, and the
## encounter on the rider's segment is planned as the rider nears it. A ride
## that has finished starts again from the beginning.
import Animation
import EncounterPlan
import Clock
import Distance
import Route
import Rider
import Segment
import TruckJourney

## One instant of the ride, and all that is kept from one step to the next: the
## rider and the truck, each moved once a step from where it was, the clock,
## which counts the steps, and when the encounter on the rider's segment
## starts. Everything else that changes is worked out from these four. It is
## nominal, not opaque: other modules read its fields.
RideInstant := {
	rider : Rider,
	truck : TruckJourney.TruckProgress,
	clock : Clock,
	encounter_plan : EncounterPlan,
}.{

	initial : RideInstant
	initial = {
		rider: Rider.initial,
		truck: TruckJourney.initial,
		clock: Clock.start,
		encounter_plan: Unplanned,
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

	## Where the encounter on the rider's segment of `route` has got to at
	## `instant`.
	encounter_stage : Route, RideInstant -> Animation.Stage
	encounter_stage = |route, instant|
		instant.rider.motorcycle.route_place.segment_on(route).encounter_stage(
			instant.encounter_plan.timing_at(instant.clock),
		)
}

## The instant a step after `instant`. The world and the rider change each
## other within one step, in this order. First the rider reads the world as it
## stands at the old clock: the stage of the encounter on the rider's segment.
## Then the rider steps, and the clock ticks. Then the world answers the rider
## that has just moved. The truck aims at how far along the route this step's
## rider is, and the encounter plan is kept, forgotten at a new segment, or made
## from this step's rider at the new clock. The rider never reads the truck.
next : Route, RideInstant -> RideInstant
next = |route, instant| {
	stage_before = RideInstant.encounter_stage(route, instant)
	rider = instant.rider.next({ route, encounter_stage: stage_before })
	clock = instant.clock.next()
	rider_place = rider.motorcycle.route_place
	truck = TruckJourney.truck_progress_at_next_step(
		instant.truck,
		{ rider_distance: rider_place.distance_along(route), route },
	)
	segment_change =
		if rider_place.segment_index == instant.rider.motorcycle.route_place.segment_index {
			SameSegment
		} else {
			NewSegment
		}
	encounter_plan = instant.encounter_plan.plan_at_next_step({
		segment_change,
		approach: encounter_approach(rider_place.segment_on(route), rider),
		now: clock,
	})
	{ rider, truck, clock, encounter_plan }
}

## How `rider` comes at `segment`'s encounter, or none on a quiet road.
encounter_approach : Segment, Rider -> EncounterPlan.Approach
encounter_approach = |segment, rider|
	match segment.encounter_span() {
		Ok({ span, planned_along }) =>
			Approaching({
				span,
				gap: planned_along.distance_from(rider.motorcycle.route_place.along),
				speed: rider.motorcycle.speed,
			})
		Err(QuietRoad) => QuietRoad
	}
