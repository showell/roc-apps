## The rider from one step to the next: the motorcycle they ride, which knows
## where on the route it is, and where their eyes are. It is kept from one step
## to the next, one of the four things the ride remembers.
import Along
import Angle
import Animation
import Attention
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
	## `encounter_stage`: the move, the crossing onto the next segment, the stop
	## at the route's end, and then where the rider looks.
	rider_at_next_step : Rider, { route : Route, encounter_stage : Animation.Stage } -> Rider
	rider_at_next_step = |rider, { route, encounter_stage }| {
		segment = rider.motorcycle.route_place.segment_on(route)
		moved = rider.motorcycle.motorcycle_at_next_step(
			RiderMind.controls(rider.motorcycle, { segment, encounter_stage }),
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
			RouteEnds =>
				match route_end_arrival(rider.motorcycle, segment) {
					AtEnd(_) => True
					ShortOfEnd => False
				}
		}
	}

	## How strongly something holds the rider's eye on their segment of `route`,
	## with its encounter at `encounter_stage`: the stronger of what the
	## encounter asks and what the rider's own look holds.
	attention : Rider, { route : Route, encounter_stage : Animation.Stage } -> Attention
	attention = |rider, { route, encounter_stage }| {
		encounter = rider.motorcycle.route_place.segment_on(route).encounter
		EncounterReaction.encounter_attention(encounter, encounter_stage)
			.max(rider.eyes.attention())
	}

	## How far the rider's head turns from the way the motorcycle points: the
	## gaze, and a little more with the lean, as a rider's head turns into a bend.
	head_yaw : Rider -> Angle.Turn
	head_yaw = |rider| rider.eyes.gaze_yaw.plus(rider.motorcycle.lean.steer(head_turn_per_lean))
}

## How far the head turns for each radian of lean.
head_turn_per_lean : F64
head_turn_per_lean = 0.15

## The motorcycle held at the route's end once it reaches it. The throttle
## brakes it to rest there, and this catches the last step's overrun.
stop_at_route_end : Motorcycle, Segment -> Motorcycle
stop_at_route_end = |moved, segment|
	match route_end_arrival(moved, segment) {
		AtEnd(route_end) => moved.stopped_at(route_end)
		ShortOfEnd => moved
	}

## Whether `motorcycle` has reached the route's end on `segment`, the route's
## last, and where on the segment that end is.
route_end_arrival : Motorcycle, Segment -> [AtEnd(Along), ShortOfEnd]
route_end_arrival = |motorcycle, segment| {
	route_end = Along.at(segment.length)
	if motorcycle.has_reached(route_end) {
		AtEnd(route_end)
	} else {
		ShortOfEnd
	}
}

# With no lean, the head turns from the way the motorcycle points exactly as
# far as the rider looks.
expect {
	gaze_yaw = Angle.Turn.radians(0.375)
	upright = { ..Rider.initial.motorcycle, lean: Angle.Lean.radians(0.0) }
	eyes = { ..Rider.initial.eyes, gaze_yaw }
	looking = { ..Rider.initial, motorcycle: upright, eyes }
	looking.head_yaw() == gaze_yaw
}
