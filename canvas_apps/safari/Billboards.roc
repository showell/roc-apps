## A billboard is a critter in the rider's view, ready to draw: where it
## stands, how tall it is, which emoji it is and which way it faces.
## Billboards decides which critters become billboards: one behind the camera,
## or too small to see, is left out.
import Distance
import Geom
import Lens

Billboards :: [].{

	## Which way a critter faces on screen.
	Facing : [FacesLeft, FacesRight]

	Billboard : {
		right : F64,
		forward : F64,
		height : Distance,
		codepoint : I64,
		facing : Billboards.Facing,
	}

	## What became of a critter placed in the rider's view.
	Sighting : [
		InView(Billboards.Billboard),
		BehindCamera,
		TooSmall,
	]

	## A critter shorter than this many pixels is too small to draw.
	min_critter_px : F64
	min_critter_px = 2.0

	## A critter of `height` at `at` in the rider's view.
	sighting : {
		at : Geom.RiderPoint,
		height : Distance,
		codepoint : I64,
		facing : Billboards.Facing,
	} -> Billboards.Sighting
	sighting = |
		{
			at,
			height,
			codepoint,
			facing,
		},
	|
		if at.forward <= Geom.near_plane {
			BehindCamera
		} else if ((height.to_metres() / at.forward) * Lens.focal) < min_critter_px {
			TooSmall
		} else {
			InView({
				right: at.right,
				forward: at.forward,
				height,
				codepoint,
				facing,
			})
		}

	## The billboards of the critters in view, in order.
	billboards_in_view : List(Billboards.Sighting) -> List(Billboards.Billboard)
	billboards_in_view = |sightings|
		sightings.join_map(
			|critter|
				match critter {
					InView(billboard) => [billboard]
					BehindCamera => []
					TooSmall => []
				},
		)

	## How many critters were too small to draw.
	too_small_count : List(Billboards.Sighting) -> I64
	too_small_count = |sightings|
		sightings
			.count_if(
				|critter|
					match critter {
						TooSmall => True
						InView(_) => False
						BehindCamera => False
					},
			)
			.to_i64_wrap()
}
