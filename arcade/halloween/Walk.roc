# Walk -- where the child is, which way they are looking, and when everything
# happens.
#
# Hand-written. **THIS IS THE ONLY MODULE THAT KNOWS WHAT TIME IT IS.** The
# house is handed how far open its door is; the witch is handed how far down
# the hall she has come; the skeletons are handed how much they are attending
# to the child. None of them counts a frame, so none of them has to be
# re-timed when the cut changes -- which is what the drawing modules in Safari
# do too: a plan says what is where, and a draw turns that into shapes.
#
# Sixty frames a second. The approach is fifteen of them, which is a child's
# pace rather than a march; the door starts to open at eight seconds and she is
# all the way down the hall at twelve; the child brakes from the moment she
# appears, stands still for half a second, turns over two, and goes back down
# the path half again as fast.
import lib.Trig

Walk :: [].{
	walk_frames : I64
	walk_frames = 900
	walk_to : F64
	walk_to = 9.0

	door_tick : I64
	door_tick = 470
	open_frames : I64
	open_frames = 130
	witch_tick : I64
	witch_tick = 600
	loom_frames : I64
	loom_frames = 120
	brake_frames : I64
	brake_frames = 100

	# Half a second of nothing at all, and then a turn that takes better than
	# two seconds: a child looking over both shoulders on the way round, not a
	# gun turret.
	spin_tick : I64
	spin_tick = 750
	spin_frames : I64
	spin_frames = 132

	# **THE WAY BACK IS HALF AGAIN AS FAST.** The approach averaged about
	# twelve millimetres a frame; this is sixteen, reached over three quarters
	# of a second.
	back_tick : I64
	back_tick = 882
	back_speed : F64
	back_speed = 0.0154
	back_ramp : I64
	back_ramp = 45

	# **THE CHILD BRAKES WHEN SHE APPEARS.** Until then the walk is the tick;
	# after it the pace falls linearly to nothing over `brake_frames`, and the
	# distance covered while it does is the area under that -- half of it.
	paced : I64 -> F64
	paced = |tick|
		if tick <= witch_tick {
			I64.to_f64(tick)
		} else {
			u = ramp(tick - witch_tick, brake_frames)
			I64.to_f64(witch_tick) + I64.to_f64(brake_frames) * (u - u * u / 2.0)
		}

	approach : I64 -> F64
	approach = |tick| {
		t = F64.min(1.0, paced(tick) / I64.to_f64(walk_frames))
		# Ease out, so the child slows up the path rather than stopping dead.
		walk_to * (1.0 - (1.0 - t) * (1.0 - t))
	}

	# As far up the path as the child ever gets.
	arrived : F64
	arrived = approach(back_tick)

	# How far back down it they have come, which stops at the pavement.
	retreated : I64 -> F64
	retreated = |tick| {
		s = tick - back_tick
		if s <= 0 {
			0.0
		} else {
			u = I64.to_f64(s)
			r = I64.to_f64(back_ramp)
			# The area under a pace that ramps up and then holds.
			d = if u < r { back_speed * u * u / (2.0 * r) } else { back_speed * (u - r / 2.0) }
			F64.min(d, arrived)
		}
	}

	# How far up the path, in metres from the pavement.
	here : I64 -> F64
	here = |tick| approach(tick) - retreated(tick)

	# Every metre of it, whichever way it was walked: what the stride counts.
	travelled : I64 -> F64
	travelled = |tick| approach(tick) + retreated(tick)

	# The turn, quick and eased at both ends.
	heading : I64 -> F64
	heading = |tick| Trig.pi * smooth(ramp(tick - spin_tick, spin_frames))

	# **A STRIDE, NOT A SHAKE.** Four bobs to the metre of nine millimetres
	# each: it is the walking that makes it, so it quickens on the way back
	# and stops dead when the child does.
	bobs_per_metre : F64
	bobs_per_metre = 4.0

	eye : I64 -> F64
	eye = |tick| 1.05 + stride(tick) * Trig.r_sin(travelled(tick) * bobs_per_metre * tau) * 0.009

	# How much walking is going on, from the walking itself.
	stride : I64 -> F64
	stride = |tick| {
		d = here(tick) - here(tick - 5)
		F64.min(1.0, (if d < 0.0 { 0.0 - d } else { d }) * 20.0)
	}

	# How far open the door is, and how far down the hall she has come.
	door_open : I64 -> F64
	door_open = |tick| ramp(tick - door_tick, open_frames)

	witch_in : I64 -> F64
	witch_in = |tick| ramp(tick - witch_tick, loom_frames)

	# **THEY SQUARE UP WHEN THE CHILD STOPS.** Off the path the skeletons
	# stand at forty-five degrees; the moment the child freezes in front of
	# the witch they all turn and face them, and they go back to the angle
	# once the child is running.
	attend : I64 -> F64
	attend = |tick| smooth(ramp(tick - (witch_tick + 60), 90)) * (1.0 - smooth(ramp(tick - (back_tick + 40), 100)))

	# How much of the way through something that starts at `tick` and takes
	# `len`, held at each end.
	ramp : I64, I64 -> F64
	ramp = |since, len|
		if since <= 0 {
			0.0
		} else if since >= len {
			1.0
		} else {
			I64.to_f64(since) / I64.to_f64(len)
		}

	smooth : F64 -> F64
	smooth = |u| u * u * (3.0 - 2.0 * u)

	tau : F64
	tau = 6.283185307179586
}
