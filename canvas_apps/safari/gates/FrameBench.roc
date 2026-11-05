## FrameBench is a native bench for the frame: it builds the world, rides N
## steps, renders each frame, and prints the total number of shapes
## and whether the ride finished. It is for `perf` on a native --opt=speed
## build, where the wasm module has no names; the gate doesn't run it.
##
##   roc build --opt=speed FrameBench.roc --output=<bin>; <bin> 60
app [main!] {
	game: "../game.roc",
	lib: "../../lib/main.roc",
}

import game.World
import game.Safari
import game.Rider

## The ride after `steps` more frames, and the shapes counted so far.
BenchRun : { ride : Safari.Ride, shapes : U64 }

ride_frames : List(World.Segment), { bench_run : BenchRun, steps_left : I64 } -> BenchRun
ride_frames = |world, { bench_run, steps_left: steps }|
	if steps <= 0 {
		bench_run
	} else {
		frame_shapes = Safari.ride_frame(world, bench_run.ride)
		ride_frames(
			world,
			{
				bench_run: {
					ride: Safari.ride_next(world, bench_run.ride),
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
	world = World.segments
	done = ride_frames(
		world,
		{
			bench_run: { ride: Safari.ride_initial, shapes: 0 },
			steps_left: steps,
		},
	)
	finished = if (Rider.is_finished(done.ride.rider, world)) "yes" else "no"
	echo!("${done.shapes.to_str()} shapes over the frames; finished ${finished}\n")
	Ok({})
}
