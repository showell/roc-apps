## These are World's checks: the route's shape, its headings and turns, and
## what the segments built from it hold.
app [main!] {
	lib: "../lib/main.roc",
}

import Grade
import lib.Trig
import World

route_shape_got : List(I64)
route_shape_got = List.concat([World.route.len().to_i64_wrap()], [0, 3, 11, 12, 19].map(World.pig_segments_before))

route_shape_want : List(I64)
route_shape_want = [19, 0, 1, 2, 3, 9]

headings_got : List(F64)
headings_got = World.route.map_with_index(|_, index| World.heading_at(U64.to_i64_wrap(index)) / Trig.deg)

headings_want : List(F64)
headings_want = [0.0, 50.0, (-20.0), 0.0, 20.0, (-50.0), (-120.0), (-40.0), (-25.0), (-95.0), (-80.0), (-65.0), (-50.0), (-35.0), (-85.0), (-35.0), (-85.0), (-35.0), (-85.0)]

steps_got : List(F64)
steps_got = [0, 1, 6, 18].map(|index| World.turn(World.route.get(index) ?? crash "WorldSpec: the route has 19 segments") / Trig.deg)

steps_want : List(F64)
steps_want = [50.0, (-70.0), 80.0, 0.0]

seg : I64 -> World.Segment
seg = |i| World.segment_at(i)

length_got : List(F64)
length_got = [seg(0).length, seg(1).length, seg(6).length, seg(9).length, seg(18).length, seg(0).width, seg(18).width]

length_want : List(F64)
length_want = [500.0, 320.0, 1200.0, 800.0, 300.0, 4.0, 4.0]

exit_got : List(I64)
exit_got = [seg(0).exit_to, seg(1).exit_to, seg(17).exit_to, seg(18).exit_to]

exit_want : List(I64)
exit_want = [1, 2, 18, 18]

flags_got : List(Bool)
flags_got = [seg(0).terminates, seg(18).terminates, seg(0).exit_right, seg(1).exit_right, seg(6).exit_right, seg(18).exit_right, seg(0).has_mid_tower, seg(6).has_mid_tower, seg(9).has_mid_tower, seg(0).has_cat, seg(1).has_cat, seg(12).has_cat, seg(18).has_cat]

flags_want : List(Bool)
flags_want = [False, True, True, False, True, True, False, True, False, False, True, True, True]

angle_got : List(F64)
angle_got = [(seg(0).exit_angle / Trig.deg), (seg(1).exit_angle / Trig.deg), (seg(6).exit_angle / Trig.deg), (seg(18).exit_angle / Trig.deg), seg(18).commit_along]

angle_want : List(F64)
angle_want = [50.0, 70.0, 80.0, 0.0, 300.0]

commit_got : List(F64)
commit_got = [seg(0).commit_along, seg(1).commit_along, seg(6).commit_along]

commit_want : List(F64)
commit_want = [498.32180073764545, 319.2720595314676, 1199.647346038583]

pigs_got : List(I64)
pigs_got = [seg(0).pigs.len().to_i64_wrap(), seg(2).pigs.len().to_i64_wrap(), seg(10).pigs.len().to_i64_wrap(), seg(11).pigs.len().to_i64_wrap(), seg(13).pigs.len().to_i64_wrap(), seg(18).pigs.len().to_i64_wrap()]

pigs_want : List(I64)
pigs_want = [0, 49, 49, 10, 10, 10]

distract_got : List(Bool)
distract_got = [seg(0).pigs_distract, seg(2).pigs_distract, seg(10).pigs_distract, seg(11).pigs_distract, seg(18).pigs_distract]

distract_want : List(Bool)
distract_want = [False, True, True, False, False]

cows_got : List(I64)
cows_got = [seg(0).cows.len().to_i64_wrap(), seg(3).cows.len().to_i64_wrap(), seg(4).cows.len().to_i64_wrap(), seg(18).cows.len().to_i64_wrap()]

cows_want : List(I64)
cows_want = [14, 14, 15, 15]

trees_got : List(I64)
trees_got = [seg(0).trees.len().to_i64_wrap(), seg(1).trees.len().to_i64_wrap(), seg(6).trees.len().to_i64_wrap(), seg(18).trees.len().to_i64_wrap()]

trees_want : List(I64)
trees_want = [28, 16, 74, 14]

cat_got : List(F64)
cat_got = [seg(0).cat.mid_across, seg(18).cat.mid_across, seg(0).cat.height, seg(18).cat.height]

cat_want : List(F64)
cat_want = [0.816, 0.816, 1.7, 1.7]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "wo-shape ",
			got: route_shape_got,
			want: route_shape_want,
		}),
		Grade.reals({
			name: "wo-head  ",
			got: headings_got,
			want: headings_want,
			tol: F64.from_bits(4427486594234968593),
		}),
		Grade.reals({
			name: "wo-step  ",
			got: steps_got,
			want: steps_want,
			tol: F64.from_bits(4427486594234968593),
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
