## Tour is the whole ride, for any platform that draws it. It keeps the
## current instant of the ride and every instant behind it, back to the ride's
## start, so stepping back can reach step 0. The whole ride's instants come to
## under a megabyte. A restart clears them. SafariApp turns it into a canvas
## app, with the keys, the pause, and the frame leaned by the roll.
import Clock
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

	## The tour a step on. A ride that has finished starts again.
	step_forward : Tour -> Tour
	step_forward = |tour|
		match tour_after_step(tour) {
			Continued(next_tour) | Restarted(next_tour) => next_tour
		}

	## The tour `length` steps on.
	steps_forward : Tour, Steps -> Tour
	steps_forward = |tour, length| {
		var $tour = tour
		for _ in 0..<length.to_u32() {
			$tour = Tour.step_forward($tour)
		}
		$tour
	}

	## The tour `length` steps back, or at the ride's start if that is
	## nearer.
	steps_back : Tour, Steps -> Tour
	steps_back = |tour, length| {
		var $tour = tour
		for _ in 0..<length.to_u32() {
			$tour = Tour.step_back($tour)
		}
		$tour
	}

	## The tour ridden from its start to `goal`, with the instants it passed
	## behind it. The ride must not finish before `goal`.
	at_step : Clock -> Tour
	at_step = |goal| {
		var $tour = Tour.initial
		while Tour.instant($tour).clock != goal {
			$tour =
				match tour_after_step($tour) {
					Continued(next_tour) => next_tour
					Restarted(_) => crash "Tour.at_step: the ride finishes before step ${goal.to_str()}"
				}
		}
		$tour
	}

	## The tour a step back. At the ride's start there is nothing behind it,
	## so it stays there.
	step_back : Tour -> Tour
	step_back = |Tour.(tour)| {
		match tour.past_instants.last() {
			Ok(previous_instant) => {
				past_instants = tour.past_instants.drop_last(1)
				Tour.({ ..tour, instant: previous_instant, past_instants })
			}
			Err(ListWasEmpty) => Tour.(tour)
		}
	}

	## The tour stepped on until the rider is on another of the route's
	## segments, which are its scenes. Every ride finishes and starts again on
	## the first segment, so this ends: on the next segment, or on the first
	## after the last. A route of one segment would never leave it, so that
	## crashes.
	at_next_segment : Tour -> Tour
	at_next_segment = |tour| {
		from = rider_segment_index(tour)
		var $tour = tour
		while rider_segment_index($tour) == from {
			$tour =
				match tour_after_step($tour) {
					Continued(next_tour) => next_tour
					Restarted(next_tour) =>
						if rider_segment_index(next_tour) == from {
							crash "Tour.at_next_segment: the ride started again on the segment it set out from, so the route has only one"
						} else {
							next_tour
						}
				}
		}
		$tour
	}
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

## The index of the segment the rider is on.
rider_segment_index : Tour -> Route.SegmentIndex
rider_segment_index = |Tour.(tour)| tour.instant.rider_segment_index()

# The next segment from the start is the second, reached on the step that
# leaves the first.
expect {
	reached = Tour.at_next_segment(Tour.initial)
	rider_segment_index(reached) == Route.SegmentIndex.number(1)
		and rider_segment_index(Tour.step_back(reached)) == Route.SegmentIndex.first
}

# A tour ridden to a step keeps every instant it passed, and none at the start.
expect {
	ridden = Tour.at_step(Clock.at_step(3))
	Tour.instant(ridden).clock == Clock.at_step(3) and Tour.past_instant_count(ridden) == 3
}
expect Tour.past_instant_count(Tour.at_step(Clock.start)) == 0

# Stepping forward a number of steps lands where riding to that step does.
expect {
	at_two = Tour.at_step(Clock.at_step(2))
	Tour.instant(Tour.steps_forward(at_two, Steps.of(3))).clock == Clock.at_step(5)
}

# A tour stepped back from step 5 is one step short of the start after 4 backs,
# at step 0 after 5, and still there after a sixth.
expect {
	var $tour = Tour.steps_back(Tour.at_step(Clock.at_step(5)), Steps.of(4))
	after_four = Tour.instant($tour).clock
	$tour = Tour.step_back($tour)
	after_five = Tour.instant($tour).clock
	$tour = Tour.step_back($tour)
	after_six = Tour.instant($tour).clock
	after_four == Clock.at_step(1) and after_five == Clock.start and after_six == Clock.start
}
