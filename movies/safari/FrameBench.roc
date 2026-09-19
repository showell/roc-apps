# A native bench for the frame: build the world, ride N steps, render each
# frame, print the command total. Hand-written; for `perf` on a native
# --opt=speed build, where the wasm module has no names.
#
#   roc build --opt=speed FrameBench.roc --output=<bin>; <bin> 60
import World
import Safari
import Blit
import Rider

run : List(World.Segment), Safari.Ride, I64, U64 -> U64
run = |world, ride, n, total|
	if n <= 0 { total } else {
		cmds = Blit.blit_expand(Safari.ride_frame(world, ride), 0)
		run(world, Safari.ride_next(world, ride), n - 1, total + List.len(cmds))
	}

main! = |args| {
	n = I64.from_str(List.get(args, 0) ?? "60") ?? 60
	world = World.build_world
	total = run(world, Safari.ride_initial, n, 0)
	echo!(Str.concat(Str.concat(U64.to_str(total), " commands over the frames; finished "), if Rider.is_finished(Safari.ride_initial.rider, world) { "yes\n" } else { "no\n" }))
	Ok({})
}
