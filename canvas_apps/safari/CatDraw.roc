## CatDraw draws the cat: the still for the pose it is in, standing where its
## sighting found it, its feet raised as it leaps.
import Pixels
import Camera
import Cat
import CatSighting
import CatStills
import Distance
import StillDraw
import lib.Shapes

CatDraw :: [].{

	## A cat on screen, its feet where it is.
	draw : CatSighting, Pixels -> List(Shapes.Shape)
	draw = |cat, cam_focal| {
		projected = |height| Camera.project(
			{ right: cat.right, forward: cat.forward, height },
			cam_focal,
		)
		feet = projected(cat.lift)
		StillDraw.still_shapes(
			{
				feet,
				flip: AsDrawn,
				height_px: feet.y.minus(projected(cat.lift.plus(Cat.cat_height)).y),
			},
			CatStills.pose_polygons(cat.pose),
		)
	}
}

## A cat 100 m straight ahead, on the ground, through a 500 px focal length: its
## feet land at (480, 306), and it stands 8.5 px tall.
near_cat : CatSighting
near_cat = {
	right: Distance.metres(0.0),
	forward: Distance.metres(100.0),
	lift: Distance.zero,
	pose: Rest,
}

cat_shapes : CatSighting -> List(Shapes.Shape)
cat_shapes = |cat| CatDraw.draw(cat, Pixels.of(500.0))

## The first corner `cat` draws: its still's first corner, on screen.
first_corner_coordinates : CatSighting -> List(F64)
first_corner_coordinates = |cat|
	match cat_shapes(cat) {
		[Poly(polygon), ..] => polygon.points.take_first(2)
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
	].all(|pose| cat_shapes({ ..near_cat, pose }).len() == CatStills.pose_polygons(pose).len())
