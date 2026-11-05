## These are World's checks: the route's shape, and what the segments built
## from it hold.
app [main!] {
	lib: "../lib/main.roc",
}

import Cat
import Grade
import lib.Trig
import World

route_shape_got : List(I64)
route_shape_got = List.concat(
	[World.route.len().to_i64_wrap()],
	[
		0,
		2,
		10,
		11,
		18,
	].map(|number| World.pig_segments_through(World.SegmentIndex.number(number)).to_i64()),
)

route_shape_want : List(I64)
route_shape_want = [19, 0, 1, 2, 3, 9]

seg : U32 -> World.Segment
seg = |i| World.route_segment(i)

length_got : List(F64)
length_got = [
	seg(0).length,
	seg(1).length,
	seg(6).length,
	seg(9).length,
	seg(18).length,
]

length_want : List(F64)
length_want = [500.0, 320.0, 1200.0, 800.0, 300.0]

exit_got : List(I64)
exit_got = [0, 1, 17].map(|index| next_of(seg(index)))

exit_want : List(I64)
exit_want = [1, 2, 18]

flags_got : List(Bool)
flags_got = List.join([
	[0, 18].map(|index| is_route_end(seg(index))),
	[0, 1, 6, 18].map(|index| turns_right(seg(index))),
	[0, 6, 9].map(|index| has_mid_tower(seg(index))),
	[0, 1, 12, 18].map(|index| has_cat(seg(index))),
])

flags_want : List(Bool)
flags_want = [False, True, True, False, True, True, False, True, False, False, True, True, True]

angle_got : List(F64)
angle_got = [
	(seg(0).exit_turn.abs().to_radians() / Trig.deg),
	(seg(1).exit_turn.abs().to_radians() / Trig.deg),
	(seg(6).exit_turn.abs().to_radians() / Trig.deg),
	(seg(18).exit_turn.abs().to_radians() / Trig.deg),
	seg(18).commit_along,
]

angle_want : List(F64)
angle_want = [50.0, 70.0, 80.0, 0.0, 300.0]

commit_got : List(F64)
commit_got = [
	seg(0).commit_along,
	seg(1).commit_along,
	seg(6).commit_along,
]

commit_want : List(F64)
commit_want = [498.32180073764545, 319.2720595314676, 1199.647346038583]

pigs_got : List(I64)
pigs_got = [
	seg(0).pigs.len().to_i64_wrap(),
	seg(2).pigs.len().to_i64_wrap(),
	seg(10).pigs.len().to_i64_wrap(),
	seg(11).pigs.len().to_i64_wrap(),
	seg(13).pigs.len().to_i64_wrap(),
	seg(18).pigs.len().to_i64_wrap(),
]

pigs_want : List(I64)
pigs_want = [0, 49, 49, 10, 10, 10]

distract_got : List(Bool)
distract_got = [0, 2, 10, 11, 18].map(|index| is_distracting(seg(index)))

distract_want : List(Bool)
distract_want = [False, True, True, False, False]

cows_got : List(I64)
cows_got = [
	seg(0).cows.len().to_i64_wrap(),
	seg(3).cows.len().to_i64_wrap(),
	seg(4).cows.len().to_i64_wrap(),
	seg(18).cows.len().to_i64_wrap(),
]

cows_want : List(I64)
cows_want = [14, 14, 15, 15]

trees_got : List(I64)
trees_got = [
	seg(0).trees.len().to_i64_wrap(),
	seg(1).trees.len().to_i64_wrap(),
	seg(6).trees.len().to_i64_wrap(),
	seg(18).trees.len().to_i64_wrap(),
]

trees_want : List(I64)
trees_want = [28, 16, 74, 14]

cat_got : List(F64)
cat_got = [
	crossing_at(1).mid_across,
	crossing_at(18).mid_across,
	crossing_at(1).height,
	crossing_at(18).height,
]

cat_want : List(F64)
cat_want = [0.816, 0.816, 1.7, 1.7]

## Whether the route ends with a segment.
is_route_end : World.Segment -> Bool
is_route_end = |segment|
	match segment.ending {
		Continues(_) => False
		Terminates => True
	}

## The segment after one that continues.
next_of : World.Segment -> I64
next_of = |segment|
	match segment.ending {
		Continues({ next }) => next.to_i64()
		Terminates => crash "WorldSpec.next_of: segments 0, 1 and 17 continue"
	}

## Whether a segment ends by turning right.
turns_right : World.Segment -> Bool
turns_right = |segment| segment.exit_turn.is_right()

## Whether a segment has a mast halfway along.
has_mid_tower : World.Segment -> Bool
has_mid_tower = |segment|
	match segment.mid_tower {
		MidTower => True
		NoMidTower => False
	}

## Whether a segment has a cat waiting by the road.
has_cat : World.Segment -> Bool
has_cat = |segment|
	match segment.cat {
		Waits(_) => True
		NoCat => False
	}

## Whether a segment's pigs draw the rider's eye.
is_distracting : World.Segment -> Bool
is_distracting = |segment|
	match segment.pig_attention {
		Distracting => True
		Unnoticed => False
	}

## The cat crossing at a segment that has one.
crossing_at : U32 -> Cat.Crossing
crossing_at = |index|
	match seg(index).cat {
		Waits(crossing) => crossing
		NoCat => crash "WorldSpec.crossing_at: segments 1 and 18 have a cat"
	}

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "wo-shape ",
			got: route_shape_got,
			want: route_shape_want,
		}),
		Grade.reals({
			name: "wo-length",
			got: length_got,
			want: length_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "wo-exit  ",
			got: exit_got,
			want: exit_want,
		}),
		Grade.bools({
			name: "wo-flags ",
			got: flags_got,
			want: flags_want,
		}),
		Grade.reals({
			name: "wo-angle ",
			got: angle_got,
			want: angle_want,
			tol: F64.from_bits(4427486594234968593),
		}),
		Grade.reals({
			name: "wo-commit",
			got: commit_got,
			want: commit_want,
			tol: F64.from_bits(4487126258331716666),
		}),
		Grade.ints({
			name: "wo-pigs  ",
			got: pigs_got,
			want: pigs_want,
		}),
		Grade.bools({
			name: "wo-distr ",
			got: distract_got,
			want: distract_want,
		}),
		Grade.ints({
			name: "wo-cows  ",
			got: cows_got,
			want: cows_want,
		}),
		Grade.ints({
			name: "wo-trees ",
			got: trees_got,
			want: trees_want,
		}),
		Grade.reals({
			name: "wo-cat   ",
			got: cat_got,
			want: cat_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
