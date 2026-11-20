## Moves are the poses the robot dance is made of: a Move is every joint's
## angle and the few other numbers Dancer is told, without the walk.
## Choreography strings them into sections, and Routine says which one is
## danced at a tick.
Moves :: [].{

	## One pose of the dance. `wink` closes the left eye at 1.
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

	## Arms hanging, face on.
	rest : Moves.Move
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

	## A quarter turn, in radians: an arm straight out to the side.
	quarter : F64
	quarter = F64.pi / 2.0

	## Both arms out and bent up at the elbow, a right angle each.
	goalpost : Moves.Move
	goalpost = {
		..rest,
		left_upper: -quarter,
		left_fore: -F64.pi,
		right_upper: quarter,
		right_fore: F64.pi,
	}

	## Both arms straight out to the sides.
	arms_out : Moves.Move
	arms_out = {
		..rest,
		left_upper: -quarter,
		left_fore: -quarter,
		right_upper: quarter,
		right_fore: quarter,
	}

	## Both arms straight up, a little apart, for the wave.
	arms_up : Moves.Move
	arms_up = {
		..rest,
		left_upper: -2.8,
		left_fore: -2.95,
		right_upper: 2.8,
		right_fore: 2.95,
	}

	## The right arm out, its forearm at `fore`.
	right_arm : F64 -> Moves.Move
	right_arm = |fore| { ..rest, right_upper: quarter, right_fore: fore }

	## The final pose: one forearm up, one down, head to the eye, knees
	## dropped a little.
	final_pose : Moves.Move
	final_pose = {
		..rest,
		right_upper: quarter,
		right_fore: F64.pi,
		left_upper: -quarter,
		left_fore: 0.0,
		bounce: 0.03,
	}

	## The move `fraction` of the way from `from` to `to`, joint by joint.
	mixed_move : {
		from : Moves.Move,
		to : Moves.Move,
		fraction : F64,
	} -> Moves.Move
	mixed_move = |{ from, to, fraction }| {
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
}

# Mixing goes all the way at 1 and nowhere at 0.
expect Moves.mixed_move({
	from: Moves.rest,
	to: Moves.goalpost,
	fraction: 0.0,
}) == Moves.rest
expect Moves.mixed_move({
	from: Moves.rest,
	to: Moves.goalpost,
	fraction: 1.0,
}) == Moves.goalpost
