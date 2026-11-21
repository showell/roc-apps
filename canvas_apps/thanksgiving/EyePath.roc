## EyePath is where the guest's eye goes through the movie and which way it
## faces: a list of moves, each easing the eye from wherever the last one
## left it, either by a distance or to a spot. Each is named for the shot it
## ends on, so the path reads as a shot list. Lens says what the eye zooms
## to on the way.
import Family
import Ease
import MusicalChairs
import Script
import Seatless

EyePath :: [].{

	## Where the eye is, in the backyard's metres, and its heading, in
	## radians to the right of straight down the table.
	Spot : {
		right : F64,
		forward : F64,
		height : F64,
		heading : F64,
	}

	## Where the eye is at `tick`.
	eye_spot : I64 -> EyePath.Spot
	eye_spot = |tick| {
		now = Script.held_tick(tick)
		moves.fold(
			seated,
			|spot, move| moved_spot(spot, { goes: move.goes, fraction: move_fraction(move, now) }),
		)
	}

	## How far through a camera move it is at `now`: smoothed at both ends,
	## or whipped, fast off the mark and settling.
	move_fraction : {
		start : I64,
		frames : I64,
		curve : [Smooth, Whip],
		..,
	},
	I64 -> F64
	move_fraction = |{ start, frames, curve, .. }, now| {
		progress = Ease.ramp(now - start, frames)
		match curve {
			Smooth => Ease.smooth(progress)
			Whip => Ease.whip(progress)
		}
	}
}

Move : {
	start : I64,
	frames : I64,
	curve : [Smooth, Whip],
	goes : Going,
}

# A move goes by a distance, or to a spot.
Going : [By(EyePath.Spot), To(EyePath.Spot)]

# The guest's own seat, at the near end of the table.
seated : EyePath.Spot
seated = {
	right: -0.4,
	forward: 0.0,
	height: 1.15,
	heading: 0.0,
}

moves : List(Move)
moves = [
	# Over to the side of the table and down a little, to watch the tall
	# robot pull its chair out and sit, and back to the seat after.
	{
		start: Script.first_sit_tick - 80,
		frames: 50,
		curve: Smooth,
		goes: To(sit_watch),
	},
	{
		start: Script.first_sit_tick + 120,
		frames: 40,
		curve: Smooth,
		goes: To(seated),
	},
	# Whipped aside and down onto the tiny robot's pie as it slips, past the
	# table's corner, and back
	# once it is caught.
	{
		start: Family.slip_tick - 8,
		frames: 10,
		curve: Whip,
		goes: To({ ..seated, right: -0.75, height: 0.95 }),
	},
	{
		start: Family.slip_tick + 70,
		frames: 30,
		curve: Smooth,
		goes: To(seated),
	},
	# Eased back and up until the whole table is in view.
	{
		start: Script.pull_tick,
		frames: 150,
		curve: Smooth,
		goes: By({
			right: 0.4,
			forward: -1.8,
			height: 0.4,
			heading: 0.0,
		}),
	},
	# Snapped close on the dancer, its head and arms filling the screen.
	{
		start: Script.close_up_tick,
		frames: 30,
		curve: Whip,
		goes: To(close_up),
	},
	# Backed away as the dancer winks, while the lens zooms in to keep its
	# head the same size, so the yard behind stretches away.
	{
		start: Script.wink_tick - 18,
		frames: 26,
		curve: Smooth,
		goes: To({ ..close_up, forward: close_up.forward - 2.75 }),
	},
	# Far back and high, over the empty lawn where the floats will stand.
	{
		start: Script.wide_tick,
		frames: Script.parade_tick - Script.wide_tick,
		curve: Smooth,
		goes: To(wide),
	},
	# Whipped round and down onto the last float as it brakes.
	{
		start: last_float_stop - 14,
		frames: 12,
		curve: Whip,
		goes: To({ ..wide, height: 2.4, heading: 0.4 }),
	},
	# Whip-panned round and down to the lawn, looking left across it from
	# the aisle at the musical chairs, with nothing else going on behind.
	{
		start: Script.chairs_tick,
		frames: 24,
		curve: Whip,
		goes: To(chairs_watch),
	},
	# Whipped in close on the drum major as it has its idea, and kept there
	# for the sit and the wink.
	{
		start: Seatless.idea_tick - 5,
		frames: 15,
		curve: Whip,
		goes: To({
			..chairs_watch,
			right: MusicalChairs.stand_spot.right + 4.0,
			forward: MusicalChairs.stand_spot.forward - 0.6,
		}),
	},
	# Whipped up and round to look up the aisle as the drum major leaps up
	# and runs to the head of the army coming out from under the eye, then
	# up and back as the army marches.
	{
		start: Script.army_tick,
		frames: 24,
		curve: Whip,
		goes: To(march_start),
	},
	{
		start: Script.army_tick + 24,
		frames: Script.march_frames - 24,
		curve: Smooth,
		goes: To(army_watch),
	},
	# Dropped to the drum major's height for the drumstick toss.
	{
		start: Script.halt_tick - 10,
		frames: 12,
		curve: Whip,
		goes: To({ ..army_watch, height: 2.4 }),
	},
	# Round and down toward the near left float, to watch the army take its
	# seats.
	{
		start: Script.seat_tick + 40,
		frames: 90,
		curve: Smooth,
		goes: To({
			right: -1.0,
			forward: -24.0,
			height: 2.0,
			heading: -0.16,
		}),
	},
	# Flown down the aisle between the floats, toward a noise at the fence.
	{
		start: Script.peek_tick,
		frames: 90,
		curve: Whip,
		goes: To(fence_watch),
	},
	# Snapped far back and high to take in the crowd as it pours in.
	{
		start: Script.flood_tick,
		frames: 60,
		curve: Whip,
		goes: To(crowd_watch),
	},
	# Down among the crowd, panned with the wave one way and back the other.
	{
		start: first_wave - 40,
		frames: 80,
		curve: Smooth,
		goes: To(wave_watch(0.18)),
	},
	{
		start: second_wave - 40,
		frames: 80,
		curve: Smooth,
		goes: To(wave_watch(-0.12)),
	},
	# All the way back in to the first dancer, for one more wink.
	{
		start: Script.final_wink_tick - 50,
		frames: 40,
		curve: Whip,
		goes: To({
			right: 0.6,
			forward: -1.0,
			height: 1.75,
			heading: 0.26,
		}),
	},
	# And snapped all the way out for the banner.
	{
		start: Script.final_wink_tick + 26,
		frames: 40,
		curve: Whip,
		goes: To({
			..crowd_watch,
			forward: -46.0,
			height: 8.0,
			heading: 0.0,
		}),
	},
]

