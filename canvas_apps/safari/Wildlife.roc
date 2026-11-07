## At a bend in the road, a safari animal stands on the outside of the bend,
## beyond the guard rail, and its baby stands straight on past the bend, dead
## ahead of a rider coming up to it, off the road the rider turns onto. Both
## face the way the road turns.
import Across
import Along
import Billboard
import Distance
import EmojiStills
import Geom

Wildlife :: [].{

	## The safari animals that stand at a bend.
	Animal : [Elephant, Giraffe, Zebra, Rhino]

	## The animal and its baby at `bend`, the bend that ends a segment.
	bend_billboards : { animal : Wildlife.Animal, bend : Geom.Bend } -> List(Geom.Placed(Billboard))
	bend_billboards = |{ animal, bend }| {
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
		Elephant => { emoji: EmojiStills.elephant, adult_height: Distance.metres(2.8) }
		Giraffe => { emoji: EmojiStills.giraffe, adult_height: Distance.metres(4.5) }
		Zebra => { emoji: EmojiStills.zebra, adult_height: Distance.metres(1.6) }
		Rhino => { emoji: EmojiStills.rhino, adult_height: Distance.metres(2.2) }
	}
