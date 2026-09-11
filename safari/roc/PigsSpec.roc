# PigsSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import ListUtils
import Pigs
import Scenery
import Tuple

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

gaze : Scenery.Critter
gaze = Pigs.gaze_pig(1000.0, 2.0)

gaze_got : List(F64)
gaze_got = [gaze.along, gaze.across, gaze.height, Pigs.pig_height, Pigs.pig_dist_before_end, Pigs.gaze_pig_along_offset]

gaze_got_want : List(F64)
gaze_got_want = [942.0, 12.0, 1.1, 1.1, 60.0, 2.0]

gaze_kind_got : List(I64)
gaze_kind_got = [gaze.codepoint, Pigs.pig_cp, Pigs.pig_novelty_count, Pigs.big_herd_cols, Pigs.big_herd_rows]

gaze_kind_want : List(I64)
gaze_kind_want = [128022, 128022, 2, 7, 7]

gaze_face_got : List(Bool)
gaze_face_got = [gaze.face_right]

gaze_face_want : List(Bool)
gaze_face_want = [False]

herd : List(Scenery.Critter)
herd = Pigs.fill_pig_herd(1000.0)

herd_count_got : List(I64)
herd_count_got = [U64.to_i64_wrap(List.len(herd)), U64.to_i64_wrap(List.len(Pigs.fill_pig_herd(500.0)))]

herd_count_want : List(I64)
herd_count_want = [49, 49]

along_of : I64, I64 -> F64
along_of = |r, c| (List.get(herd, I64.to_u64_wrap(((r * 7) + c))) ?? crash("list-at out of range")).along

row_alongs : I64 -> List(F64)
row_alongs = |r| [along_of(r, 0), along_of(r, 1), along_of(r, 2), along_of(r, 3), along_of(r, 4), along_of(r, 5), along_of(r, 6)]

herd_along_got : List(F64)
herd_along_got = List.concat(List.concat(row_alongs(0), row_alongs(3)), row_alongs(6))

herd_along_want : List(F64)
herd_along_want = [934.0, 938.0, 942.0, 946.0, 950.0, 954.0, 958.0, 952.0, 956.0, 960.0, 964.0, 968.0, 972.0, 976.0, 970.0, 974.0, 978.0, 982.0, 986.0, 990.0, 994.0]

herd_across_got : List(F64)
herd_across_got = [(List.get(herd, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(6)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(7)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(13)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(14)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(21)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(28)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(35)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(42)) ?? crash("list-at out of range")).across, (List.get(herd, I64.to_u64_wrap(48)) ?? crash("list-at out of range")).across]

herd_across_want : List(F64)
herd_across_want = [12.0, 12.0, 18.0, 18.0, 24.0, 30.0, 36.0, 42.0, 48.0, 48.0]