sit_watch : EyePath.Spot
sit_watch = {
	right: -0.9,
	forward: 0.0,
	height: 1.05,
	heading: 0.0,
}

close_up : EyePath.Spot
close_up = {
	right: 1.25,
	forward: 0.15,
	height: 1.75,
	heading: 0.0,
}

wide : EyePath.Spot
wide = {
	right: 0.4,
	forward: -25.5,
	height: 3.4,
	heading: 0.0,
}

# In the aisle beside the musical chairs, eye high to a seated robot,
# looking across the lawn at them, the boombox at one edge of the screen
# and the drum major's spot at the other.
chairs_watch : EyePath.Spot
chairs_watch = {
	right: 1.0,
	forward: -23.7,
	height: 1.1,
	heading: -0.5 * F64.pi - 0.075,
}

# Over where the army comes out, turned a little toward where the drum
# major gets up.
march_start : EyePath.Spot
march_start = {
	right: 0.4,
	forward: -27.5,
	height: 3.6,
	heading: -0.25,
}

army_watch : EyePath.Spot
army_watch = { ..wide, forward: -30.0, height: 4.2 }

fence_watch : EyePath.Spot
fence_watch = {
	right: 0.0,
	forward: -6.0,
	height: 2.8,
	heading: 0.0,
}

crowd_watch : EyePath.Spot
crowd_watch = {
	right: 0.4,
	forward: -40.0,
	height: 6.5,
	heading: -0.12,
}

wave_watch : F64 -> EyePath.Spot
wave_watch = |heading| {
	..crowd_watch,
	forward: -36.0,
	height: 4.5,
	heading,
}

last_float_stop : I64
last_float_stop = Script.float_stop_ticks.last() ?? crash "EyePath: the floats have stops"

first_wave : I64
first_wave = Script.wave_ticks.first() ?? crash "EyePath: the crowd waves"

second_wave : I64
second_wave = Script.wave_ticks.last() ?? crash "EyePath: the crowd waves"

moved_spot : EyePath.Spot, { goes : Going, fraction : F64 } -> EyePath.Spot
moved_spot = |from, { goes, fraction }|
	match goes {
		By(distance) => {
			right: from.right + distance.right * fraction,
			forward: from.forward + distance.forward * fraction,
			height: from.height + distance.height * fraction,
			heading: from.heading + distance.heading * fraction,
		}
		To(to) => {
			right: from.right + (to.right - from.right) * fraction,
			forward: from.forward + (to.forward - from.forward) * fraction,
			height: from.height + (to.height - from.height) * fraction,
			heading: from.heading + (to.heading - from.heading) * fraction,
		}
	}

# The eye starts in the guest's seat and is at the wide shot as the parade
# sets off.
expect EyePath.eye_spot(0) == seated
expect (EyePath.eye_spot(Script.parade_tick).forward - wide.forward).abs() < 0.000001
