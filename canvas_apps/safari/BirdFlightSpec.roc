## These are BirdFlight's checks: which tree a bird starts on, which it flies
## to, how far through its flight it is at and around take-off and landing,
## where it sits before and after, and how it looks on the way.
app [main!] {
	lib: "../lib/main.roc",
}

import BirdFlight
import Grade
import Scenery

tree_at : F64, F64 -> Scenery.Tree
tree_at = |along, across| {
	along,
	across,
	color: 0,
	height: 10.0,
}

left_tree : Scenery.Tree
left_tree = tree_at(100.0, -6.0)

## A tree on the far side too near to fly to, and two far enough.
trees : List(Scenery.Tree)
trees = [
	left_tree,
	tree_at(100.0, 6.0),
	tree_at(140.0, -6.0),
	tree_at(140.0, 6.0),
	tree_at(180.0, 6.0),
]

flight : BirdFlight.Flight
flight = {
	from: left_tree,
	to: { ..tree_at(140.0, 6.0), height: 12.0 },
}

## A left and a right tree at each of `alongs`.
pairs_at : List(F64) -> List(Scenery.Tree)
pairs_at = |alongs| alongs.join_map(|along| [tree_at(along, -6.0), tree_at(along, 6.0)])

## How far along the fifth left tree of `choices` is: one number, or none.
fifth_along : List(Scenery.Tree) -> List(F64)
fifth_along = |choices|
	match BirdFlight.fifth_left_tree(choices) {
		Found(tree) => [tree.along]
		NoTree => []
	}

fifth_got : List(List(F64))
fifth_got = [
	fifth_along([]),
	fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0])),
	fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0, 50.0])),
	fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0, 50.0, 60.0])),
	fifth_along([50.0, 60.0, 70.0, 80.0, 90.0].map(|along| tree_at(along, 6.0))),
]

fifth_lengths_got : List(I64)
fifth_lengths_got = fifth_got.map(|found| found.len().to_i64_wrap())

fifth_lengths_want : List(I64)
fifth_lengths_want = [0, 0, 1, 1, 0]

fifth_alongs_got : List(F64)
fifth_alongs_got = List.join(fifth_got)

fifth_alongs_want : List(F64)
fifth_alongs_want = [50.0, 50.0]

chosen_along : List(Scenery.Tree) -> List(F64)
chosen_along = |choices|
	match BirdFlight.flight_from(choices, left_tree) {
		Flies(found) => [found.to.along, found.to.across]
		Stays => []
	}

target_got : List(F64)
target_got = List.join([
	chosen_along(trees),
	chosen_along([left_tree, tree_at(124.0, 6.0)]),
	chosen_along([left_tree, tree_at(125.0, 6.0)]),
	chosen_along([left_tree, tree_at(140.0, -6.0)]),
])

target_want : List(F64)
target_want = [140.0, 6.0, 125.0, 6.0]

progress_got : List(F64)
progress_got = [
	BirdFlight.flight_progress(BirdFlight.takeoff_gap + 1.0),
	BirdFlight.flight_progress(BirdFlight.takeoff_gap),
	BirdFlight.flight_progress((BirdFlight.takeoff_gap + BirdFlight.landing_gap) / 2.0),
	BirdFlight.flight_progress(BirdFlight.landing_gap),
	BirdFlight.flight_progress(BirdFlight.landing_gap - 1.0),
]

progress_want : List(F64)
progress_want = [0.0, 0.0, 0.5, 1.0, 1.0]

ends_got : List(F64)
ends_got = {
	before = BirdFlight.state(flight, 100.0)
	after = BirdFlight.state(flight, 0.0)
	[
		before.along,
		before.across,
		before.lift,
		after.along,
		after.across,
		after.lift,
	]
}

ends_want : List(F64)
ends_want = [100.0, -6.0, 10.0, 140.0, 6.0, 12.0]

middle_got : List(F64)
middle_got = {
	middle = BirdFlight.state(flight, (BirdFlight.takeoff_gap + BirdFlight.landing_gap) / 2.0)
	[
		middle.along,
		middle.across,
		middle.lift,
	]
}

middle_want : List(F64)
middle_want = [120.0, 0.0, 16.0]

pose_got : List(Bool)
pose_got = List.concat(
	[
		BirdFlight.state(flight, 100.0).pose == Perched,
		BirdFlight.state(flight, 0.0).pose == Perched,
	],
	[
		(0.01, Side(WingsUp)),
		(0.08, Side(WingsDown)),
		(0.1199, Side(WingsUp)),
		(0.12, Away(WingsUp)),
		(0.5 - 1.0 / 36.0, Away(WingsUp)),
		(0.5 + 1.0 / 36.0, Away(WingsDown)),
		(0.87, Away(WingsDown)),
		(0.89, Diving),
		(0.95, Diving),
	].map(|(progress, pose)| BirdFlight.pose_at(progress) == pose),
)

pose_want : List(Bool)
pose_want = List.repeat(True, 11)

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "bf-fifth   ",
			got: fifth_lengths_got,
			want: fifth_lengths_want,
		}),
		Grade.reals({
			name: "bf-fifth-at",
			got: fifth_alongs_got,
			want: fifth_alongs_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "bf-target  ",
			got: target_got,
			want: target_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "bf-progress",
			got: progress_got,
			want: progress_want,
			tol: 0.000000001,
		}),
		Grade.reals({
			name: "bf-ends    ",
			got: ends_got,
			want: ends_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "bf-middle  ",
			got: middle_got,
			want: middle_want,
			tol: 0.000000001,
		}),
		Grade.bools({
			name: "bf-pose    ",
			got: pose_got,
			want: pose_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
