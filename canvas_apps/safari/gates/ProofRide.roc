## ProofRide takes a proof tool through the ride in one pass: it stops at each
## depth the tool holds on its way to the deepest, so no depth replays the
## steps before it.

import game.Tour

ProofRide :: [].{

	## The tour `steps` steps past `tour`.
	ride_on : Tour, I64 -> Tour
	ride_on = |tour, steps| if steps <= 0 {
		tour
	} else {
		ride_on(Tour.advance(tour), steps - 1)
	}

	## The number a tool was given on its command line.
	depth_of : Str -> I64
	depth_of = |text| I64.from_str(text) ?? crash "ProofRide: a depth must be a whole number"

	## What `held_line` says at each of `depths`, which rise, a line each.
	held_lines : List(Str), (I64, Tour -> Str) -> Str
	held_lines = |depths, held_line| {
		var $tour = Tour.initial
		var $at = 0
		var $out = ""
		for text in depths {
			depth = depth_of(text)
			if depth < $at {
				crash "ProofRide: the depths must rise"
			}
			$tour = ride_on($tour, depth - $at)
			$at = depth
			$out = Str.concat($out, "${held_line(depth, $tour)}\n")
		}
		$out
	}
}
