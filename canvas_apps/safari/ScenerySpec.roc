# ScenerySpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Grade
import Scenery

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

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "sc-road",
			got: road_got,
			want: road_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "sc-pond",
			got: pond_got,
			want: pond_want,
		}),
		Grade.ints({
			name: "sc-code",
			got: code_got,
			want: code_want,
		}),
		Grade.reals({
			name: "sc-recr",
			got: rec_reals_got,
			want: rec_reals_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "sc-reci",
			got: rec_ints_got,
			want: rec_ints_want,
		}),
		Grade.bools({
			name: "sc-recb",
			got: rec_bools_got,
			want: rec_bools_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
