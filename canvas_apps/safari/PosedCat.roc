## A cat at one moment of its crossing: how it holds itself. It draws as the
## still for its pose, its feet at its spot, raised as high as the spot says
## while it leaps.
import Pixels
import Across
import Along
import CatStills
import Distance
import Geom
import Picture
import SegmentPlace
import Spot
import StillShapes
import Still
import lib.Shapes

PosedCat := { pose : PosedCat.CatPose }.{

	## How the cat holds itself: walking, it is at rest or mid-stride; then
	## frozen; then its leap, from the coil through flight and landing to the
	## collapse after.
	CatPose : [Rest, Stride, Frozen, Coil, Flight, Land, Collapse]

	cat_height : Distance
	cat_height = Distance.metres(1.7)

	scenery_height : PosedCat -> Distance
	scenery_height = |_cat| PosedCat.cat_height

	## A cat on screen, its feet where it is.
	scenery_picture : PosedCat, Picture.Setting({}) -> Picture
	scenery_picture = |cat, setting|
		Picture.from_shapes(
			StillShapes.standing_still_shapes(
				setting,
				{ height: PosedCat.cat_height, still: PosedCat.pose_still(cat.pose) },
			),
		)

	## The cat's still in a pose.
	pose_still : PosedCat.CatPose -> Still
	pose_still = |pose|
		match pose {
			Rest => CatStills.rest_still
			Stride => CatStills.stride_still
			Frozen => CatStills.frozen_still
			Coil => CatStills.coil_still
			Flight => CatStills.flight_still
			Land => CatStills.land_still
			Collapse => CatStills.collapse_still
		}
}

## A cat at rest.
near_cat : PosedCat
near_cat = { pose: Rest }

## The spot 100 m straight ahead, on the rider's own segment, `lift` off the
## ground.
spot_ahead : Distance -> Spot
spot_ahead = |lift| {
	foot =
		Geom.ahead_on_level({ right: Distance.zero, forward: Distance.metres(100.0) })
			?? crash "a test's cat is past the near plane"
	Spot.at({
		place: Ahead(SegmentPlace.Position.first),
		road_point: { along: Along.metres(100.0), across: Across.middle },
		lift,
		foot,
	})
}

## `cat` 100 m straight ahead through a 500 px focal length, `lift` off the
## ground: on the ground its feet land at (480, 306), and it stands 8.5 px tall.
sample_cat_shapes : PosedCat, Distance -> List(Shapes.Shape)
sample_cat_shapes = |cat, lift|
	cat.scenery_picture({
		spot: spot_ahead(lift),
		cam_focal: Pixels.of(500.0),
		context: {},
	}).to_shapes()

## The first corner `cat` draws, `lift` off the ground: its still's first
## corner, on screen.
first_corner_coordinates : PosedCat, Distance -> List(F64)
first_corner_coordinates = |cat, lift|
	match sample_cat_shapes(cat, lift) {
		[Poly(polygon), ..] => polygon.coordinates.take_first(2)
		_ => crash "a cat draws polygons"
	}

is_near : List(F64), List(F64) -> Bool
is_near = |got, expected| {
	misses = got.map2(expected, |one, wanted| (one - wanted).abs())
	got.len() == expected.len() and misses.all(|miss| miss <= 0.000000001)
}

# The resting still's first corner is (0.0092, 0.4513), and 1 m of lift at 100 m
# raises it 5 px without moving it across.
expect
	[
		(Distance.zero, [480.0782, 302.16395]),
		(Distance.metres(1.0), [480.0782, 297.16395]),
	].all(|(lift, want)| is_near(first_corner_coordinates(near_cat, lift), want))

# Each pose draws its own still.
expect
	[
		(Rest, CatStills.rest_still),
		(Stride, CatStills.stride_still),
		(Frozen, CatStills.frozen_still),
		(Coil, CatStills.coil_still),
		(Flight, CatStills.flight_still),
		(Land, CatStills.land_still),
		(Collapse, CatStills.collapse_still),
	].all(|(pose, still)| PosedCat.pose_still(pose) == still)

# Each pose draws every polygon of its still.
expect
	[
		Rest,
		Stride,
		Frozen,
		Coil,
		Flight,
		Land,
		Collapse,
	].all(
		|pose| {
			shapes = sample_cat_shapes({ pose: pose }, Distance.zero)
			shapes.len() == PosedCat.pose_still(pose).polygons().len()
		},
	)
