## At a bend in the road, a safari animal stands on the outside of the bend,
## beyond the guard rail, and its baby stands straight on past the bend, dead
## ahead of a rider coming up to it, off the road the rider turns onto. Both
## face the way the road turns.
import Across
import Along
import Angle
import Billboard
import Distance
import EmojiStills
import Geom

Wildlife :: [].{

	## The safari animals that stand at a bend.
	Animal : [Elephant, Giraffe, Zebra, Rhino]

	## The animal and its baby at `bend`, the bend that ends a segment.
	bend_critters : { animal : Wildlife.Animal, bend : Geom.Bend } -> List(Geom.Placed(Billboard))
	bend_critters = |{ animal, bend }| {
		species = species_of(animal)
		bend_along = Along.at(bend.segment_length)
		{ out_on_outside, facing } =
			match Geom.outer_side(bend.turn) {
				LeftSide => { out_on_outside: Across.left_of_middle, facing: FacesRight }
				RightSide => { out_on_outside: Across.right_of_middle, facing: FacesLeft }
			}
		adult = Billboard.adult_billboard(species, facing)
		clear_of_rail = Geom.road_half_width.plus(adult_rail_buffer)
		across = out_on_outside(clear_of_rail.plus(adult.half_width()))
		[
			{
				road_point: { along: bend_along, across },
				lift: Distance.zero,
				kind: adult,
			},
			{
				road_point: { along: bend_along.plus(baby_beyond), across: Across.middle },
				lift: Distance.zero,
				kind: Billboard.young_billboard(species, facing),
			},
		]
	}
}

## How far beyond the guard rail the grown animal stands.
adult_rail_buffer : Distance
adult_rail_buffer = Distance.metres(1.5)

## How far the baby stands past the bend, straight on along the segment that
## ends there, in the middle of where its road would run.
baby_beyond : Distance
baby_beyond = Distance.metres(14.0)

## The species of a bend's animal.
species_of : Wildlife.Animal -> Billboard.Species
species_of = |animal|
	match animal {
		Elephant => { still: EmojiStills.elephant, adult_height: Distance.metres(2.8) }
		Giraffe => { still: EmojiStills.giraffe, adult_height: Distance.metres(4.5) }
		Zebra => { still: EmojiStills.zebra, adult_height: Distance.metres(1.6) }
		Rhino => { still: EmojiStills.rhino, adult_height: Distance.metres(2.2) }
	}

## An animal and its baby at each of four bends, the first and third turning
## right and the second and fourth left.
four_critters : List(Geom.Placed(Billboard))
four_critters = [
	Wildlife.bend_critters({
		animal: Elephant,
		bend: { segment_length: Distance.metres(100.0), turn: Angle.Turn.degrees(50.0) },
	}),
	Wildlife.bend_critters({
		animal: Giraffe,
		bend: { segment_length: Distance.metres(50.0), turn: Angle.Turn.degrees(-70.0) },
	}),
	Wildlife.bend_critters({
		animal: Zebra,
		bend: { segment_length: Distance.metres(10.0), turn: Angle.Turn.degrees(50.0) },
	}),
	Wildlife.bend_critters({
		animal: Rhino,
		bend: { segment_length: Distance.metres(0.0), turn: Angle.Turn.degrees(-70.0) },
	}),
].join()

expect
	four_critters.map(|critter| critter.road_point.across.to_metres())
		== [
			-4.9,
			0.0,
			5.75,
			0.0,
			-4.3,
			0.0,
			4.6,
			0.0,
		]

expect
	four_critters.map(|critter| critter.road_point.along.to_metres())
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
	four_critters.map(|critter| critter.kind.emoji)
		== [
			EmojiStills.elephant,
			EmojiStills.elephant,
			EmojiStills.giraffe,
			EmojiStills.giraffe,
			EmojiStills.zebra,
			EmojiStills.zebra,
			EmojiStills.rhino,
			EmojiStills.rhino,
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
