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

	## While the eye backs away: bounces with the arms out, and the forearms
	## hinging down.
	travel_steps : List(Choreography.Step)
	travel_steps = [
		{ move: { ..Moves.arms_out, bounce: 0.05 }, frames: 7 },
		{ move: Moves.arms_out, frames: 7 },
		{ move: { ..Moves.arms_out, bounce: 0.05 }, frames: 7 },
		{ move: Moves.arms_out, frames: 7 },
		{ move: { ..Moves.arms_out, bounce: 0.05 }, frames: 7 },
		{ move: Moves.arms_out, frames: 9 },
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

	## While the floats roll in: a groove in the goalpost, and a shoulder pop,
	## left and right in turn, as each float brakes to a stop. The pops come
	## faster and faster, as the floats do.
	parade_steps : List(Choreography.Step)
	parade_steps = {
		first_stop = pop_offsets.first() ?? crash "Choreography.parade_steps: the floats stop"
		next_stops = pop_offsets.drop_first(1).append(parade_ticks)
		pops =
			List.map3(pop_offsets, next_stops, [0.07, -0.07, 0.07, -0.07], |stop, next, lift| (next - stop, lift))
				.map(
					|(gap, lift)| List.concat(
						pop_steps(lift),
						groove_steps(Moves.goalpost, gap - pop_frames),
					),
				)
				.join()
		List.concat(groove_steps(Moves.goalpost, first_stop), pops)
	}

	## The ticks from the start of the parade to each float's stop, one a
	## shoulder pop.
	pop_offsets : List(I64)
	pop_offsets = [200, 270, 330, 380]

	## While the robots play musical chairs: a groove while the music plays,
	## and when it stops, a freeze like everyone else's, the head turned to
	## the chairs, until the army marches in.
	chairs_steps : List(Choreography.Step)
	chairs_steps = List.concat(
		groove_steps(Moves.goalpost, music_offset),
		[{ move: { ..Moves.goalpost, head: -1.0 }, frames: chairs_ticks - music_offset }],
	)

	## The ticks from the start of the musical chairs to the music stopping.
	music_offset : I64
	music_offset = 240

	## While the army marches in: a bounce on every step of its drum, arms
	## out, the head clicking toward the marchers every few steps.
	strut_steps : List(Choreography.Step)
	strut_steps =
		[0.0, -1.0, 0.0, 1.0, 0.0, -1.0, 0.0, 1.0]
			.map(|head| beat_steps({ ..Moves.arms_out, head }))
			.join()
			.append({ move: Moves.arms_out, frames: 70 })

	## While the army breaks ranks and finds its seats: arms out, bouncing on
	## the beat, the head clicking after the marchers as they run past.
	seat_steps : List(Choreography.Step)
	seat_steps =
		[0.0, 1.0, 0.0, -1.0, 0.0, 1.0, 0.0, -1.0, 0.0, 1.0, 0.0, -1.0]
			.map(|head| beat_steps({ ..Moves.arms_out, head }))
			.join()

	## A noise behind the fence: a hand up to the brow, and the head clicking
	## from side to side, looking for it.
	peek_steps : List(Choreography.Step)
	peek_steps = {
		brow = { ..Moves.rest, right_upper: 2.5, right_fore: -1.2 }
		[-1.0, 1.0]
			.map(|head| [{ move: { ..brow, head }, frames: 35 }, { move: brow, frames: 35 }])
			.join()
	}

	## While the crowd floods in: arms out, bouncing on the beat, the head
	## clicking one way and the other.
	flood_steps : List(Choreography.Step)
	flood_steps =
		[0.0, 1.0, 0.0, -1.0]
			.map(
				|head| List.concat(
					beat_steps({ ..Moves.arms_out, head }),
					beat_steps(Moves.arms_out),
				),
			)
			.join()

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
		{ move: Moves.final_pose, frames: 190 },
	]

	## The ticks from the start of the finale to its wink.
	final_wink_offset : I64
	final_wink_offset = 80

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

# The musical chairs, from the boombox dropping in to the drum major's wink
# and a moment after.
chairs_ticks : I64
chairs_ticks = 510

# The parade ends a moment after the last float stops.
parade_ticks : I64
parade_ticks = 420

pop_frames : I64
pop_frames = 30

wave_gap : I64
wave_gap = 40

arms_up_frames : I64
arms_up_frames = 40

# A groove lasts exactly what it is asked for.
expect Choreography.ticks_of(groove_steps(Moves.goalpost, 100)) == 100
expect Choreography.ticks_of(groove_steps(Moves.goalpost, 120)) == 120
