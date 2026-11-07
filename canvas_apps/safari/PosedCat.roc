## A cat at one moment of its crossing: how it holds itself, and how high its
## leap has raised it. It draws as the still for its pose, standing where its
## sighting found it, its feet raised as it leaps.
import Pixels
import Camera
import Cat
import CatStills
import Distance
import Geom
import Picture
import StillShapes
import lib.Shapes

PosedCat := { pose : Cat.CatPose, lift : Distance }.{

	scenery_height : PosedCat -> Distance
	scenery_height = |_cat| Cat.cat_height

	## A cat on screen, its feet where it is.
	scenery_picture : PosedCat, Picture.Setting({}) -> Picture
	scenery_picture = |cat, { foot, cam_focal, .. }| {
		projected = |height| Camera.project(foot.at_height(height), cam_focal)
		feet = projected(cat.lift)
		Picture.from_shapes(
			StillShapes.still_shapes(
				{
					feet,
					flip: AsDrawn,
					height_px: feet.y.minus(projected(cat.lift.plus(Cat.cat_height)).y),
				},
				CatStills.pose_polygons(cat.pose),
			),
		)
	}
}

## A cat on the ground, at rest.
near_cat : PosedCat
near_cat = { lift: Distance.zero, pose: Rest }

## `cat` 100 m straight ahead through a 500 px focal length: its feet on the
## ground land at (480, 306), and it stands 8.5 px tall.
sample_cat_shapes : PosedCat -> List(Shapes.Shape)
sample_cat_shapes = |cat| {
	foot =
		Geom.ahead_on_level({ right: Distance.zero, forward: Distance.metres(100.0) })
			?? crash "a test's cat is past the near plane"
	cat.scenery_picture({ foot, cam_focal: Pixels.of(500.0), context: {} }).to_shapes()
}

## The first corner `cat` draws: its still's first corner, on screen.
first_corner_coordinates : PosedCat -> List(F64)
first_corner_coordinates = |cat|
	match sample_cat_shapes(cat) {
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
		(near_cat, [480.0782, 302.16395]),
		({ ..near_cat, lift: Distance.metres(1.0) }, [480.0782, 297.16395]),
	].all(|(cat, want)| is_near(first_corner_coordinates(cat), want))

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
		|pose| sample_cat_shapes({ ..near_cat, pose }).len() == CatStills.pose_polygons(pose).len(),
	)

# A cat's height is the same in every pose.
expect
	[near_cat, { pose: Flight, lift: Distance.metres(1.0) }].all(
		|cat| cat.scenery_height() == Cat.cat_height,
	)
