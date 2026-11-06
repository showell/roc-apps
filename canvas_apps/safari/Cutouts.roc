## A cutout is a critter in the rider's view, ready to draw: where it
## stands, how tall it is, which emoji it is and which way it faces.
## Cutouts decides which critters become cutouts: one behind the camera,
## or too small to see, is left out.
import Distance
import Geom
import Lens

Cutouts :: [].{

	## Which way a critter faces on screen.
	Facing : [FacesLeft, FacesRight]

	## A critter to draw. A cutout is ahead of the rider, so of its lengths only
	## `right` can be negative.
	Cutout : {
		right : Distance,
		forward : Distance,
		height : Distance,
		codepoint : I64,
		facing : Cutouts.Facing,
	}

	## What became of a critter placed in the rider's view.
	Placement : [InView(Cutouts.Cutout), BehindCamera, TooSmall]

	## A critter shorter than this many pixels is too small to draw.
	min_critter_px : F64
	min_critter_px = 2.0

	## A critter of `height` at `at` in the rider's view.
	placement : {
		at : Geom.RiderPoint,
		height : Distance,
		codepoint : I64,
		facing : Cutouts.Facing,
	} -> Cutouts.Placement
	placement = |{ at, height, codepoint, facing }|
		if at.forward <= Geom.near_plane {
			BehindCamera
		} else if (height.ratio_to(at.forward) * Lens.focal) < min_critter_px {
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

	## The cutouts of the critters in view, in order.
	cutouts_in_view : List(Cutouts.Placement) -> List(Cutouts.Cutout)
	cutouts_in_view = |placements|
		placements.join_map(
			|critter|
				match critter {
					InView(cutout) => [cutout]
					BehindCamera => []
					TooSmall => []
				},
		)

	## How many critters were too small to draw.
	too_small_count : List(Cutouts.Placement) -> I64
	too_small_count = |placements|
		placements
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

cow_placement : { forward : Distance, height : Distance } -> Cutouts.Placement
cow_placement = |{ forward, height }|
	Cutouts.placement({
		at: { right: Distance.metres(2.5), forward },
		height,
		codepoint: 128004,
		facing: FacesRight,
	})

# Which way a sighting went, whatever it carries.
fate_of : Cutouts.Placement -> [Seen, BehindCamera, TooSmall]
fate_of = |placement|
	match placement {
		InView(_) => Seen
		BehindCamera => BehindCamera
		TooSmall => TooSmall
	}

# A cow 2.5 m to the right, at each distance and height.
cow_places : List({ forward : Distance, height : Distance })
cow_places = [
	{ forward: Distance.metres(-5.0), height: Distance.metres(1.0) },
	{ forward: Distance.metres(0.3), height: Distance.metres(1.0) },
	{ forward: Distance.metres(0.4), height: Distance.metres(1.0) },
	{ forward: Distance.metres(0.5), height: Distance.metres(1.0) },
	{ forward: Distance.metres(300.0), height: Distance.metres(1.0) },
	{ forward: Distance.metres(342.0), height: Distance.metres(1.0) },
	{ forward: Distance.metres(343.0), height: Distance.metres(1.0) },
	{ forward: Distance.metres(400.0), height: Distance.metres(1.0) },
	{ forward: Distance.metres(10.0), height: Distance.metres(0.0) },
	{ forward: Distance.metres(50.0), height: Distance.metres(0.9) },
]

expect
	cow_places.map(|place| fate_of(cow_placement(place)))
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

cutout_of : Cutouts.Placement -> Cutouts.Cutout
cutout_of = |placement|
	match placement {
		InView(cutout) => cutout
		BehindCamera => crash "this critter is in view"
		TooSmall => crash "this critter is in view"
	}

near_cow : Cutouts.Cutout
near_cow = cutout_of(cow_placement({ forward: Distance.metres(0.5), height: Distance.metres(1.0) }))

left_bull : Cutouts.Cutout
left_bull = cutout_of(
	Cutouts.placement({
		at: { right: Distance.metres(-1.5), forward: Distance.metres(50.0) },
		height: Distance.metres(1.6),
		codepoint: 128002,
		facing: FacesLeft,
	}),
)

expect near_cow.right.to_metres() == 2.5
expect near_cow.forward.to_metres() == 0.5
expect near_cow.height.to_metres() == 1.0
expect left_bull.right.to_metres() == -1.5
expect left_bull.forward.to_metres() == 50.0
expect left_bull.height.to_metres() == 1.6

expect near_cow.codepoint == 128004
expect left_bull.codepoint == 128002
expect near_cow.facing == FacesRight
expect left_bull.facing == FacesLeft

expect Cutouts.cutouts_in_view(cow_places.map(cow_placement)).len() == 4
expect Cutouts.too_small_count(cow_places.map(cow_placement)) == 3
expect cow_places.map(cow_placement).len() == 10

expect Cutouts.min_critter_px == 2.0
