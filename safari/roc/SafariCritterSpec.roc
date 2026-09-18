# SafariCritterSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Grade
import ListUtils
import SafariCritter
import Scenery
import Text

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

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
all_four = List.concat(List.concat(List.concat(pair_a, pair_b), pair_c), pair_d)

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
	line!(Text.printed(Grade.grade_bools([19, 34, 73, 31, 21, 13, 19, 13, 18, 14], present_got, present_want)))
	line!(Text.printed(Grade.grade_ints([19, 34, 73, 24, 31, 2, 2, 2, 2], cp_got, cp_want)))
	line!(Text.printed(Grade.grade_reals([19, 34, 73, 20, 13, 17, 29, 20, 14], height_got, height_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([19, 34, 73, 22, 17, 26, 19, 2, 2], dims_got, dims_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([19, 34, 73, 15, 24, 21, 16, 19, 19], across_got, across_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([19, 34, 73, 15, 23, 16, 18, 29, 2], along_got, along_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([19, 34, 73, 24, 20, 2, 2, 2, 2], ch_got, ch_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([19, 34, 73, 24, 24, 31, 2, 2, 2], ccp_got, ccp_want)))
	line!(Text.printed(Grade.grade_bools([19, 34, 73, 28, 15, 24, 13, 2, 2], face_got, face_want)))
	line!(Text.printed(Grade.grade_ints([19, 34, 73, 24, 16, 25, 18, 14, 2], count_got, count_want)))
	Ok({})
}
