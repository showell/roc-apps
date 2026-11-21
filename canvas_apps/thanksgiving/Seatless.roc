## Seatless is the drum major away from the head of its army: in the game
## of musical chairs, which it loses, and back on its drumstick after the
## army sits. In the game it struts round the chairs last in the line,
## drumstick high, freezes when the music stops, and hurries for a chair a
## moment too late. Left standing at the end of the row, it looks one way and
## the other, shrugs, droops, and then has an idea: it plants its giant
## drumstick in the lawn, bone down, sits on the meaty end as on a shooting
## stick, folds its arms, and winks at the eye. When its army marches it
## leaps up and runs to lead it, which March has; once the army breaks
## ranks for the floats' chairs, it sits on its drumstick again.
import Dancer
import Ease
import March
import Moves
import MusicalChairs
import Script

Seatless :: [].{

	## The drum major at `tick`: in the game, getting up off its drumstick,
	## March's while it leads the army, and sat on its drumstick after.
	drum_major_at : I64 -> [Marching(March.DrumMajor), NotYet]
	drum_major_at = |tick| {
		now = Script.held_tick(tick)
		if now < MusicalChairs.music_start_tick {
			NotYet
		} else if now < Script.army_tick {
			Marching(in_game(now))
		} else if now < March.run_start_tick {
			Marching(getting_up(now - Script.army_tick))
		} else if now < Script.seat_tick {
			March.drum_major_at(tick)
		} else {
			Marching(sat_again(now - Script.seat_tick))
		}
	}

	## When it has its idea, which the eye whips in to see.
	idea_tick : I64
	idea_tick = MusicalChairs.left_standing_tick + idea_start
}

# The gag's stretches, in ticks from when it is left standing.
shrug_start : I64
shrug_start = 50

droop_start : I64
droop_start = 74

idea_start : I64
idea_start = 104

plant_start : I64
plant_start = 118

wink_start : I64
wink_start = 180

wink_end : I64
wink_end = 204

# Sitting down on the drumstick, in ticks from when it starts planting it:
# the plant, the sit and the folded arms.
sit_after : I64
sit_after = 18

fold_after : I64
fold_after = 42

settled_after : I64
settled_after = 58

# The left hand on the hip and the right holding the drumstick high, as it
# marches.
proud : Moves.Move
proud = {
	..Moves.rest,
	left_upper: -0.75,
	left_fore: 0.75,
	right_upper: 2.5,
	right_fore: F64.pi,
}

# Both forearms out, palms up: what, no chair?
shrug : Moves.Move
shrug = {
	..Moves.rest,
	left_upper: -0.5,
	left_fore: -1.9,
	right_upper: 0.5,
	right_fore: 1.9,
	pop: 0.05,
}

# Arms hanging, knees sagging.
droop : Moves.Move
droop = { ..Moves.rest, bounce: 0.1 }

# Sat on the drumstick, arms folded across the chest.
folded : Moves.Move
folded = {
	..Moves.rest,
	left_upper: -0.35,
	left_fore: 1.45,
	right_upper: 0.35,
	right_fore: -1.45,
	bounce: 0.5,
}

