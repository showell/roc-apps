## FrameBench is a native bench for the frame: it builds the world, rides N
## steps, renders each frame, and prints the total number of draw commands
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
import game.Blit
import game.Rider

## The ride after `steps` more frames, and the draw commands counted so far.
BenchRun : { ride : Safari.Ride, commands : U64 }

ride_frames : List(World.Segment), BenchRun, I64 -> BenchRun
ride_frames = |world, bench_run, steps|
	if steps <= 0 {
		bench_run
	} else {
		cmds = Blit.blit_expand(Safari.ride_frame(world, bench_run.ride))
		ride_frames(
			world,
			{
				ride: Safari.ride_next(world, bench_run.ride),
				commands: bench_run.commands + List.len(cmds),
			},
			steps - 1,
		)
	}

main! = |args| {
	steps = I64.from_str(List.get(args, 0) ?? "60") ?? 60
	world = World.segments
	done = ride_frames(world, { ride: Safari.ride_initial, commands: 0 }, steps)
	finished = if (Rider.is_finished(done.ride.rider, world)) "yes" else "no"
	echo!("${done.commands.to_str()} commands over the frames; finished ${finished}\n")
	Ok({})
}
