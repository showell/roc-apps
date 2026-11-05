## These are CrossingReaction's checks: a cat holds the throttle while it
## crosses and not before or after, draws the rider's eye as it crosses and lets
## it go, and a bird and a quiet road ask nothing.
app [main!] {
	lib: "../lib/main.roc",
}

import Cat
import CrossingReaction
import Grade
import Pose
import Speed
import World

bird_segment : World.Segment
bird_segment = World.route_segment(0)

quiet_segment : World.Segment
quiet_segment = World.route_segment(1)

cat_segment : World.Segment
cat_segment = World.route_segment(3)

cat_along : F64
cat_along =
	match cat_segment.crossing {
		CatCrosses(crossing) => crossing.along
		BirdFlies(_) | QuietRoad => crash "CrossingReactionSpec: segment 3 has a cat"
	}

## A rider `along` their segment at `speed` metres a step.
rider_at : F64, F64 -> Pose.RiderState
rider_at = |along, speed| {
	..Pose.initial_rider_state,
	along,
	speed: Speed.metres_a_step(speed),
}

## The reaction to the cat of a rider `gap` metres short of it.
to_cat : F64, F64 -> CrossingReaction.Reaction
to_cat = |gap, speed| CrossingReaction.reaction_to(cat_segment, rider_at(cat_along - gap, speed))

## A reaction's throttle as a number: 0 free, 1 held.
held_number : CrossingReaction.Reaction -> I64
held_number = |reaction|
	match reaction.throttle {
		Free => 0
		Held => 1
	}

cat_throttle_got : List(I64)
cat_throttle_got = [
	to_cat(42.0, 1.0),
	to_cat(41.0, 1.0),
	to_cat(22.0, 1.0),
	to_cat(3.5, 1.0),
	to_cat(3.0, 1.0),
	to_cat(2.0, 1.0),
	to_cat(22.0, 0.0),
].map(held_number)

cat_throttle_want : List(I64)
cat_throttle_want = [
	0,
	1,
	1,
	1,
	0,
	0,
	0,
]

cat_eye_got : List(F64)
cat_eye_got = [
	to_cat(42.0, 1.0).eye_pull,
	to_cat(41.0, 1.0).eye_pull,
	to_cat(22.0, 1.0).eye_pull,
	to_cat(3.0, 1.0).eye_pull,
	to_cat(-38.5, 1.0).eye_pull,
	to_cat(-80.0, 1.0).eye_pull,
	to_cat(22.0, 0.0).eye_pull,
]

cat_eye_want : List(F64)
cat_eye_want = [
	0.0,
	0.0,
	0.9,
	1.8,
	0.9,
	0.0,
	0.0,
]

## A bird or a quiet road at each place on it, and at each speed.
unmoved_got : List(Bool)
unmoved_got = [bird_segment, quiet_segment].join_map(
	|segment| [0.0, 60.0, 100.0, 200.0, 400.0].join_map(
		|along| [0.0, 0.3, 1.0].map(
			|speed| {
				reaction = CrossingReaction.reaction_to(segment, rider_at(along, speed))
				held_number(reaction) == 0 and reaction.eye_pull == 0.0
			},
		),
	),
)

unmoved_want : List(Bool)
unmoved_want = List.repeat(True, 30)

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "cr-throttle",
			got: cat_throttle_got,
			want: cat_throttle_want,
		}),
		Grade.reals({
			name: "cr-eye     ",
			got: cat_eye_got,
			want: cat_eye_want,
			tol: 0.000000001,
		}),
		Grade.bools({
			name: "cr-unmoved ",
			got: unmoved_got,
			want: unmoved_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
