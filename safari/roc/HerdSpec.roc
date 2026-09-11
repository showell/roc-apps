# HerdSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import Herd
import ListUtils
import Scenery

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bull_count_got : List(I64)
bull_count_got = [U64.to_i64_wrap(List.len(Herd.bull_of(True))), U64.to_i64_wrap(List.len(Herd.bull_of(False))), U64.to_i64_wrap(List.len(Herd.fill_cows(True))), U64.to_i64_wrap(List.len(Herd.fill_cows(False))), (List.get(Herd.bull_of(True), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).codepoint, Herd.bull_cp, Herd.cow_cp]

bull_count_want : List(I64)
bull_count_want = [1, 0, 15, 14, 128002, 128002, 128004]

bull_face_got : List(Bool)
bull_face_got = [(List.get(Herd.bull_of(True), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).face_right, (List.get(Herd.fill_cows(True), I64.to_u64_wrap(1)) ?? crash("list-at out of range")).face_right]

bull_face_want : List(Bool)
bull_face_want = [False, True]

bull_place_got : List(F64)
bull_place_got = ({
	b = (List.get(Herd.bull_of(True), I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
	[b.along, b.across, Herd.bull_dist, Herd.bull_tree_gap]
})

bull_place_want : List(F64)
bull_place_want = [24.0, (-4.805), 24.0, 0.5]

height_got : List(F64)
height_got = [Herd.cow_height, Herd.calf_height]

height_want : List(F64)
height_want = [1.4, 0.7]

bull_height_got : List(F64)
bull_height_got = [Herd.bull_height, (List.get(Herd.bull_of(True), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).height]

bull_height_want : List(F64)
bull_height_want = [1.61, 1.61]

cows : List(Scenery.Critter)
cows = Herd.cows_from(0)

cow_of : I64 -> Scenery.Critter
cow_of = |i| (List.get(cows, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))

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
kind_got = [U64.to_i64_wrap(List.len(cows)), cow_of(0).codepoint, cow_of(13).codepoint]

kind_want : List(I64)
kind_want = [14, 128004, 128004]

order_got : List(F64)
order_got = ({
	all = Herd.fill_cows(True)
	[(List.get(all, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).along, ((List.get(all, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).along - cow_of(0).along), ((List.get(all, I64.to_u64_wrap(14)) ?? crash("list-at out of range")).along - cow_of(13).along)]
})

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
	line!(Grade.grade_ints("hd-bull  ", bull_count_got, bull_count_want))
	line!(Grade.grade_bools("hd-face  ", bull_face_got, bull_face_want))
	line!(Grade.grade_reals("hd-place ", bull_place_got, bull_place_want, 0.0))
	line!(Grade.grade_reals("hd-height", height_got, height_want, 0.0))
	line!(Grade.grade_reals("hd-bullh ", bull_height_got, bull_height_want, F64.from_bits(4427486594234968593)))
	line!(Grade.grade_reals("hd-calves", calves_got, calves_want, 0.0))
	line!(Grade.grade_ints("hd-kind  ", kind_got, kind_want))
	line!(Grade.grade_reals("hd-order ", order_got, order_want, 0.0))
	line!(Grade.grade_reals("hd-space ", spacing_got, spacing_want, 0.0))
	line!(Grade.grade_reals("hd-along ", alongs_got, alongs_want, 1.5))
	line!(Grade.grade_reals("hd-across", acrosses_got, acrosses_want, 1.2))
	Ok({})
}
