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
	# In on the slipping pie, and out once it is caught.
	{
		start: Dinner.slip_tick - 10,
		frames: 16,
		curve: Whip,
		to: { focal: 700.0, roll: 0.0 },
	},
	{
		start: Dinner.slip_tick + 72,
		frames: 40,
		curve: Smooth,
		to: normal,
	},
	# Zoomed in as the eye backs away from the wink, in step, so the
	# dancer's head stays the size it was: the eye ends up 3.2 times as far
	# from it.
	{
		start: Script.wink_tick - 24,
		frames: 40,
		curve: Smooth,
		to: { ..normal, focal: normal.focal * 3.2 },
	},
	# Snapped out past wide and tipped over as the eye flies back, then
	# righted on the other tip and settled.
	{
		start: Script.wide_tick,
		frames: 30,
		curve: Whip,
		to: { focal: 160.0, roll: 0.22 },
	},
	{
		start: Script.wide_tick + 40,
		frames: 60,
		curve: Smooth,
		to: { focal: 260.0, roll: -0.15 },
	},
	{
		start: Script.wide_tick + 100,
		frames: 80,
		curve: Smooth,
		to: normal,
	},
	# In on the last float as it brakes, and out.
	{
		start: last_float_stop - 30,
		frames: 24,
		curve: Whip,
		to: { ..normal, focal: 700.0 },
	},
	{
		start: last_float_stop + 70,
		frames: 60,
		curve: Smooth,
		to: normal,
	},
	# In on the drumstick toss, and the long lens kept for the flight to
	# the fence.
	{
		start: Script.halt_tick - 12,
		frames: 18,
		curve: Whip,
		to: { ..normal, focal: 900.0 },
	},
	{
		start: Script.peek_tick,
		frames: 150,
		curve: Smooth,
		to: { focal: 760.0, roll: -0.06 },
	},
	# Snapped out to the crowd, tipping as it goes, then righted.
	{
		start: Script.flood_tick,
		frames: 60,
		curve: Whip,
		to: { focal: 190.0, roll: 0.14 },
	},
	{
		start: Script.flood_tick + 120,
		frames: 200,
		curve: Smooth,
		to: { focal: 330.0, roll: 0.0 },
	},
	# In for the last wink, and out for the banner.
	{
		start: Script.final_wink_tick - 75,
		frames: 65,
		curve: Smooth,
		to: { ..normal, focal: 700.0 },
	},
	{
		start: Script.final_wink_tick + 30,
		frames: 70,
		curve: Whip,
		to: { focal: 330.0, roll: 0.0 },
	},
]

last_float_stop : I64
last_float_stop = Script.float_stop_ticks.last() ?? crash "Lens: the floats have stops"

# The lens starts and ends as it is meant to: plain at the start, and
# untipped under the banner.
expect Lens.setting_at(0) == normal
expect Lens.setting_at(Script.end_tick).roll == 0.0
