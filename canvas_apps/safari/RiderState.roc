## The rider from one step to the next: which segment of the route they are on,
## the motorcycle they ride, and where their eyes are. This is the one place the
## segment and the motorcycle change together.
import Along
import EncounterPlan
import Gaze
import Geom
import Motorcycle
import Rider
import RiderEyes
import Route
import Segment

## The rider at one step. `segment_index` is the segment of the route the
## motorcycle is on, which places its `along` and `across`.
RiderState := {
	segment_index : Route.SegmentIndex,
	motorcycle : Motorcycle,
	eyes : RiderEyes,
}.{

	initial : RiderState
	initial = {
		segment_index: Route.SegmentIndex.first,
		motorcycle: Motorcycle.initial,
		eyes: RiderEyes.initial,
	}

	## The rider a step on along `route`, with the encounter on their segment at
	## `encounter_timing`: the move, the crossing onto the next segment, the stop
	## at the route's end, and then where the rider looks.
	next : RiderState, { route : Route, encounter_timing : EncounterPlan.Timing } -> RiderState
	next = |state, { route, encounter_timing }| {
		seg = route.segment_at(state.segment_index)
		moved = {
			..state,
			motorcycle: state.motorcycle.motorcycle_at_next_step(
				Rider.controls(state.motorcycle, { segment: seg, encounter_timing }),
			),
		}
		resolved =
			match seg.ending {
				Bends(_) => cross_if_on_road(moved, seg)
				RouteEnds => { ..moved, motorcycle: stop_at_route_end(moved.motorcycle, seg) }
			}
		resolved_seg =
			if resolved.segment_index == state.segment_index {
				seg
			} else {
				route.segment_at(resolved.segment_index)
			}
		{
			..resolved,
			eyes: Gaze.eyes_at_next_step(
				resolved.eyes,
				{ motorcycle: resolved.motorcycle, segment: resolved_seg },
			),
		}
	}

	## Whether the rider has reached the end of the route.
	is_finished : RiderState, Route -> Bool
	is_finished = |state, route| {
		seg = route.segment_at(state.segment_index)
		match seg.ending {
			Bends(_) => False
			RouteEnds => state.motorcycle.has_reached(seg.length)
		}
	}
}

## The rider on the next segment if crossing the bend at the end of `seg` puts
## them on its road, else where they were.
cross_if_on_road : RiderState, Segment -> RiderState
cross_if_on_road = |moved, seg| {
	on_next = moved.motorcycle.motorcycle_past_bend(seg.bend_out_of())
	if on_next.across.distance_from_middle() < Geom.road_half_width {
		{ ..moved, segment_index: moved.segment_index.next(), motorcycle: on_next }
	} else {
		moved
	}
}

## The motorcycle held at the route's end once it reaches it. The throttle
## brakes it to rest there, and this catches the last step's overrun.
stop_at_route_end : Motorcycle, Segment -> Motorcycle
stop_at_route_end = |moved, seg|
	if moved.has_reached(seg.length) {
		moved.stopped_at(Along.at(seg.length))
	} else {
		moved
	}
