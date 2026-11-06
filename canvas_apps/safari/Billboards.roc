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
	Sighting : [InView(Billboards.Billboard), BehindCamera, TooSmall]

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
	sighting = |{ at, height, codepoint, facing }|
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

cow_sighting : { forward : F64, height : F64 } -> Billboards.Sighting
cow_sighting = |{ forward, height }|
	Billboards.sighting({
		at: { right: 2.5, forward },
		height: Distance.metres(height),
		codepoint: 128004,
		facing: FacesRight,
	})

# Which way a sighting went, whatever it carries.
fate_of : Billboards.Sighting -> [Seen, BehindCamera, TooSmall]
fate_of = |sighting|
	match sighting {
		InView(_) => Seen
		BehindCamera => BehindCamera
		TooSmall => TooSmall
	}

# A cow 2.5 m to the right, at each distance and height.
cow_places : List({ forward : F64, height : F64 })
cow_places = [
	{ forward: -5.0, height: 1.0 },
	{ forward: 0.3, height: 1.0 },
	{ forward: 0.4, height: 1.0 },
	{ forward: 0.5, height: 1.0 },
	{ forward: 300.0, height: 1.0 },
	{ forward: 342.0, height: 1.0 },
	{ forward: 343.0, height: 1.0 },
	{ forward: 400.0, height: 1.0 },
	{ forward: 10.0, height: 0.0 },
	{ forward: 50.0, height: 0.9 },
]

expect
	cow_places.map(|place| fate_of(cow_sighting(place)))
		== [
			BehindCamera,
			BehindCamera,
			BehindCamera,
			Seen,
			Seen,
			Seen,
			TooSmall,
			TooSmall,
			TooSmall,
			Seen,
		]

billboard_of : Billboards.Sighting -> Billboards.Billboard
billboard_of = |sighting|
	match sighting {
		InView(billboard) => billboard
		BehindCamera => crash "this critter is in view"
		TooSmall => crash "this critter is in view"
	}

near_cow : Billboards.Billboard
near_cow = billboard_of(cow_sighting({ forward: 0.5, height: 1.0 }))

left_bull : Billboards.Billboard
left_bull = billboard_of(
	Billboards.sighting({
		at: { right: -1.5, forward: 50.0 },
		height: Distance.metres(1.6),
		codepoint: 128002,
		facing: FacesLeft,
	}),
)

expect near_cow.right == 2.5
expect near_cow.forward == 0.5
expect near_cow.height.to_metres() == 1.0
expect left_bull.right == -1.5
expect left_bull.forward == 50.0
expect left_bull.height.to_metres() == 1.6

expect near_cow.codepoint == 128004
expect left_bull.codepoint == 128002
expect near_cow.facing == FacesRight
expect left_bull.facing == FacesLeft

expect Billboards.billboards_in_view(cow_places.map(cow_sighting)).len() == 4
expect Billboards.too_small_count(cow_places.map(cow_sighting)) == 3
expect cow_places.map(cow_sighting).len() == 10

expect Billboards.min_critter_px == 2.0
