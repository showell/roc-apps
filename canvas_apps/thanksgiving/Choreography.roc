## Choreography is the robot dance written out: for each section, the moves
## in order and how many ticks each is held. Routine strings the sections
## together and says which move is danced at a tick; Script times the eye,
## the floats, the army and the crowd to the beats named here.
import Moves

Choreography :: [].{

	## One move and how many ticks it lasts.
	Step : { move : Moves.Move, frames : I64 }

	## The right arm comes up and its forearm waves down in clicks, as the
	## eye moves in.
	opening_steps : List(Choreography.Step)
	opening_steps = [
		{ move: Moves.right_arm(Moves.quarter), frames: 14 },
		{ move: Moves.right_arm(F64.pi), frames: 18 },
		{ move: Moves.right_arm(2.62), frames: 9 },
		{ move: Moves.right_arm(2.09), frames: 9 },
		{ move: Moves.right_arm(1.57), frames: 9 },
		{ move: Moves.right_arm(1.05), frames: 9 },
		{ move: Moves.right_arm(0.52), frames: 12 },
	]

	## In close: the head clicks round to one side and back to the eye, winks
	## at it, and clicks round to the other side.
	hello_steps : List(Choreography.Step)
	hello_steps = List.concat(glance_steps, wink_steps)

	## The ticks from the start of the hello to the wink.
	wink_offset : I64
	wink_offset = ticks_of(glance_steps)

	## While the eye backs away: bounces with the arms out, a turn to the
	## side and back, and the forearms hinging down.
	travel_steps : List(Choreography.Step)
	travel_steps = [
		{ move: { ..Moves.arms_out, bounce: 0.05 }, frames: 7 },
		{ move: Moves.arms_out, frames: 7 },
		{ move: { ..Moves.arms_out, bounce: 0.05 }, frames: 7 },
		{ move: Moves.arms_out, frames: 7 },
		{ move: { ..Moves.arms_out, bounce: 0.05 }, frames: 7 },
		{ move: Moves.arms_out, frames: 9 },
		{ move: { ..Moves.rest, turn: 0.88 }, frames: 10 },
		{ move: { ..Moves.rest, turn: 0.75 }, frames: 10 },
		{ move: { ..Moves.rest, turn: 0.62 }, frames: 10 },
		{ move: { ..Moves.rest, turn: 0.5 }, frames: 16 },
		{ move: { ..Moves.rest, turn: 0.62 }, frames: 10 },
		{ move: { ..Moves.rest, turn: 0.75 }, frames: 10 },
		{ move: { ..Moves.rest, turn: 0.88 }, frames: 10 },
		{ move: Moves.rest, frames: 12 },
		{ move: { ..Moves.goalpost, left_fore: -2.09, right_fore: 2.09 }, frames: 9 },
		{ move: { ..Moves.goalpost, left_fore: -1.57, right_fore: 1.57 }, frames: 9 },
		{ move: { ..Moves.goalpost, left_fore: -1.05, right_fore: 1.05 }, frames: 9 },
		{
			move: {
				..Moves.goalpost,
				left_fore: -1.05,
				right_fore: 1.05,
				head: 1.0,
			},
			frames: 10,
		},
		{
			move: {
				..Moves.goalpost,
				left_fore: -1.05,
				right_fore: 1.05,
				head: -1.0,
			},
			frames: 10,
		},
		{ move: Moves.goalpost, frames: 8 },
	]

	## While the floats roll in: a groove in the Moves.goalpost, and a shoulder pop,
	## left and right in turn, as each float brakes to a stop.
	parade_steps : List(Choreography.Step)
	parade_steps = [
		[{ move: Moves.goalpost, frames: parade_breath }],
		groove_steps(Moves.goalpost, first_roll_frames),
		[0.07, -0.07, 0.07, -0.07]
			.map(
				|lift| List.concat(
					pop_steps(lift),
					groove_steps(Moves.goalpost, pop_gap - pop_frames),
				),
			)
			.join(),
	].join()

	## The ticks from the start of the parade to each float's stop, one a
	## shoulder pop.
	pop_offsets : List(I64)
	pop_offsets = [0, 1, 2, 3].map(|float| parade_breath + first_roll_frames + float * pop_gap)

	## While the army marches in: a bounce on every step of its drum, arms
	## out, the head clicking toward the marchers every few steps.
	strut_steps : List(Choreography.Step)
	strut_steps =
		[0.0, 0.0, -1.0, 0.0, 0.0, 1.0, 0.0, 0.0, -1.0, 0.0, 0.0, 1.0, 0.0]
			.map(|head| beat_steps({ ..Moves.arms_out, head }))
			.join()
			.append({ move: Moves.arms_out, frames: 21 })

	## A noise behind the fence: a hand up to the brow, and the head clicking
	## from side to side, looking for it.
	peek_steps : List(Choreography.Step)
	peek_steps = {
		brow = { ..Moves.rest, right_upper: 2.5, right_fore: -1.2 }
		[-1.0, 1.0, -1.0, 1.0, -0.5, 0.5]
			.map(|head| [{ move: { ..brow, head }, frames: 40 }, { move: brow, frames: 40 }])
			.join()
	}

	## While the crowd floods in: arms out, bouncing on the beat, the head
	## clicking one way and the other.
	flood_steps : List(Choreography.Step)
	flood_steps = {
		round =
			[0.0, 1.0, 0.0, -1.0]
				.map(
					|head| List.concat(
						beat_steps({ ..Moves.arms_out, head }),
						beat_steps(Moves.arms_out),
					),
				)
				.join()
		List.concat(repeated_steps(round, 3), repeated_steps(beat_steps(Moves.arms_out), 4))
	}

	## While the crowd does the wave: a groove, and the arms thrown up each
	## time the wave goes by.
	wave_steps : List(Choreography.Step)
	wave_steps = [
		groove_steps(Moves.goalpost, wave_gap),
		[{ move: Moves.arms_up, frames: arms_up_frames }],
		groove_steps(Moves.goalpost, wave_gap),
		[{ move: Moves.arms_up, frames: arms_up_frames }],
		groove_steps(Moves.goalpost, wave_gap),
	].join()

	## The ticks from the start of the wave to each time the arms go up.
	wave_offsets : List(I64)
	wave_offsets = [wave_gap, 2 * wave_gap + arms_up_frames]

	## The final pose, held, with one last wink at the eye.
	finale_steps : List(Choreography.Step)
	finale_steps = [
		{ move: Moves.final_pose, frames: final_wink_offset },
		{ move: { ..Moves.final_pose, wink: 1.0 }, frames: 24 },
		{ move: Moves.final_pose, frames: 336 },
	]

	## The ticks from the start of the finale to its wink.
	final_wink_offset : I64
	final_wink_offset = 240

	## How many ticks a list of steps lasts.
	ticks_of : List(Choreography.Step) -> I64
	ticks_of = |steps| steps.fold(0, |total, step| total + step.frames)
}

