## Routine is the robot dance, move by move: a list of sections, each a list
## of moves and how many ticks each lasts. A move snaps into place over its
## first few ticks and holds for the rest, so the dance goes in clicks rather
## than easing. Every dancer at every table dances it in step. Script says
## when it starts, and times the eye's path and the copies' pops to its
## sections.
Routine :: [].{

	## One pose of the dance: the joints and the rest of what Dancer is told,
	## without the walk. `wink` closes the left eye at 1.
	Move : {
		left_upper : F64,
		left_fore : F64,
		right_upper : F64,
		right_fore : F64,
		head : F64,
		pop : F64,
		turn : F64,
		bounce : F64,
		wink : F64,
	}

	## The routine's sections, in the order they are danced.
	Section : [Opening, Hello, Travel, Multiply, Strut, Finale]

	## Arms hanging, face on.
	rest : Routine.Move
	rest = {
		left_upper: -0.12,
		left_fore: -0.12,
		right_upper: 0.12,
		right_fore: 0.12,
		head: 0.0,
		pop: 0.0,
		turn: 1.0,
		bounce: 0.0,
		wink: 0.0,
	}

	## The move `since` ticks into the routine, and the last move after it
	## ends.
	move_at : I64 -> Routine.Move
	move_at = |since| {
		var $before = rest
		var $start = 0
		var $found = False
		var $move = rest
		for step in all_steps {
			if !$found and since < $start + step.frames {
				$move = snapped_move({
					from: $before,
					to: step.move,
					fraction: snap(since - $start + 1),
				})
				$found = True
			}
			$before = step.move
			$start = $start + step.frames
		}
		if $found {
			$move
		} else {
			$before
		}
	}

	## How many ticks into the routine a section starts.
	section_start : Routine.Section -> I64
	section_start = |wanted| {
		var $start = 0
		var $done = False
		for section in sections_in_order {
			if section == wanted {
				$done = True
			}
			if !$done {
				$start = $start + frames_of(steps_of(section))
			}
		}
		$start
	}

	## How long the whole routine is, in ticks.
	length : I64
	length = frames_of(all_steps)

	## The ticks from the start of the Hello section to the wink.
	wink_offset : I64
	wink_offset = frames_of(glance_steps)

	## The ticks from the start of the Multiply section to each shoulder pop,
	## one for each copied table.
	pop_offsets : List(I64)
	pop_offsets = [0, 1, 2, 3].map(|beat| breath + beat * pop_beat)
}

Step : { move : Routine.Move, frames : I64 }

sections_in_order : List(Routine.Section)
sections_in_order = [Opening, Hello, Travel, Multiply, Strut, Finale]

steps_of : Routine.Section -> List(Step)
steps_of = |section|
	match section {
		Opening => opening_steps
		Hello => hello_steps
		Travel => travel_steps
		Multiply => multiply_steps
		Strut => strut_steps
		Finale => finale_steps
	}

all_steps : List(Step)
all_steps = sections_in_order.map(steps_of).join()

frames_of : List(Step) -> I64
frames_of = |steps| steps.fold(0, |total, step| total + step.frames)

quarter : F64
quarter = F64.pi / 2.0

# Both arms out and bent up at the elbow, a right angle each.
goalpost : Routine.Move
goalpost = {
	..Routine.rest,
	left_upper: -quarter,
	left_fore: -F64.pi,
	right_upper: quarter,
	right_fore: F64.pi,
}

# Both arms straight out to the sides.
arms_out : Routine.Move
arms_out = {
	..Routine.rest,
	left_upper: -quarter,
	left_fore: -quarter,
	right_upper: quarter,
	right_fore: quarter,
}

# The right arm out, its forearm at `fore`.
right_arm : F64 -> Routine.Move
right_arm = |fore| { ..Routine.rest, right_upper: quarter, right_fore: fore }

# The right arm comes up and its forearm waves down in clicks, as the eye
# moves in.
opening_steps : List(Step)
opening_steps = [
	{ move: right_arm(quarter), frames: 14 },
	{ move: right_arm(F64.pi), frames: 18 },
	{ move: right_arm(2.62), frames: 9 },
	{ move: right_arm(2.09), frames: 9 },
	{ move: right_arm(1.57), frames: 9 },
	{ move: right_arm(1.05), frames: 9 },
	{ move: right_arm(0.52), frames: 12 },
]

# In close: the head clicks round to one side and back to the eye, winks at
# it, and clicks round to the other side.
hello_steps : List(Step)
hello_steps = List.concat(glance_steps, wink_steps)

glance_steps : List(Step)
glance_steps = [
	{ move: goalpost, frames: 16 },
	{ move: { ..goalpost, head: 0.5 }, frames: 8 },
	{ move: { ..goalpost, head: 1.0 }, frames: 14 },
	{ move: { ..goalpost, head: 0.5 }, frames: 8 },
	{ move: goalpost, frames: 8 },
	{ move: { ..goalpost, pop: 0.04 }, frames: 6 },
]

