## At a bend in the road, a safari animal stands on the outside of
## the bend, beyond the guard rail, and its baby stands in the middle of the
## road a little past the bend. Both face the way the road turns.
import Across
import Along
import Angle
import Billboard
import Distance
import Fraction
import Geom
import Scenery

Wildlife :: [].{

	## A safari animal: its emoji, and how tall a grown one stands.
	Species : { codepoint : U32, adult_height : Distance }

	## How far beyond the guard rail the grown animal stands.
	adult_rail_buffer : Distance
	adult_rail_buffer = Distance.metres(1.5)

	## A baby's height, as a fraction of its parent's.
	baby_ratio : Fraction
	baby_ratio = Fraction.of(0.5)

	## How far past the bend the baby stands.
	baby_beyond : Distance
	baby_beyond = Distance.metres(14.0)

	## The species of a bend's animal.
	species_of : Scenery.Animal -> Wildlife.Species
	species_of = |animal|
		match animal {
			Elephant => { codepoint: 128024, adult_height: Distance.metres(2.8) }
			Giraffe => { codepoint: 129426, adult_height: Distance.metres(4.5) }
			Zebra => { codepoint: 129427, adult_height: Distance.metres(1.6) }
			Rhino => { codepoint: 129423, adult_height: Distance.metres(2.2) }
		}

	## The animal and its baby at a bend at `bend_along` on its segment, on
	## a road `road_half_width` either side of its middle.
	bend_critters : {
		bend_life : Scenery.BendLife,
		bend_along : Along,
		turn : Angle.Turn,
		road_half_width : Distance,
	} -> List(Geom.Placed(Billboard))
	bend_critters = |{ bend_life, bend_along, turn, road_half_width }|
		match bend_life {
			Quiet | DuckPond => []
			Animal(animal) => {
				species = species_of(animal)
				{ inward, facing } =
					if turn.is_right() {
						{ inward: 1.0, facing: FacesRight }
					} else {
						{ inward: -1.0, facing: FacesLeft }
					}
				clear_of_rail = road_half_width.plus(adult_rail_buffer)
				out_from_middle = clear_of_rail.plus(species.adult_height.divided_by(2.0))
				[
					{
						along: bend_along,
						across: Across.right_of_middle(out_from_middle.times(-inward)),
						kind: {
							codepoint: species.codepoint,
							height: species.adult_height,
							facing,
						},
					},
					{
						along: bend_along.plus(baby_beyond),
						across: Across.middle,
						kind: {
							codepoint: species.codepoint,
							height: species.adult_height.times(baby_ratio.to_f64()),
							facing,
						},
					},
				]
			}
		}
}

expect
	Wildlife.species_of(Elephant)
		== { codepoint: 128024, adult_height: Distance.metres(2.8) }

expect
	Wildlife.species_of(Giraffe)
		== { codepoint: 129426, adult_height: Distance.metres(4.5) }

expect
	Wildlife.species_of(Zebra)
		== { codepoint: 129427, adult_height: Distance.metres(1.6) }

expect
	Wildlife.species_of(Rhino)
		== { codepoint: 129423, adult_height: Distance.metres(2.2) }

expect Wildlife.adult_rail_buffer.to_metres() == 1.5
expect Wildlife.baby_ratio.to_f64() == 0.5
expect Wildlife.baby_beyond.to_metres() == 14.0

## An animal and its baby at each of four bends, the first and third turning
## right and the second and fourth left.
four_critters : List(Geom.Placed(Billboard))
four_critters = [
	Wildlife.bend_critters({
		bend_life: Animal(Elephant),
		bend_along: Along.metres(100.0),
		turn: Angle.Turn.degrees(50.0),
		road_half_width: Distance.metres(2.0),
	}),
	Wildlife.bend_critters({
		bend_life: Animal(Giraffe),
		bend_along: Along.metres(50.0),
		turn: Angle.Turn.degrees(-70.0),
		road_half_width: Distance.metres(2.0),
	}),
	Wildlife.bend_critters({
		bend_life: Animal(Zebra),
		bend_along: Along.metres(10.0),
		turn: Angle.Turn.degrees(50.0),
		road_half_width: Distance.metres(2.5),
	}),
	Wildlife.bend_critters({
		bend_life: Animal(Rhino),
		bend_along: Along.metres(0.0),
		turn: Angle.Turn.degrees(-70.0),
		road_half_width: Distance.metres(2.0),
	}),
].join()

expect
	four_critters.map(|critter| critter.across.to_metres())
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
	four_critters.map(|critter| critter.along.to_metres())
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
	four_critters.map(|critter| critter.kind.height.to_metres())
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
	four_critters.map(|critter| critter.kind.codepoint)
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
	four_critters.map(|critter| critter.kind.facing)
		== [
			FacesRight,
			FacesRight,
			FacesLeft,
			FacesLeft,
			FacesRight,
			FacesRight,
			FacesLeft,
			FacesLeft,
		]

## How many critters a right bend has for this life.
bend_count : Scenery.BendLife -> U64
bend_count = |bend_life|
	Wildlife.bend_critters({
		bend_life,
		bend_along: Along.metres(100.0),
		turn: Angle.Turn.degrees(50.0),
		road_half_width: Distance.metres(2.0),
	}).len()

expect bend_count(Animal(Elephant)) == 2
expect bend_count(DuckPond) == 0
expect bend_count(Quiet) == 0