herd_kind_got : List(I64)
herd_kind_got = [(List.get(herd, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).codepoint, (List.get(herd, I64.to_u64_wrap(48)) ?? crash("list-at out of range")).codepoint]

herd_kind_want : List(I64)
herd_kind_want = [128022, 128022]

row : List(Scenery.Critter)
row = Pigs.fill_pig_row(1000.0)

row_count_got : List(I64)
row_count_got = [U64.to_i64_wrap(List.len(row)), U64.to_i64_wrap(List.len(Pigs.pig_row_front)), U64.to_i64_wrap(List.len(Pigs.pig_row_back))]

row_count_want : List(I64)
row_count_want = [10, 4, 6]

row_along_got : List(F64)
row_along_got = ListUtils.list_map(lam_0, row)

row_along_want : List(F64)
row_along_want = [934.0, 938.0, 942.0, 946.0, 930.0, 934.0, 938.0, 942.0, 946.0, 950.0]

row_across_got : List(F64)
row_across_got = ListUtils.list_map(lam_1, row)

row_across_want : List(F64)
row_across_want = [12.0, 12.0, 12.0, 12.0, 18.0, 18.0, 18.0, 18.0, 18.0, 18.0]

offsets_got : List(F64)
offsets_got = List.concat(List.concat(Pigs.pig_row_front, Pigs.pig_row_back), [Pigs.pig_back_row_offset, Pigs.pig_herd_first_col, Pigs.pig_col_spacing, Pigs.pig_row_depth, Pigs.pig_jitter_along, Pigs.pig_jitter_across])

offsets_want : List(F64)
offsets_want = [(-6.0), (-2.0), 2.0, 6.0, (-10.0), (-6.0), (-2.0), 2.0, 6.0, 10.0, 6.0, (-6.0), 4.0, 6.0, 1.2, 1.0]

eq_tup2 : Tuple.Tup2(a, b), Tuple.Tup2(a, b) -> Bool
eq_tup2 = |ex, ey| (match ex {
	MkTup2(exf0, exf1) => (match ey {
		MkTup2(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

eq_tup3 : Tuple.Tup3(a, b, c), Tuple.Tup3(a, b, c) -> Bool
eq_tup3 = |ex, ey| (match ex {
	MkTup3(exf0, exf1, exf2) => (match ey {
		MkTup3(eyf0, eyf1, eyf2) => (((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2))
		_ => False
	})
})

eq_tup4 : Tuple.Tup4(a, b, c, d), Tuple.Tup4(a, b, c, d) -> Bool
eq_tup4 = |ex, ey| (match ex {
	MkTup4(exf0, exf1, exf2, exf3) => (match ey {
		MkTup4(eyf0, eyf1, eyf2, eyf3) => ((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3))
		_ => False
	})
})

eq_tup5 : Tuple.Tup5(a, b, c, d, e), Tuple.Tup5(a, b, c, d, e) -> Bool
eq_tup5 = |ex, ey| (match ex {
	MkTup5(exf0, exf1, exf2, exf3, exf4) => (match ey {
		MkTup5(eyf0, eyf1, eyf2, eyf3, eyf4) => (((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3)) and (exf4 == eyf4))
		_ => False
	})
})

eq_scheme : Scenery.Scheme, Scenery.Scheme -> Bool
eq_scheme = |ex, ey| (match ex {
	AllGreen => (match ey {
		AllGreen => True
		_ => False
	})
	YellowGreen => (match ey {
		YellowGreen => True
		_ => False
	})
	RedGreen => (match ey {
		RedGreen => True
		_ => False
	})
})

eq_creature : Scenery.Creature, Scenery.Creature -> Bool
eq_creature = |ex, ey| (match ex {
	NoCreature => (match ey {
		NoCreature => True
		_ => False
	})
	Elephant => (match ey {
		Elephant => True
		_ => False
	})
	Giraffe => (match ey {
		Giraffe => True
		_ => False
	})
	Zebra => (match ey {
		Zebra => True
		_ => False
	})
	Rhino => (match ey {
		Rhino => True
		_ => False
	})
	DuckPond => (match ey {
		DuckPond => True
		_ => False
	})
})

lam_0 : Scenery.Critter -> F64
lam_0 = |p| p.along

lam_1 : Scenery.Critter -> F64
lam_1 = |p| p.across

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("pg-gaze  ", gaze_got, gaze_got_want, 0.0))
	line!(Grade.grade_ints("pg-kind  ", gaze_kind_got, gaze_kind_want))
	line!(Grade.grade_bools("pg-face  ", gaze_face_got, gaze_face_want))
	line!(Grade.grade_ints("pg-nherd ", herd_count_got, herd_count_want))
	line!(Grade.grade_ints("pg-hkind ", herd_kind_got, herd_kind_want))
	line!(Grade.grade_ints("pg-nrow  ", row_count_got, row_count_want))
	line!(Grade.grade_reals("pg-rowa  ", row_along_got, row_along_want, 0.0))
	line!(Grade.grade_reals("pg-rowx  ", row_across_got, row_across_want, 0.0))
	line!(Grade.grade_reals("pg-offs  ", offsets_got, offsets_want, 0.0))
	line!(Grade.grade_reals("pg-herda ", herd_along_got, herd_along_want, 1.2))
	line!(Grade.grade_reals("pg-herdx ", herd_across_got, herd_across_want, 1.0))
	Ok({})
}
