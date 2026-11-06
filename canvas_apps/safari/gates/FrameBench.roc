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

## The instant after `steps` more frames, and the shapes counted so far.
BenchRun : { instant : RideInstant, shapes : U64 }

ride_frames : List(World.Segment), { bench_run : BenchRun, steps_left : I64 } -> BenchRun
ride_frames = |route, { bench_run, steps_left: steps }|
	if steps <= 0 {
		bench_run
	} else {
		frame_shapes = RideInstant.shapes(route, bench_run.instant)
		ride_frames(
			route,
			{
				bench_run: {
					instant: RideInstant.next_or_restart(route, bench_run.instant),
					shapes: bench_run.shapes + List.len(frame_shapes),
				},
				steps_left: steps - 1,
			},
		)
	}

main! = |args| {
	# With no argument, the run takes its usual number of steps.
	steps =
		match args.get(0) {
			Ok(text) => I64.from_str(text) ?? crash "FrameBench: steps must be a whole number"
			Err(OutOfBounds) => 60
		}
	route = World.segments
	done = ride_frames(
		route,
		{ bench_run: { instant: RideInstant.initial, shapes: 0 }, steps_left: steps },
	)
	finished = if Rider.is_finished(done.instant.rider, route) {
		"yes"
	} else {
		"no"
	}
	echo!("${done.shapes.to_str()} shapes over the frames; finished ${finished}\n")
	Ok({})
}