wink_steps : List(Step)
wink_steps = [
	{ move: { ..goalpost, wink: 1.0 }, frames: 16 },
	{ move: goalpost, frames: 10 },
	{ move: { ..goalpost, head: -0.5 }, frames: 8 },
	{ move: { ..goalpost, head: -1.0 }, frames: 14 },
	{ move: goalpost, frames: 12 },
]

# While the eye backs away: bounces with the arms out, a turn to the side and
# back, and the forearms hinging down.
travel_steps : List(Step)
travel_steps = [
	{ move: { ..arms_out, bounce: 0.05 }, frames: 7 },
	{ move: arms_out, frames: 7 },
	{ move: { ..arms_out, bounce: 0.05 }, frames: 7 },
	{ move: arms_out, frames: 7 },
	{ move: { ..arms_out, bounce: 0.05 }, frames: 7 },
	{ move: arms_out, frames: 9 },
	{ move: { ..Routine.rest, turn: 0.88 }, frames: 10 },
	{ move: { ..Routine.rest, turn: 0.75 }, frames: 10 },
	{ move: { ..Routine.rest, turn: 0.62 }, frames: 10 },
	{ move: { ..Routine.rest, turn: 0.5 }, frames: 16 },
	{ move: { ..Routine.rest, turn: 0.62 }, frames: 10 },
	{ move: { ..Routine.rest, turn: 0.75 }, frames: 10 },
	{ move: { ..Routine.rest, turn: 0.88 }, frames: 10 },
	{ move: Routine.rest, frames: 12 },
	{ move: { ..goalpost, left_fore: -2.09, right_fore: 2.09 }, frames: 9 },
	{ move: { ..goalpost, left_fore: -1.57, right_fore: 1.57 }, frames: 9 },
	{ move: { ..goalpost, left_fore: -1.05, right_fore: 1.05 }, frames: 9 },
	{
		move: {
			..goalpost,
			left_fore: -1.05,
			right_fore: 1.05,
			head: 1.0,
		},
		frames: 10,
	},
	{
		move: {
			..goalpost,
			left_fore: -1.05,
			right_fore: 1.05,
			head: -1.0,
		},
		frames: 10,
	},
	{ move: goalpost, frames: 8 },
]

# A breath on the empty lawn, then four shoulder pops, one a beat, left and
# right in turn, with a copied table springing up at each, and a breath to
# take in all five.
breath : I64
breath = 12

pop_beat : I64
pop_beat = 18

multiply_steps : List(Step)
multiply_steps = [
	[{ move: goalpost, frames: breath }],
	[0.07, -0.07, 0.07, -0.07]
		.map(
			|lift| [
				{ move: { ..goalpost, pop: lift }, frames: 8 },
				{ move: goalpost, frames: pop_beat - 8 },
			],
		)
		.join(),
	[{ move: goalpost, frames: breath }],
].join()

# While the army marches in: a bounce on every step of its drum, arms out,
# the head clicking toward the marchers every few steps.
strut_steps : List(Step)
strut_steps = {
	beat = |head| [
		{ move: { ..arms_out, bounce: 0.05, head }, frames: 15 },
		{ move: { ..arms_out, head }, frames: 15 },
	]
	looks = [0.0, 0.0, -1.0, 0.0, 0.0, 1.0, 0.0, 0.0, -1.0, 0.0, 0.0, 1.0, 0.0]
	looks.map(beat).join().append({ move: arms_out, frames: 21 })
}

# The final pose: one forearm up, one down, head to the eye, knees dropped a
# little. The movie holds on it.
finale_steps : List(Step)
finale_steps = [
	{
		move: {
			..Routine.rest,
			right_upper: quarter,
			right_fore: F64.pi,
			left_upper: -quarter,
			left_fore: 0.0,
			bounce: 0.03,
		},
		frames: 60,
	},
]

snap_frames : I64
snap_frames = 3

snap : I64 -> F64
snap = |since|
	if since <= 0 {
		0.0
	} else if since >= snap_frames {
		1.0
	} else {
		since.to_f64() / snap_frames.to_f64()
	}

snapped_move : {
	from : Routine.Move,
	to : Routine.Move,
	fraction : F64,
} -> Routine.Move
snapped_move = |{ from, to, fraction }| {
	mix = |from_value, to_value| from_value + (to_value - from_value) * fraction
	{
		left_upper: mix(from.left_upper, to.left_upper),
		left_fore: mix(from.left_fore, to.left_fore),
		right_upper: mix(from.right_upper, to.right_upper),
		right_fore: mix(from.right_fore, to.right_fore),
		head: mix(from.head, to.head),
		pop: mix(from.pop, to.pop),
		turn: mix(from.turn, to.turn),
		bounce: mix(from.bounce, to.bounce),
		wink: mix(from.wink, to.wink),
	}
}

# The sections follow one another, and the routine is their sum.
expect Routine.section_start(Opening) == 0
expect Routine.section_start(Hello) == 80
expect Routine.section_start(Finale) + 60 == Routine.length

# The wink lands on the winking move, and the routine ends on the final pose.
expect Routine.move_at(Routine.section_start(Hello) + Routine.wink_offset + 5).wink == 1.0
expect Routine.move_at(Routine.length + 100).left_fore == 0.0
