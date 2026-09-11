# ScenerySpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import Scenery
import Tuple

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

road_got : List(F64)
road_got = [Scenery.lane_width, Scenery.herd_road_offset]

road_want : List(F64)
road_want = [4.0, 10.0]

pond_got : List(Bool)
pond_got = [Scenery.is_pond(DuckPond), Scenery.is_pond(NoCreature), Scenery.is_pond(Elephant), Scenery.is_pond(Giraffe), Scenery.is_pond(Zebra), Scenery.is_pond(Rhino)]

pond_want : List(Bool)
pond_want = [True, False, False, False, False, False]

scheme_code : Scenery.Scheme -> I64
scheme_code = |s| (match s {
	AllGreen => 0
	YellowGreen => 1
	RedGreen => 2
})

creature_code : Scenery.Creature -> I64
creature_code = |c| (match c {
	NoCreature => 0
	Elephant => 1
	Giraffe => 2
	Zebra => 3
	Rhino => 4
	DuckPond => 5
})

code_got : List(I64)
code_got = [scheme_code(AllGreen), scheme_code(YellowGreen), scheme_code(RedGreen), creature_code(NoCreature), creature_code(Elephant), creature_code(Giraffe), creature_code(Zebra), creature_code(Rhino), creature_code(DuckPond)]

code_want : List(I64)
code_want = [0, 1, 2, 0, 1, 2, 3, 4, 5]

a_tree : Scenery.Tree
a_tree = { along: 120.5, across: 3.25, color: 9066271, height: 7.75 }

a_critter : Scenery.Critter
a_critter = { along: 250.5, across: (-6.5), codepoint: 128004, height: 1.375, face_right: True }

rec_reals_got : List(F64)
rec_reals_got = [a_tree.along, a_tree.across, a_tree.height, a_critter.along, a_critter.across, a_critter.height]

rec_reals_want : List(F64)
rec_reals_want = [120.5, 3.25, 7.75, 250.5, (-6.5), 1.375]

rec_ints_got : List(I64)
rec_ints_got = [a_tree.color, a_critter.codepoint]

rec_ints_want : List(I64)
rec_ints_want = [9066271, 128004]

rec_bools_got : List(Bool)
rec_bools_got = [a_critter.face_right]

rec_bools_want : List(Bool)
rec_bools_want = [True]

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

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("sc-road", road_got, road_want, 0.0))
	line!(Grade.grade_bools("sc-pond", pond_got, pond_want))
	line!(Grade.grade_ints("sc-code", code_got, code_want))
	line!(Grade.grade_reals("sc-recr", rec_reals_got, rec_reals_want, 0.0))
	line!(Grade.grade_ints("sc-reci", rec_ints_got, rec_ints_want))
	line!(Grade.grade_bools("sc-recb", rec_bools_got, rec_bools_want))
	Ok({})
}
