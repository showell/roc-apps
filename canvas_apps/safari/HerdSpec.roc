# HerdSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Grade
import Herd
import ListUtils
import Scenery

bull_count_got : List(I64)
bull_count_got = [Herd.bull_of(True).len().to_i64_wrap(), Herd.bull_of(False).len().to_i64_wrap(), Herd.fill_cows(True).len().to_i64_wrap(), Herd.fill_cows(False).len().to_i64_wrap(), (List.get(Herd.bull_of(True), I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).codepoint, Herd.bull_cp, Herd.cow_cp]

bull_count_want : List(I64)
bull_count_want = [1, 0, 15, 14, 128002, 128002, 128004]

bull_face_got : List(Bool)
bull_face_got = [(List.get(Herd.bull_of(True), I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).face_right, (List.get(Herd.fill_cows(True), I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).face_right]

bull_face_want : List(Bool)
bull_face_want = [False, True]

bull_place_got : List(F64)
bull_place_got = (
	{
		b = (List.get(Herd.bull_of(True), I64.to_u64_wrap(0)) ?? crash ("list-at out of range"))
		[b.along, b.across, Herd.bull_dist, Herd.bull_tree_gap]
	}
)

bull_place_want : List(F64)
bull_place_want = [24.0, (-4.805), 24.0, 0.5]

height_got : List(F64)
height_got = [Herd.cow_height, Herd.calf_height]

height_want : List(F64)
height_want = [1.4, 0.7]

bull_height_got : List(F64)
bull_height_got = [Herd.bull_height, (List.get(Herd.bull_of(True), I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).height]

bull_height_want : List(F64)
bull_height_want = [1.61, 1.61]

cows : List(Scenery.Critter)
cows = Herd.cows_from(0)

cow_of : I64 -> Scenery.Critter
cow_of = |i| (List.get(cows, I64.to_u64_wrap(i)) ?? crash ("list-at out of range"))

alongs_got : List(F64)
alongs_got = ListUtils.list_map(lam_0, cows)

alongs_want : List(F64)
alongs_want = [28.0, 30.0, 32.0, 34.0, 36.0, 38.0, 40.0, 42.0, 44.0, 46.0, 48.0, 50.0, 52.0, 54.0]

acrosses_got : List(F64)
acrosses_got = ListUtils.list_map(lam_1, cows)

acrosses_want : List(F64)
acrosses_want = [(-12.0), (-17.0), (-22.0), (-12.0), (-17.0), (-22.0), (-12.0), (-17.0), (-22.0), (-12.0), (-17.0), (-22.0), (-12.0), (-17.0)]

calves_got : List(F64)
calves_got = ListUtils.list_map(lam_2, cows)

calves_want : List(F64)
calves_want = [1.4, 0.7, 1.4, 1.4, 1.4, 0.7, 1.4, 1.4, 1.4, 0.7, 1.4, 1.4, 1.4, 0.7]

kind_got : List(I64)
kind_got = [cows.len().to_i64_wrap(), cow_of(0).codepoint, cow_of(13).codepoint]

kind_want : List(I64)
kind_want = [14, 128004, 128004]

order_got : List(F64)
order_got = (
	{
		all = Herd.fill_cows(True)
		[(List.get(all, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).along, ((List.get(all, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).along - cow_of(0).along), ((List.get(all, I64.to_u64_wrap(14)) ?? crash ("list-at out of range")).along - cow_of(13).along)]
	}
)

order_want : List(F64)
order_want = [24.0, 0.0, 0.0]

spacing_got : List(F64)
spacing_got = [Herd.herd_gap_behind_bull, Herd.herd_col_spacing, Herd.herd_row_stagger, Herd.herd_row_depth, Herd.herd_jitter_along, Herd.herd_jitter_across]

spacing_want : List(F64)
spacing_want = [6.0, 6.0, 2.0, 5.0, 1.5, 1.2]

lam_0 : Scenery.Critter -> F64
lam_0 = |c| c.along

lam_1 : Scenery.Critter -> F64
lam_1 = |c| c.across

lam_2 : Scenery.Critter -> F64
lam_2 = |c| c.height

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "hd-bull  ",
			got: bull_count_got,
			want: bull_count_want,
		}),
		Grade.bools({
			name: "hd-face  ",
			got: bull_face_got,
			want: bull_face_want,
		}),
		Grade.reals({
			name: "hd-place ",
			got: bull_place_got,
			want: bull_place_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "hd-height",
			got: height_got,
			want: height_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "hd-bullh ",
			got: bull_height_got,
			want: bull_height_want,
			tol: F64.from_bits(4427486594234968593),
		}),
		Grade.reals({
			name: "hd-calves",
			got: calves_got,
			want: calves_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "hd-kind  ",
			got: kind_got,
			want: kind_want,
		}),
		Grade.reals({
			name: "hd-order ",
			got: order_got,
			want: order_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "hd-space ",
			got: spacing_got,
			want: spacing_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "hd-along ",
			got: alongs_got,
			want: alongs_want,
			tol: 1.5,
		}),
		Grade.reals({
			name: "hd-across",
			got: acrosses_got,
			want: acrosses_want,
			tol: 1.2,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
