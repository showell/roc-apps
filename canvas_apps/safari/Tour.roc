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
Tour :: {
	route : Route,
	instant : RideInstant,
	past_instants : List(RideInstant),
}.{

	initial : Tour
	initial = Tour.({ route: World.route, instant: RideInstant.initial, past_instants: [] })

	## The instant the ride has reached.
	instant : Tour -> RideInstant
	instant = |Tour.(tour)| tour.instant

	## The route the ride is on.
	route : Tour -> Route
	route = |Tour.(tour)| tour.route

	## How many instants are kept behind the current one: how far back the
	## tour can step.
	past_instant_count : Tour -> U64
	past_instant_count = |Tour.(tour)| tour.past_instants.len()

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
		while Tour.instant($tour).clock != goal {
			$tour =
				match tour_after_step($tour) {
					Continued(next_tour) => next_tour
					Restarted(_) => crash "Tour.at_step: the ride finishes before step ${step.to_str()}"
				}
		}
		$tour
	}

	step_back : Tour -> Tour
	step_back = |Tour.(tour)| {
		match tour.past_instants.last() {
			Ok(prev) => {
				past_instants = tour.past_instants.drop_last(1)
				Tour.({ ..tour, instant: prev, past_instants })
			}
			Err(_) => Tour.(tour)
		}
	}

	## What the camera shows at the tour's instant.
	frame_view : Tour -> FrameView
	frame_view = |Tour.(tour)| FrameView.frame_view_at(tour.route, tour.instant)
}

## `tour` a step on, with its past instants kept. The ride that has finished
## starts again with none.
tour_after_step : Tour -> [Continued(Tour), Restarted(Tour)]
tour_after_step = |Tour.(tour)|
	match RideInstant.next_or_restart(tour.route, tour.instant) {
		Continued(next_instant) => {
			past_instants = tour.past_instants.append(tour.instant)
			Continued(Tour.({ ..tour, instant: next_instant, past_instants }))
		}
		Restarted(start) => Restarted(Tour.({ ..tour, instant: start, past_instants: [] }))
	}

# A tour ridden to a step keeps every instant it passed, and none at the start.
expect {
	ridden = Tour.at_step(3)
	Tour.instant(ridden).clock == Clock.at_step(3) and Tour.past_instant_count(ridden) == 3
}
expect Tour.past_instant_count(Tour.at_step(0)) == 0

# A tour stepped back from step 5 is one step short of the start after 4 backs,
# at step 0 after 5, and still there after a sixth.
expect {
	var $tour = Tour.at_step(5)
	for _ in 0..<4 {
		$tour = Tour.step_back($tour)
	}
	after_four = Tour.instant($tour).clock
	$tour = Tour.step_back($tour)
	after_five = Tour.instant($tour).clock
	$tour = Tour.step_back($tour)
	after_six = Tour.instant($tour).clock
	after_four == Clock.at_step(1) and after_five == Clock.start and after_six == Clock.start
}
