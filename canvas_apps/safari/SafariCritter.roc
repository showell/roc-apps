## At a bend in the road, a safari animal stands on the outside of
## the bend, beyond the guard rail, and its baby stands in the middle of the
## road a little past the bend. Both face the way the road turns.
import Across
import Along
import Angle
import Distance
import Scenery

SafariCritter :: [].{

	## A safari animal: its emoji, and how tall a grown one stands.
	Species : { codepoint : I64, adult_height : Distance }

	## How far beyond the guard rail the grown animal stands.
	adult_rail_buffer : Distance
	adult_rail_buffer = Distance.metres(1.5)

	## A baby's height, as a fraction of its parent's.
	baby_ratio : F64
	baby_ratio = 0.5

	## How far past the bend the baby stands.
	baby_beyond : Distance
	baby_beyond = Distance.metres(14.0)

	## The animal a bend's creature is. A pond's ducks are placed with the
	## pond, not here.
	species_of : Scenery.Creature -> [Species(SafariCritter.Species), NoSpecies]
	species_of = |creature|
		match creature {
			Elephant => Species({ codepoint: 128024, adult_height: Distance.metres(2.8) })
			Giraffe => Species({ codepoint: 129426, adult_height: Distance.metres(4.5) })
			Zebra => Species({ codepoint: 129427, adult_height: Distance.metres(1.6) })
			Rhino => Species({ codepoint: 129423, adult_height: Distance.metres(2.2) })
			DuckPond => NoSpecies
			NoCreature => NoSpecies
		}

	## The animal and its baby at a bend at `bend_along` on its segment, on
	## a road `lane_half_width` either side of its middle.
	bend_critters : {
		creature : Scenery.Creature,
		bend_along : Along,
		turn : Angle.Turn,
		lane_half_width : Distance,
	} -> List(Scenery.Critter)
	bend_critters = |{ creature, bend_along, turn, lane_half_width }|
		match species_of(creature) {
			NoSpecies => []
			Species(species) => {
				{ inward, face_right } =
					if turn.is_right() {
						{ inward: 1.0, face_right: True }
					} else {
						{ inward: (0.0 - 1.0), face_right: False }
					}
				clear_of_rail = lane_half_width.plus(adult_rail_buffer)
				out_from_middle = clear_of_rail.plus(species.adult_height.divided_by(2.0))
				[
					{
						along: bend_along,
						across: Across.right_of_middle(out_from_middle.times(0.0 - inward)),
						codepoint: species.codepoint,
						height: species.adult_height,
						face_right,
					},
					{
						along: bend_along.plus(baby_beyond),
						across: Across.middle,
						codepoint: species.codepoint,
						height: species.adult_height.times(baby_ratio),
						face_right,
					},
				]
			}
		}
}

expect
	SafariCritter.species_of(Elephant)
		== Species({ codepoint: 128024, adult_height: Distance.metres(2.8) })

expect
	SafariCritter.species_of(Giraffe)
		== Species({ codepoint: 129426, adult_height: Distance.metres(4.5) })

expect
	SafariCritter.species_of(Zebra)
		== Species({ codepoint: 129427, adult_height: Distance.metres(1.6) })

expect
	SafariCritter.species_of(Rhino)
		== Species({ codepoint: 129423, adult_height: Distance.metres(2.2) })

expect SafariCritter.species_of(DuckPond) == NoSpecies
expect SafariCritter.species_of(NoCreature) == NoSpecies

expect SafariCritter.adult_rail_buffer.to_metres() == 1.5
expect SafariCritter.baby_ratio == 0.5
expect SafariCritter.baby_beyond.to_metres() == 14.0

## An animal and its baby at each of four bends, the first and third turning
## right and the second and fourth left.
all_four : List(Scenery.Critter)
all_four = List.join([
	SafariCritter.bend_critters({
		creature: Elephant,
		bend_along: Along.metres(100.0),
		turn: Angle.Turn.degrees(50.0),
		lane_half_width: Distance.metres(2.0),
	}),
	SafariCritter.bend_critters({
		creature: Giraffe,
		bend_along: Along.metres(50.0),
		turn: Angle.Turn.degrees(-70.0),
		lane_half_width: Distance.metres(2.0),
	}),
	SafariCritter.bend_critters({
		creature: Zebra,
		bend_along: Along.metres(10.0),
		turn: Angle.Turn.degrees(50.0),
		lane_half_width: Distance.metres(2.5),
	}),
	SafariCritter.bend_critters({
		creature: Rhino,
		bend_along: Along.metres(0.0),
		turn: Angle.Turn.degrees(-70.0),
		lane_half_width: Distance.metres(2.0),
	}),
])

expect
	all_four.map(|critter| critter.across.to_metres())
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
	all_four.map(|critter| critter.along.to_metres())
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
	all_four.map(|critter| critter.height.to_metres())
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

## How many critters a right bend has for this creature.
bend_count : Scenery.Creature -> U64
bend_count = |creature|
	SafariCritter.bend_critters({
		creature,
		bend_along: Along.metres(100.0),
		turn: Angle.Turn.degrees(50.0),
		lane_half_width: Distance.metres(2.0),
	}).len()

expect bend_count(Elephant) == 2
expect bend_count(DuckPond) == 0
expect bend_count(NoCreature) == 0
