## Tour is the whole ride, for any platform that draws it. It keeps the
## current instant of the ride and the instants behind it for stepping back, and
## it gives the FrameView of the current instant: what a painter needs for a
## frame. SafariApp turns it into a canvas app, with the keys, the pause, and
## the frame leaned by the roll.
import Clock
import FrameView
import Route
import World
import RideInstant
import Steps

## The route, the instant the ride has reached, and the instants before it.
Tour := {
	route : Route,
	instant : RideInstant,
	past_instants : List(RideInstant),
}.{

	initial : Tour
	initial = { route: World.route, instant: RideInstant.initial, past_instants: [] }

	step_forward : Tour -> Tour
	step_forward = |tour|
		match tour_after_step(tour) {
			Continued(next_tour) | Restarted(next_tour) => next_tour
		}

	## The tour ridden from its start to `step`, with the instants it passed
	## behind it. The ride must not finish before `step`.
	at_step : U32 -> Tour
	at_step = |step| {
		goal = Clock.start.plus(Steps.of(step))
		var $tour = Tour.initial
		while $tour.instant.clock != goal {
			$tour =
				match tour_after_step($tour) {
					Continued(next_tour) => next_tour
					Restarted(_) => crash "Tour.at_step: the ride finishes before step ${step.to_str()}"
				}
		}
		$tour
	}

	## How many past instants a tour keeps for stepping back: about half the
	## route. The newest are the ones kept.
	steps_kept_back : Steps
	steps_kept_back = Steps.of(2048)

	step_back : Tour -> Tour
	step_back = |tour| {
		match tour.past_instants.last() {
			Ok(prev) => {
				route: tour.route,
				instant: prev,
				past_instants: tour.past_instants.drop_last(1),
			}
			Err(_) => tour
		}
	}

	## What the camera shows at the tour's instant.
	frame_view : Tour -> FrameView
	frame_view = |tour| FrameView.frame_view_at(tour.route, tour.instant)
}

## `tour` a step on, with its past instants kept. The ride that has finished
## starts again with none.
tour_after_step : Tour -> [Continued(Tour), Restarted(Tour)]
tour_after_step = |tour|
	match RideInstant.next_or_restart(tour.route, tour.instant) {
		Continued(next_instant) =>
			Continued({
				route: tour.route,
				instant: next_instant,
				past_instants: past_instants_after(tour),
			})
		Restarted(start) => Restarted({ route: tour.route, instant: start, past_instants: [] })
	}

## `tour`'s past instants with its current one added. Dropping one instant per
## step would copy the whole list every step, so half of it goes at once and the
## copy falls on one step in a thousand. The list starts empty, grows to a cap,
## and from then on is between half a cap and a cap deep.
past_instants_after : Tour -> List(RideInstant)
past_instants_after = |tour| {
	cap = Tour.steps_kept_back.to_u32().to_u64()
	if tour.past_instants.len() < cap {
		tour.past_instants.append(tour.instant)
	} else {
		tour.past_instants.drop_first(cap // 2).append(tour.instant)
	}
}

# A tour ridden to a step keeps every instant it passed, and none at the start.
expect {
	ridden = Tour.at_step(3)
	ridden.instant.clock == Clock.at_step(3) and ridden.past_instants.len() == 3
}
expect Tour.at_step(0).past_instants.is_empty()