glance_steps : List(Choreography.Step)
glance_steps = [
	{ move: Moves.goalpost, frames: 16 },
	{ move: { ..Moves.goalpost, head: 0.5 }, frames: 8 },
	{ move: { ..Moves.goalpost, head: 1.0 }, frames: 14 },
	{ move: { ..Moves.goalpost, head: 0.5 }, frames: 8 },
	{ move: Moves.goalpost, frames: 8 },
	{ move: { ..Moves.goalpost, pop: 0.04 }, frames: 6 },
]

wink_steps : List(Choreography.Step)
wink_steps = [
	{ move: { ..Moves.goalpost, wink: 1.0 }, frames: 16 },
	{ move: Moves.goalpost, frames: 10 },
	{ move: { ..Moves.goalpost, head: -0.5 }, frames: 8 },
	{ move: { ..Moves.goalpost, head: -1.0 }, frames: 14 },
	{ move: Moves.goalpost, frames: 12 },
]

# One step of a march: down on the knees, then up, half a second.
beat_steps : Moves.Move -> List(Choreography.Step)
beat_steps = |move| [{ move: { ..move, bounce: 0.05 }, frames: 15 }, { move, frames: 15 }]

# `move` held for `frames` ticks, bobbing on the knees every quarter second.
groove_steps : Moves.Move, I64 -> List(Choreography.Step)
groove_steps = |move, frames| {
	bob = [{ move: { ..move, bounce: 0.04 }, frames: 15 }, { move, frames: 15 }]
	left_over = frames - 30 * (frames // 30)
	whole = repeated_steps(bob, (frames // 30).to_u64_wrap())
	if left_over > 0 {
		whole.append({ move, frames: left_over })
	} else {
		whole
	}
}

# A shoulder pop: up for a few ticks, and down.
pop_steps : F64 -> List(Choreography.Step)
pop_steps = |lift| [
	{ move: { ..Moves.goalpost, pop: lift }, frames: 8 },
	{ move: Moves.goalpost, frames: pop_frames - 8 },
]

repeated_steps : List(Choreography.Step), U64 -> List(Choreography.Step)
repeated_steps = |steps, times| List.repeat(steps, times).join()

parade_breath : I64
parade_breath = 24

first_roll_frames : I64
first_roll_frames = 210

pop_frames : I64
pop_frames = 30

pop_gap : I64
pop_gap = 180

wave_gap : I64
wave_gap = 150

arms_up_frames : I64
arms_up_frames = 60

# A groove lasts exactly what it is asked for.
expect Choreography.ticks_of(groove_steps(Moves.goalpost, 100)) == 100
expect Choreography.ticks_of(groove_steps(Moves.goalpost, 120)) == 120
