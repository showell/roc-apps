## At a corner where the road turns, a safari animal stands on the outside of
## the bend, beyond the guard rail, and its baby stands in the middle of the
## road a little past the corner. Both face the way the road turns.
import Angle
import Distance
import Scenery

SafariCritter :: [].{

	## A safari animal: its emoji, and how tall a grown one stands.
	Species : { codepoint : I64, adult_height : Distance }

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
			Elephant => Species({ codepoint: 128024, adult_height: Distance.metres(2.8) })
			Giraffe => Species({ codepoint: 129426, adult_height: Distance.metres(4.5) })
			Zebra => Species({ codepoint: 129427, adult_height: Distance.metres(1.6) })
			Rhino => Species({ codepoint: 129423, adult_height: Distance.metres(2.2) })
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
				out_from_middle = (clear_of_rail + (species.adult_height.to_metres() / 2.0))
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
						height: species.adult_height.times(baby_ratio),
						face_right,
					},
				]
			}
		}
}
