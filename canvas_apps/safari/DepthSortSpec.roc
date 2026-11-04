## These are DepthSort's checks: keys come out far to near, keys about as
## far away keep the order they came in, and how near is near enough to tie.
app [main!] {
	lib: "../lib/main.roc",
}

import DepthSort
import Grade

# Ten keys, each with its own place, so the order they come out in shows
# whether ties kept theirs.
mixed : List(DepthSort.DepthKey)
mixed = [
	{ forward: 30.0, subject: Tree(0) },
	{ forward: 10.0, subject: Critter(1) },
	{ forward: 30.0, subject: Rail(2) },
	{ forward: 50.0, subject: Tower(3) },
	{ forward: 10.0, subject: Cat(4) },
	{ forward: 20.0, subject: Bird(5) },
	{ forward: 30.0, subject: Tree(6) },
	{ forward: 40.0, subject: Rail(7) },
	{ forward: 10.0, subject: Critter(8) },
	{ forward: 5.0, subject: Cat(9) },
]

sorted_by_forward : List(DepthSort.DepthKey) -> List(DepthSort.DepthKey)
sorted_by_forward = |keys| DepthSort.sort_by(keys, |key| key.forward)

## The place a key names in its kind's list. The keys here never name the
## truck, which has none.
place_of : DepthSort.DepthKey -> I64
place_of = |key|
	match key.subject {
		Tree(place) | Tower(place) | Critter(place) | Cat(place) | Rail(place) | Bird(place) => place.to_i64_wrap()
		Truck => crash "DepthSortSpec: no key here names the truck"
	}

kind_code : DepthSort.DepthKey -> I64
kind_code = |key|
	match key.subject {
		Tree(_) => 0
		Tower(_) => 1
		Critter(_) => 2
		Cat(_) => 3
		Truck => 4
		Rail(_) => 5
		Bird(_) => 6
	}

order_want : List(F64)
order_want = [50.0, 40.0, 30.0, 30.0, 30.0, 20.0, 10.0, 10.0, 10.0, 5.0]

stable_want : List(I64)
stable_want = [3, 7, 0, 2, 6, 5, 1, 4, 8, 9]

kind_want : List(I64)
kind_want = [1, 5, 0, 5, 0, 6, 2, 3, 2, 3]

# Pairs of trees a hair apart, at 100 m and at half a metre. At each depth
# the first pair is within the tie's slack and keeps its order; the second
# is not, and its farther tree goes first.
slack_got : List(I64)
slack_got = [
	[{ forward: 100.0, subject: Tree(0) }, { forward: 100.000004, subject: Tree(1) }],
	[{ forward: 100.0, subject: Tree(0) }, { forward: 100.00001, subject: Tree(1) }],
	[{ forward: 0.5, subject: Tree(0) }, { forward: 0.50000004, subject: Tree(1) }],
	[{ forward: 0.5, subject: Tree(0) }, { forward: 0.5000001, subject: Tree(1) }],
].join_map(|keys| sorted_by_forward(keys).map(place_of))

slack_want : List(I64)
slack_want = [0, 1, 1, 0, 0, 1, 1, 0]

# --- Entry ---

main! = |_args| {
	sorted = sorted_by_forward(mixed)
	verdicts = [
		Grade.reals({
			name: "d-order ",
			got: sorted.map(|key| key.forward),
			want: order_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "d-stable",
			got: sorted.map(place_of),
			want: stable_want,
		}),
		Grade.ints({
			name: "d-kind  ",
			got: sorted.map(kind_code),
			want: kind_want,
		}),
		Grade.ints({
			name: "d-slack ",
			got: slack_got,
			want: slack_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
