## FrameBench is a native bench for the frame: it builds the world, rides N
## steps, renders each frame, and prints the total number of shapes
## and whether the ride finished. It is for `perf` on a native --opt=speed
## build, where the wasm module has no names; the gate doesn't run it.
##
##   roc build --opt=speed FrameBench.roc --output=<bin>; <bin> 60
app [main!] { game: "../game.roc", lib: "../../lib/main.roc" }

import game.World
import game.RideInstant
import game.Rider

main! = |args| {
	# With no argument, the run takes its usual number of steps.
	steps =
		match args.get(0) {
			Ok(text) => I64.from_str(text) ?? crash "FrameBench: steps must be a whole number"
			Err(OutOfBounds) => 60
		}
	route_segments = World.segments
	var $instant = RideInstant.initial
	var $shapes = 0
	for _ in 0..<steps {
		$shapes = $shapes + RideInstant.shapes(route_segments, $instant).len()
		$instant = RideInstant.next_or_restart(route_segments, $instant)
	}
	finished = if Rider.is_finished($instant.rider, route_segments) {
		"yes"
	} else {
		"no"
	}
	echo!("${$shapes.to_str()} shapes over the frames; finished ${finished}\n")
	Ok({})
}
