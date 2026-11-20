## Seatless is the drum major's musical chairs: there are twelve chairs and
## twelve marchers, and the drum major is the thirteenth. As the army breaks
## ranks it looks one way and the other for a seat, hurries over to one
## side, looks again, hurries across to the other, and finds every chair
## taken. It shrugs, droops, and then has an idea: it plants its giant
## drumstick in the lawn, bone down, sits on the meaty end as on a shooting
## stick, folds its arms, and winks at the eye. March has it until the
## army breaks ranks; this module has it after.
import Dancer
import Ease
import March
import Moves
import Script

Seatless :: [].{

	## The drum major at `tick`: March's until the army breaks ranks, then
	## looking for a seat.
	drum_major_at : I64 -> [Marching(March.DrumMajor), NotYet]
	drum_major_at = |tick| {
		now = Script.held_tick(tick)
		if now < Script.seat_tick {
			March.drum_major_at(tick)
		} else {
			Marching(seatless(now - Script.seat_tick))
		}
	}

	## How long the whole gag takes, from the army breaking ranks to the
	## wink.
	gag_ticks : I64
	gag_ticks = wink_end

	## When it hurries across for one last look, which the eye whips round to
	## see.
	last_look_tick : I64
	last_look_tick = Script.seat_tick + second_hurry

	## When it has an idea, which the eye whips in to see.
	idea_tick : I64
	idea_tick = Script.seat_tick + idea_start
}

# The gag's stretches, in ticks from the army breaking ranks.
first_hurry : I64
first_hurry = 110

look_again : I64
look_again = 150

second_hurry : I64
second_hurry = 170

shrug_start : I64
shrug_start = 230

droop_start : I64
droop_start = 260

idea_start : I64
idea_start = 300

plant_start : I64
plant_start = 315

sit_start : I64
sit_start = 335

fold_start : I64
fold_start = 365

wink_start : I64
wink_start = 385

wink_end : I64
wink_end = 409

# Where it stands across the lawn: where it halted, then over to the left,
# then across to the right, where it ends up sitting.
halted_right : F64
halted_right = March.drum_major_halt_spot.right

left_look : F64
left_look = -1.0

right_look : F64
right_look = 1.8

right_at : I64 -> F64
right_at = |since| {
	to_left = Ease.smooth(Ease.ramp(since - first_hurry, look_again - first_hurry))
	to_right = Ease.smooth(Ease.ramp(since - second_hurry, shrug_start - second_hurry))
	halted_right + (left_look - halted_right) * to_left + (right_look - left_look) * to_right
}

# The left hand on the hip and the right holding the drumstick high, as it
# marched.
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
	click = (since // 25) % 4
	match click {
		0 => -1.0
		1 => 1.0
		2 => -1.0
		_ => 1.0
	}
}

move_at : I64 -> Moves.Move
move_at = |since|
	if since < shrug_start {
		{ ..proud, head: search_head(since) }
	} else if since < droop_start {
		snapped(proud, shrug, since - shrug_start)
	} else if since < idea_start {
		snapped(shrug, { ..droop, head: 0.0 }, since - droop_start)
	} else if since < sit_start {
		snapped(droop, proud, since - idea_start)
	} else if since < fold_start {
		sitting = Ease.smooth(Ease.ramp(since - sit_start, fold_start - sit_start))
		{ ..Moves.rest, bounce: 0.5 * sitting }
	} else if since < wink_start {
		snapped({ ..Moves.rest, bounce: 0.5 }, folded, since - fold_start)
	} else if since < wink_end {
		{ ..folded, wink: 1.0 }
	} else {
		folded
	}

# A move clicked into place over a few ticks, as the dance's are.
snapped : Moves.Move, Moves.Move, I64 -> Moves.Move
snapped = |from, to, since| Moves.mixed_move({ from, to, fraction: Ease.ramp(since + 1, 4) })

seatless : I64 -> March.DrumMajor
seatless = |since| {
	right = right_at(since)
	hurrying = (right - right_at(since - 4)).abs() > 0.004
	move = move_at(since)
	hop = 0.15 * (F64.pi * Ease.ramp(since - idea_start, 12)).sin()
	pose = {
		left_upper: move.left_upper,
		left_fore: move.left_fore,
		right_upper: move.right_upper,
		right_fore: move.right_fore,
		head: move.head,
		pop: move.pop,
		turn: move.turn,
		bounce: move.bounce,
		wink: move.wink,
		antenna_sway: Ease.boing(since - idea_start) + Ease.boing(since - wink_start),
		phase: walked_at(since) * F64.tau / 0.55,
		stride: if hurrying {
			1.0
		} else {
			0.0
		},
	}
	{
		feet: { ..March.drum_major_halt_spot, right, height: hop },
		pose,
		drumstick: drumstick_at(pose, since),
		drumstick_layer: if since < plant_start {
			OverBody
		} else {
			UnderBody
		},
	}
}

# The drumstick in the hand until the idea, then swung down and planted bone
# first in the lawn under it, the meat on top, where it sits.
drumstick_at : Dancer.Pose, I64 -> { grip : { across : F64, up : F64 }, angle : F64 }
drumstick_at = |pose, since| {
	held = {
		grip: Dancer.right_hand_at(pose),
		angle: pose.right_fore,
	}
	planted = { grip: { across: 0.0, up: 0.07 }, angle: F64.pi }
	plant = Ease.smooth(Ease.ramp(since - plant_start, sit_start - plant_start))
	{
		grip: {
			across: held.grip.across + (planted.grip.across - held.grip.across) * plant,
			up: held.grip.up + (planted.grip.up - held.grip.up) * plant,
		},
		angle: held.angle + (planted.angle - held.angle) * plant,
	}
}

# How far it has hurried, for its stride: over to the left and back across.
walked_at : I64 -> F64
walked_at = |since| {
	to_left = Ease.smooth(Ease.ramp(since - first_hurry, look_again - first_hurry))
	to_right = Ease.smooth(Ease.ramp(since - second_hurry, shrug_start - second_hurry))
	(left_look - halted_right).abs() * to_left + (right_look - left_look).abs() * to_right
}

# The gag is over, wink and all, before the eye flies off to the fence.
expect Script.seat_tick + Seatless.gag_ticks < Script.peek_tick
