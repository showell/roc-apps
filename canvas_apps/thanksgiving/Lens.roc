## Lens is how the guest's eye zooms and tips through the movie: its focal
## length, the pixels a metre subtends a metre away, so a bigger one is a
## longer lens and a closer look, and its roll, the whole picture tipped
## round its middle. Like EyePath it is a shot list of moves, each easing
## from wherever the last left off, timed to the same beats, so the zooms
## land on the wink, the drumstick and the crowd. Now and then it snaps in or
## out on purpose, to throw the viewer.
import Dinner
import EyePath
import Script

Lens :: [].{

	## The focal length, and the roll in radians, clockwise.
	Setting : { focal : F64, roll : F64 }

	## The lens at `tick`.
	setting_at : I64 -> Lens.Setting
	setting_at = |tick| {
		now = Script.held_tick(tick)
		moves.fold(
			normal,
			|setting, move| {
				fraction = EyePath.move_fraction(move, now)
				{
					focal: setting.focal + (move.to.focal - setting.focal) * fraction,
					roll: setting.roll + (move.to.roll - setting.roll) * fraction,
				}
			},
		)
	}
}

Move : {
	start : I64,
	frames : I64,
	curve : [Smooth, Whip],
	to : Lens.Setting,
}

# A wide lens, so a guest at the end of the table sees its whole length.
normal : Lens.Setting
normal = { focal: 380.0, roll: 0.0 }

moves : List(Move)
moves = [
	[
		# In on the slipping pie, and out once it is caught.
		{
			start: Dinner.slip_tick - 8,
			frames: 10,
			curve: Whip,
			to: { focal: 700.0, roll: 0.0 },
		},
		{
			start: Dinner.slip_tick + 70,
			frames: 30,
			curve: Smooth,
			to: normal,
		},
		# Zoomed in as the eye backs away from the wink, in step, so the
		# dancer's head stays the size it was: the eye ends up 3.2 times as
		# far from it.
		{
			start: Script.wink_tick - 18,
			frames: 26,
			curve: Smooth,
			to: { ..normal, focal: normal.focal * 3.2 },
		},
		# Snapped out past wide and tipped over as the eye flies back, then
		# righted on the other tip and settled.
		{
			start: Script.wide_tick,
			frames: 20,
			curve: Whip,
			to: { focal: 160.0, roll: 0.25 },
		},
		{
			start: Script.wide_tick + 30,
			frames: 30,
			curve: Smooth,
			to: { focal: 260.0, roll: -0.18 },
		},
		{
			start: Script.wide_tick + 65,
			frames: 34,
			curve: Smooth,
			to: normal,
		},
	],
	# The picture jolts as each of the first three floats brakes.
	Script.float_stop_ticks.take_first(3).map(jolt_moves).join(),
	[
		# In on the last float as it brakes, then snapped out, tipped, as
		# the army steps out, and righted.
		{
			start: last_float_stop - 14,
			frames: 12,
			curve: Whip,
			to: { ..normal, focal: 700.0 },
		},
		{
			start: Script.army_tick,
			frames: 20,
			curve: Whip,
			to: { ..normal, roll: -0.2 },
		},
		{
			start: Script.army_tick + 30,
			frames: 60,
			curve: Smooth,
			to: normal,
		},
		# In on the drumstick toss, and the long lens kept for the flight to
		# the fence.
		{
			start: Script.halt_tick - 10,
			frames: 12,
			curve: Whip,
			to: { ..normal, focal: 900.0 },
		},
		{
			start: Script.peek_tick,
			frames: 90,
			curve: Whip,
			to: { focal: 760.0, roll: -0.06 },
		},
		# Snapped out to the crowd, tipping as it goes, then righted.
		{
			start: Script.flood_tick,
			frames: 40,
			curve: Whip,
			to: { focal: 190.0, roll: 0.14 },
		},
		{
			start: Script.flood_tick + 60,
			frames: 100,
			curve: Smooth,
			to: { focal: 330.0, roll: 0.0 },
		},
		# A whole barrel roll over the crowd. From here on every roll is
		# measured from once round.
		{
			start: Script.spin_tick,
			frames: 80,
			curve: Smooth,
			to: { focal: 330.0, roll: once_round },
		},
		# Tipped one way with the wave, and the other way as it comes back.
		{
			start: first_wave - 40,
			frames: 80,
			curve: Smooth,
			to: { focal: 330.0, roll: once_round + 0.12 },
		},
		{
			start: second_wave - 40,
			frames: 80,
			curve: Smooth,
			to: { focal: 330.0, roll: once_round - 0.12 },
		},
		# Snapped in for the last wink, and out for the banner, tipped and
		# righted.
		{
			start: Script.final_wink_tick - 50,
			frames: 40,
			curve: Whip,
			to: { focal: 700.0, roll: once_round },
		},
		{
			start: Script.final_wink_tick + 26,
			frames: 40,
			curve: Whip,
			to: { focal: 330.0, roll: once_round + 0.15 },
		},
		{
			start: Script.final_wink_tick + 70,
			frames: 50,
			curve: Smooth,
			to: { focal: 330.0, roll: once_round },
		},
	],
].join()

# A float braking tips the picture a little, and it rocks back.
jolt_moves : I64 -> List(Move)
jolt_moves = |stop_tick| [
	{
		start: stop_tick - 2,
		frames: 6,
		curve: Whip,
		to: { ..normal, roll: 0.08 },
	},
	{
		start: stop_tick + 4,
		frames: 14,
		curve: Smooth,
		to: normal,
	},
]

once_round : F64
once_round = F64.tau

first_wave : I64
first_wave = Script.wave_ticks.first() ?? crash "Lens: the crowd waves"

second_wave : I64
second_wave = Script.wave_ticks.last() ?? crash "Lens: the crowd waves"

last_float_stop : I64
last_float_stop = Script.float_stop_ticks.last() ?? crash "Lens: the floats have stops"

# The lens starts and ends as it is meant to: plain at the start, and
# untipped under the banner, once round from where it started.
expect Lens.setting_at(0) == normal
expect (Lens.setting_at(Script.end_tick).roll - once_round).abs() < 0.000001
