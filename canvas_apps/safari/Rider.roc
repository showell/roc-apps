## The rider from one step to the next: the motorcycle they ride, which knows
## where on the route it is, and where their eyes are.
import Along
import Attention
import EncounterPlan
import EncounterReaction
import Motorcycle
import RiderEyes
import RiderMind
import Route
import Segment

## The rider at one step. Nominal, not opaque: other modules read its fields.
Rider := { motorcycle : Motorcycle, eyes : RiderEyes }.{

	initial : Rider
	initial = { motorcycle: Motorcycle.initial, eyes: RiderEyes.initial }

	## The rider a step on along `route`, with the encounter on their segment at
	## `encounter_timing`: the move, the crossing onto the next segment, the stop
	## at the route's end, and then where the rider looks.
	next : Rider, { route : Route, encounter_timing : EncounterPlan.Timing } -> Rider
	next = |rider, { route, encounter_timing }| {
		segment = rider.motorcycle.route_place.segment_on(route)
		moved = rider.motorcycle.motorcycle_at_next_step(
			RiderMind.controls(rider.motorcycle, { segment, encounter_timing }),
		)
		motorcycle =
			match segment.segment_ending() {
				Bends({ bend, .. }) => moved.cross_bend_if_on_road(bend)
				RouteEnds => stop_at_route_end(moved, segment)
			}
		gaze_target = RiderMind.gaze_target(motorcycle, motorcycle.route_place.segment_on(route))
		{ motorcycle, eyes: rider.eyes.eyes_at_next_step(gaze_target) }
	}

	## Whether the rider has reached the end of the route.
	is_finished : Rider, Route -> Bool
	is_finished = |rider, route| {
		segment = rider.motorcycle.route_place.segment_on(route)
		match segment.segment_ending() {
			Bends(_) => False
			RouteEnds => rider.motorcycle.has_reached(segment.length)
		}
	}

	## How strongly something holds the rider's eye on `segment`, with its
	## encounter at `encounter_timing`: the stronger of what the encounter asks
	## and what the rider's own look holds.
	attention : Rider, { segment : Segment, encounter_timing : EncounterPlan.Timing } -> Attention
	attention = |rider, { segment, encounter_timing }|
		EncounterReaction.encounter_attention(segment, encounter_timing)
			.max(rider.eyes.attention())
}

## The motorcycle held at the route's end once it reaches it. The throttle
## brakes it to rest there, and this catches the last step's overrun.
stop_at_route_end : Motorcycle, Segment -> Motorcycle
stop_at_route_end = |moved, segment|
	if moved.has_reached(segment.length) {
		moved.stopped_at(Along.at(segment.length))
	} else {
		moved
	}
