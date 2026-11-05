## These are SafariCritter's checks: each creature's species, and where a
## corner's animal and its baby stand, for each way the road turns.
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Grade
import SafariCritter
import Scenery

animals : List(Scenery.Creature)
animals = [Elephant, Giraffe, Zebra, Rhino]

species : Scenery.Creature -> SafariCritter.Species
species = |creature|
	match SafariCritter.species_of(creature) {
		Species(found) => found
		NoSpecies => crash "SafariCritterSpec: a safari animal has a species"
	}

has_species : Scenery.Creature -> Bool
has_species = |creature|
	match SafariCritter.species_of(creature) {
		Species(_) => True
		NoSpecies => False
	}

present_got : List(Bool)
present_got = [Elephant, Giraffe, Zebra, Rhino, DuckPond, NoCreature].map(has_species)

present_want : List(Bool)
present_want = [True, True, True, True, False, False]

cp_got : List(I64)
cp_got = animals.map(|creature| species(creature).codepoint)

cp_want : List(I64)
cp_want = [128024, 129426, 129427, 129423]

height_got : List(F64)
height_got = animals.map(|creature| species(creature).adult_height)

height_want : List(F64)
height_want = [2.8, 4.5, 1.6, 2.2]

dims_got : List(F64)
dims_got = [
	SafariCritter.adult_rail_buffer,
	SafariCritter.baby_ratio,
	SafariCritter.baby_beyond,
]

dims_want : List(F64)
dims_want = [1.5, 0.5, 14.0]

all_four : List(Scenery.Critter)
all_four = List.join([
	SafariCritter.corner_critters({
		creature: Elephant,
		corner_along: 100.0,
		turn: Angle.Turn.degrees(50.0),
		lane_half_width: 2.0,
	}),
	SafariCritter.corner_critters({
		creature: Giraffe,
		corner_along: 50.0,
		turn: Angle.Turn.degrees(-70.0),
		lane_half_width: 2.0,
	}),
	SafariCritter.corner_critters({
		creature: Zebra,
		corner_along: 10.0,
		turn: Angle.Turn.degrees(50.0),
		lane_half_width: 2.5,
	}),
	SafariCritter.corner_critters({
		creature: Rhino,
		corner_along: 0.0,
		turn: Angle.Turn.degrees(-70.0),
		lane_half_width: 2.0,
	}),
])

across_got : List(F64)
across_got = all_four.map(|critter| critter.across)

across_want : List(F64)
across_want = [
	(-4.9),
	0.0,
	5.75,
	0.0,
	(-4.8),
	0.0,
	4.6,
	0.0,
]

along_got : List(F64)
along_got = all_four.map(|critter| critter.along)

along_want : List(F64)
along_want = [100.0, 114.0, 50.0, 64.0, 10.0, 24.0, 0.0, 14.0]

ch_got : List(F64)
ch_got = all_four.map(|critter| critter.height)

ch_want : List(F64)
ch_want = [2.8, 1.4, 4.5, 2.25, 1.6, 0.8, 2.2, 1.1]

ccp_got : List(I64)
ccp_got = all_four.map(|critter| critter.codepoint)

ccp_want : List(I64)
ccp_want = [128024, 128024, 129426, 129426, 129427, 129427, 129423, 129423]

face_got : List(Bool)
face_got = all_four.map(|critter| critter.face_right)

face_want : List(Bool)
face_want = [True, True, False, False, True, True, False, False]

corner_count : Scenery.Creature -> I64
corner_count = |creature|
	SafariCritter.corner_critters({
		creature,
		corner_along: 100.0,
		turn: Angle.Turn.degrees(50.0),
		lane_half_width: 2.0,
	}).len().to_i64_wrap()

count_got : List(I64)
count_got = [
	corner_count(Elephant),
	corner_count(DuckPond),
	corner_count(NoCreature),
]

count_want : List(I64)
count_want = [2, 0, 0]

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
