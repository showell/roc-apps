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
import Rider
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
	step_forward = |tour| {
		finished = Rider.is_finished(tour.instant.rider, tour.route)
		# Dropping one instant per step would copy the whole list every step, so
		# half of it goes at once and the copy falls on one step in a thousand.
		# The list holds the most recent instants. It starts empty, grows to a
		# cap, and from then on is between half a cap and a cap deep, until the
		# ride finishes and starts again with the list empty.
		past_instants =
			if finished {
				[]
			} else if tour.past_instants.len() < past_instants_cap {
				tour.past_instants.append(tour.instant)
			} else {
				tour.past_instants.drop_first(past_instants_cap // 2).append(tour.instant)
			}
		{
			route: tour.route,
			instant: RideInstant.next_or_restart(tour.route, tour.instant),
			past_instants,
		}
	}

	## The tour ridden from its start to `step`, with the instants it passed
	## behind it.
	at_step : U32 -> Tour
	at_step = |step| {
		goal = Clock.start.plus(Steps.of(step))
		var $tour = Tour.initial
		while $tour.instant.clock != goal {
			$tour = Tour.step_forward($tour)
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

# How far back a step back can go: 2048 instants, about half the route.
# The newest are the ones kept.
past_instants_cap : U64
past_instants_cap = 2048

# A tour ridden to a step keeps every instant it passed, and none at the start.
expect {
	ridden = Tour.at_step(3)
	ridden.instant.clock == Clock.at_step(3) and ridden.past_instants.len() == 3
}
expect Tour.at_step(0).past_instants.is_empty()
