## At a corner where the road turns, a safari animal stands on the outside of
## the bend, beyond the guard rail, and its baby stands in the middle of the
## road a little past the corner. Both face the way the road turns.
import Angle
import Scenery

SafariCritter :: [].{

	## A safari animal: its emoji, and how tall a grown one stands, in metres.
	Species : { codepoint : I64, adult_height : F64 }

	## How far beyond the guard rail the grown animal stands.
	adult_rail_buffer : F64
	adult_rail_buffer = 1.5

	## A baby's height, as a fraction of its parent's.
	baby_ratio : F64
	baby_ratio = 0.5

	## How far past the corner the baby stands.
	baby_beyond : F64
	baby_beyond = 14.0

	## The animal a corner's creature is. A pond's ducks are placed with the
	## pond, not here.
	species_of : Scenery.Creature -> [Species(SafariCritter.Species), NoSpecies]
	species_of = |creature|
		match creature {
			Elephant => Species({ codepoint: 128024, adult_height: 2.8 })
			Giraffe => Species({ codepoint: 129426, adult_height: 4.5 })
			Zebra => Species({ codepoint: 129427, adult_height: 1.6 })
			Rhino => Species({ codepoint: 129423, adult_height: 2.2 })
			DuckPond => NoSpecies
			NoCreature => NoSpecies
		}

	## The animal and its baby at a corner `corner_along` metres along its
	## segment, on a road `lane_half_width` metres either side of its middle.
	corner_critters : {
		creature : Scenery.Creature,
		corner_along : F64,
		turn : Angle.Turn,
		lane_half_width : F64,
	} -> List(Scenery.Critter)
	corner_critters = |
		{
			creature,
			corner_along,
			turn,
			lane_half_width,
		},
	|
		match species_of(creature) {
			NoSpecies => []
			Species(species) => {
				{ inward, face_right } =
					if turn.is_right() {
						{ inward: 1.0, face_right: True }
					} else {
						{ inward: (0.0 - 1.0), face_right: False }
					}
				clear_of_rail = (lane_half_width + adult_rail_buffer)
				out_from_middle = (clear_of_rail + (species.adult_height / 2.0))
				[
					{
						along: corner_along,
						across: ((0.0 - inward) * out_from_middle),
						codepoint: species.codepoint,
						height: species.adult_height,
						face_right,
					},
					{
						along: (corner_along + baby_beyond),
						across: 0.0,
						codepoint: species.codepoint,
						height: (species.adult_height * baby_ratio),
						face_right,
					},
				]
			}
		}
}

expect SafariCritter.species_of(Elephant) == Species({ codepoint: 128024, adult_height: 2.8 })
expect SafariCritter.species_of(Giraffe) == Species({ codepoint: 129426, adult_height: 4.5 })
expect SafariCritter.species_of(Zebra) == Species({ codepoint: 129427, adult_height: 1.6 })
expect SafariCritter.species_of(Rhino) == Species({ codepoint: 129423, adult_height: 2.2 })
expect SafariCritter.species_of(DuckPond) == NoSpecies
expect SafariCritter.species_of(NoCreature) == NoSpecies

expect SafariCritter.adult_rail_buffer == 1.5
expect SafariCritter.baby_ratio == 0.5
expect SafariCritter.baby_beyond == 14.0

## An animal and its baby at each of four corners, the first and third turning
## right and the second and fourth left.
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

expect
	all_four.map(|critter| critter.across)
		== [
			-4.9,
			0.0,
			5.75,
			0.0,
			-4.8,
			0.0,
			4.6,
			0.0,
		]

expect
	all_four.map(|critter| critter.along)
		== [
			100.0,
			114.0,
			50.0,
			64.0,
			10.0,
			24.0,
			0.0,
			14.0,
		]

expect
	all_four.map(|critter| critter.height)
		== [
			2.8,
			1.4,
			4.5,
			2.25,
			1.6,
			0.8,
			2.2,
			1.1,
		]

expect
	all_four.map(|critter| critter.codepoint)
		== [
			128024,
			128024,
			129426,
			129426,
			129427,
			129427,
			129423,
			129423,
		]

expect
	all_four.map(|critter| critter.face_right)
		== [
			True,
			True,
			False,
			False,
			True,
			True,
			False,
			False,
		]

## How many critters a right turn's corner has for this creature.
corner_count : Scenery.Creature -> U64
corner_count = |creature|
	SafariCritter.corner_critters({
		creature,
		corner_along: 100.0,
		turn: Angle.Turn.degrees(50.0),
		lane_half_width: 2.0,
	}).len()

expect corner_count(Elephant) == 2
expect corner_count(DuckPond) == 0
expect corner_count(NoCreature) == 0