# Where it looks while it searches: one way, the other, and back, a click at
# a time.
search_head : I64 -> F64
search_head = |since| {
	click = (since // 15) % 4
	match click {
		0 => -1.0
		1 => 1.0
		2 => -1.0
		_ => 1.0
	}
}

# From proud to sat with its arms folded, `since` ticks after it starts
# planting the drumstick.
sitting_down : I64 -> Moves.Move
sitting_down = |since|
	if since < sit_after {
		proud
	} else if since < fold_after {
		sitting = Ease.smooth(Ease.ramp(since - sit_after, fold_after - sit_after))
		{ ..Moves.rest, bounce: 0.5 * sitting }
	} else {
		snapped({ ..Moves.rest, bounce: 0.5 }, folded, since - fold_after)
	}

# The gag, `since` ticks after it is left standing.
gag_move : I64 -> Moves.Move
gag_move = |since|
	if since < shrug_start {
		{ ..proud, head: search_head(since) }
	} else if since < droop_start {
		snapped(proud, shrug, since - shrug_start)
	} else if since < idea_start {
		snapped(shrug, { ..droop, head: 0.0 }, since - droop_start)
	} else if since < plant_start {
		snapped(droop, proud, since - idea_start)
	} else if since < wink_start {
		sitting_down(since - plant_start)
	} else if since < wink_end {
		{ ..folded, wink: 1.0 }
	} else {
		folded
	}

# A move clicked into place over a few ticks, as the dance's are.
snapped : Moves.Move, Moves.Move, I64 -> Moves.Move
snapped = |from, to, since| Moves.mixed_move({ from, to, fraction: Ease.ramp(since + 1, 4) })

# The drum major standing as `move` says, walking as `stride` and `phase`
# say, its antenna swaying `sway`.
posed : Moves.Move,
{
	stride : F64,
	phase : F64,
	sway : F64,
} -> Dancer.Pose
posed = |move, { stride, phase, sway }| {
	left_upper: move.left_upper,
	left_fore: move.left_fore,
	right_upper: move.right_upper,
	right_fore: move.right_fore,
	head: move.head,
	pop: move.pop,
	turn: move.turn,
	bounce: move.bounce,
	wink: move.wink,
	antenna_sway: sway,
	phase,
	stride,
}

# In the game: strutting round the chairs, high stepping with the drumstick
# pumping, frozen when the music stops, hurrying, then the gag.
in_game : I64 -> March.DrumMajor
in_game = |now| {
	walk = MusicalChairs.drum_major_walk(now)
	since = now - MusicalChairs.left_standing_tick
	playing =
		if now < MusicalChairs.music_stop_tick {
			1.0
		} else {
			0.0
		}
	pump = 0.35 * (2.0 * walk.phase).sin() * playing
	move =
		if since < 0 {
			{ ..proud, right_fore: F64.pi + pump }
		} else {
			gag_move(since)
		}
	hop = 0.15 * (F64.pi * Ease.ramp(since - idea_start, 12)).sin()
	sway = Ease.boing(now - MusicalChairs.music_stop_tick) + Ease.boing(since - idea_start) + Ease.boing(since - wink_start)
	pose = posed(move, { stride: 2.0 * walk.stride, phase: walk.phase, sway })
	planting = since - plant_start
	{
		feet: { ..walk.feet, height: hop },
		pose,
		drumstick: drumstick_at(pose, Ease.smooth(Ease.ramp(planting, sit_after))),
		drumstick_layer: if planting < 0 {
			OverBody
		} else {
			UnderBody
		},
	}
}

# Up off the drumstick as the army comes: arms unfolded, up on its feet and
# the drumstick pulled out of the lawn, `since` ticks after the army sets
# off.
getting_up : I64 -> March.DrumMajor
getting_up = |since| {
	up = Ease.smooth(Ease.ramp(since, March.run_start_tick - Script.army_tick))
	pose = posed(
		Moves.mixed_move({ from: folded, to: proud, fraction: up }),
		{ stride: 0.0, phase: 0.0, sway: Ease.boing(since) },
	)
	{
		feet: { ..MusicalChairs.stand_spot, height: 0.2 * (F64.pi * up).sin() },
		pose,
		drumstick: drumstick_at(pose, 1.0 - up),
		drumstick_layer: if up < 0.5 {
			UnderBody
		} else {
			OverBody
		},
	}
}

# Sat on its drumstick again where it halted, `since` ticks after the army
# breaks ranks.
sat_again : I64 -> March.DrumMajor
sat_again = |since| {
	pose = posed(
		sitting_down(since),
		{ stride: 0.0, phase: 0.0, sway: Ease.boing(since - settled_after) },
	)
	{
		feet: March.drum_major_halt_spot,
		pose,
		drumstick: drumstick_at(pose, Ease.smooth(Ease.ramp(since, sit_after))),
		drumstick_layer: UnderBody,
	}
}

# The drumstick in the hand, or `plant` of the way to planted bone first in
# the lawn under the drum major, the meat on top, where it sits.
drumstick_at : Dancer.Pose, F64 -> { grip : { across : F64, up : F64 }, angle : F64 }
drumstick_at = |pose, plant| {
	held = {
		grip: Dancer.right_hand_at(pose),
		angle: pose.right_fore,
	}
	planted = { grip: { across: 0.0, up: 0.07 }, angle: F64.pi }
	{
		grip: {
			across: held.grip.across + (planted.grip.across - held.grip.across) * plant,
			up: held.grip.up + (planted.grip.up - held.grip.up) * plant,
		},
		angle: held.angle + (planted.angle - held.angle) * plant,
	}
}
