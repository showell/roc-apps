# Does the ride stay on the road? It rides the whole route from the start,
# through Tour.step_forward, until the ride finishes.
#
# Hand-written, like StepBack beside it. A step is bad when it puts the rider
# past the road's half width, when it takes the segment index backwards, or when
# it leaves the rider past its segment's end without having crossed onto the
# next. The widest the rider got from the middle, and the step the ride finishes
# on, are printed but not held: they move with every physics change, and the
# rule is what the gate checks.
#
#   roc build --opt=dev OnRoad.roc --output=<bin>; <bin>
app [main!] { game: "../game.roc", lib: "../../lib/main.roc" }

import game.Along
import game.Distance
import game.Geom
import game.Tour

# A ride still going after this many steps never finishes. The route takes
# under 10,000.
steps_cap : I64
steps_cap = 100000

# The bad steps printed in full. The count covers the rest.
bad_lines_cap : I64
bad_lines_cap = 10

# Where the ride is at `step`, for a line of the output.
place_of : I64, Tour -> Str
place_of = |step, tour| "step ${step.to_str()} on segment ${tour.instant.rider.segment_index.to_i64().to_str()}"

# What is wrong with the tour that `step` just reached, coming from segment
# `last_segment`: a line for each rule it breaks.
broken_rules : Tour, { step : I64, last_segment : I64 } -> List(Str)
broken_rules = |tour, { step, last_segment }| {
	rider = tour.instant.rider
	segment = rider.segment_index.to_i64()
	segment_end = Along.at(tour.route.segment_at(rider.segment_index).length)
	from_middle = rider.motorcycle.across.distance_from_middle()
	place = place_of(step, tour)
	off_road =
		if from_middle >= Geom.road_half_width {
			["${place}: ${from_middle.to_metres().to_str()} m from the middle, past the road's half width"]
		} else {
			[]
		}
	backwards =
		if segment < last_segment {
			["${place}: the segment went back from ${last_segment.to_str()}"]
		} else {
			[]
		}
	past_end =
		if rider.motorcycle.along > segment_end {
			["${place}: ${rider.motorcycle.along.to_metres().to_str()} m along, past the segment's end without crossing"]
		} else {
			[]
		}
	off_road.concat(backwards).concat(past_end)
}

main! = |_args| {
	var $tour = Tour.initial
	var $step = 0
	var $bad = 0
	var $out = ""
	var $widest = Distance.zero
	var $widest_place = place_of(0, Tour.initial)
	while !$tour.instant.rider.is_finished($tour.route) and $step < steps_cap {
		last_segment = $tour.instant.rider.segment_index.to_i64()
		$tour = Tour.step_forward($tour)
		$step = $step + 1
		for line in broken_rules($tour, { step: $step, last_segment }) {
			if $bad < bad_lines_cap {
				$out = $out.concat("BAD ${line}\n")
			}
			$bad = $bad + 1
		}
		from_middle = $tour.instant.rider.motorcycle.across.distance_from_middle()
		if from_middle > $widest {
			$widest = from_middle
			$widest_place = place_of($step, $tour)
		}
	}
	finished = $tour.instant.rider.is_finished($tour.route)
	if !finished {
		$bad = $bad + 1
	}
	half_width = Geom.road_half_width.to_metres().to_str()
	widest = "widest from the middle ${$widest.to_metres().to_str()} m of ${half_width} m, at ${$widest_place}"
	finish =
		if finished {
			"the ride finishes on step ${$step.to_str()}"
		} else {
			"BAD the ride has not finished after ${$step.to_str()} steps"
		}
	verdict =
		if $bad == 0 {
			"the ride stayed on the road"
		} else {
			"${$bad.to_str()} bad: the ride did not stay on the road"
		}
	echo!($out.concat("${widest}\n${finish}\n${verdict}\n"))
	Ok({})
}
