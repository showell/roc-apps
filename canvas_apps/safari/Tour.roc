## Tour is the whole ride, for any platform that draws it. It keeps the
## current instant of the ride and every instant behind it, back to the ride's
## start, so stepping back can reach step 0. The whole ride's instants come to
## under a megabyte. A restart clears them. It also
## gives the FrameView of the current instant: what a painter needs for a
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
				past_instants: tour.past_instants.append(tour.instant),
			})
		Restarted(start) => Restarted({ route: tour.route, instant: start, past_instants: [] })
	}

# A tour ridden to a step keeps every instant it passed, and none at the start.
expect {
	ridden = Tour.at_step(3)
	ridden.instant.clock == Clock.at_step(3) and ridden.past_instants.len() == 3
}
expect Tour.at_step(0).past_instants.is_empty()

# A tour stepped back from step 5 is one step short of the start after 4 backs,
# at step 0 after 5, and still there after a sixth.
expect {
	var $tour = Tour.at_step(5)
	for _ in 0..<4 {
		$tour = Tour.step_back($tour)
	}
	after_four = $tour.instant.clock
	$tour = Tour.step_back($tour)
	after_five = $tour.instant.clock
	$tour = Tour.step_back($tour)
	after_six = $tour.instant.clock
	after_four == Clock.at_step(1) and after_five == Clock.start and after_six == Clock.start
}
