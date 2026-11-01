# SafariCritterSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Grade
import ListUtils
import SafariCritter
import Scenery

present_got : List(Bool)
present_got = [SafariCritter.species_of(Elephant).present, SafariCritter.species_of(Giraffe).present, SafariCritter.species_of(Zebra).present, SafariCritter.species_of(Rhino).present, SafariCritter.species_of(DuckPond).present, SafariCritter.species_of(NoCreature).present]

present_want : List(Bool)
present_want = [True, True, True, True, False, False]

cp_got : List(I64)
cp_got = [SafariCritter.species_of(Elephant).cp, SafariCritter.species_of(Giraffe).cp, SafariCritter.species_of(Zebra).cp, SafariCritter.species_of(Rhino).cp, SafariCritter.species_of(DuckPond).cp, SafariCritter.species_of(NoCreature).cp]

cp_want : List(I64)
cp_want = [128024, 129426, 129427, 129423, 0, 0]

height_got : List(F64)
height_got = [SafariCritter.species_of(Elephant).adult_h, SafariCritter.species_of(Giraffe).adult_h, SafariCritter.species_of(Zebra).adult_h, SafariCritter.species_of(Rhino).adult_h, SafariCritter.species_of(DuckPond).adult_h]

height_want : List(F64)
height_want = [2.8, 4.5, 1.6, 2.2, 0.0]

dims_got : List(F64)
dims_got = [SafariCritter.adult_rail_buffer, SafariCritter.baby_ratio, SafariCritter.baby_beyond]

dims_want : List(F64)
dims_want = [1.5, 0.5, 14.0]

pair_a : List(Scenery.Critter)
pair_a = SafariCritter.corner_critters(Elephant, 100.0, True, 2.0)

pair_b : List(Scenery.Critter)
pair_b = SafariCritter.corner_critters(Giraffe, 50.0, False, 2.0)

pair_c : List(Scenery.Critter)
pair_c = SafariCritter.corner_critters(Zebra, 10.0, True, 2.5)

pair_d : List(Scenery.Critter)
pair_d = SafariCritter.corner_critters(Rhino, 0.0, False, 2.0)

all_four : List(Scenery.Critter)
all_four = List.join([pair_a, pair_b, pair_c, pair_d])

across_got : List(F64)
across_got = ListUtils.list_map(lam_0, all_four)

across_want : List(F64)
across_want = [(-4.9), 0.0, 5.75, 0.0, (-4.8), 0.0, 4.6, 0.0]

along_got : List(F64)
along_got = ListUtils.list_map(lam_1, all_four)

along_want : List(F64)
along_want = [100.0, 114.0, 50.0, 64.0, 10.0, 24.0, 0.0, 14.0]

ch_got : List(F64)
ch_got = ListUtils.list_map(lam_2, all_four)

ch_want : List(F64)
ch_want = [2.8, 1.4, 4.5, 2.25, 1.6, 0.8, 2.2, 1.1]

ccp_got : List(I64)
ccp_got = ListUtils.list_map(lam_3, all_four)

ccp_want : List(I64)
ccp_want = [128024, 128024, 129426, 129426, 129427, 129427, 129423, 129423]

face_got : List(Bool)
face_got = ListUtils.list_map(lam_4, all_four)

face_want : List(Bool)
face_want = [True, True, False, False, True, True, False, False]

count_got : List(I64)
count_got = [U64.to_i64_wrap(List.len(pair_a)), U64.to_i64_wrap(List.len(SafariCritter.corner_critters(DuckPond, 100.0, True, 2.0))), U64.to_i64_wrap(List.len(SafariCritter.corner_critters(NoCreature, 100.0, True, 2.0)))]

count_want : List(I64)
count_want = [2, 0, 0]

lam_0 : Scenery.Critter -> F64
lam_0 = |c| c.across

lam_1 : Scenery.Critter -> F64
lam_1 = |c| c.along

lam_2 : Scenery.Critter -> F64
lam_2 = |c| c.height

lam_3 : Scenery.Critter -> I64
lam_3 = |c| c.codepoint

lam_4 : Scenery.Critter -> Bool
lam_4 = |c| c.face_right

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.bools({
			name: "sk-present",
			got: present_got,
			want: present_want,
		}),
		Grade.ints({
			name: "sk-cp    ",
			got: cp_got,
			want: cp_want,
		}),
		Grade.reals({
			name: "sk-height",
			got: height_got,
			want: height_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "sk-dims  ",
			got: dims_got,
			want: dims_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "sk-across",
			got: across_got,
			want: across_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "sk-along ",
			got: along_got,
			want: along_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "sk-ch    ",
			got: ch_got,
			want: ch_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "sk-ccp   ",
			got: ccp_got,
			want: ccp_want,
		}),
		Grade.bools({
			name: "sk-face  ",
			got: face_got,
			want: face_want,
		}),
		Grade.ints({
			name: "sk-count ",
			got: count_got,
			want: count_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
