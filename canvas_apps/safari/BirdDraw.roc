## The Roc bird is roc-lang.org's logo, sitting on treetops beside the road
## and flying off as the rider comes. BirdFlight says where a bird is and how
## it looks, BirdSighting finds the birds in view, and BirdStills holds their
## drawings. This module draws one.
import Pixels
import BirdSighting
import BirdStills
import Camera
import StillDraw
import Distance
import lib.Brush
import lib.Shapes

BirdDraw :: [].{

	## A bird on screen, its feet where it is. Its still is unflipped: a bird
	## from a left-hand tree crosses the road toward +x, the way its beak points.
	bird_shapes : BirdSighting, Pixels -> List(Shapes.Shape)
	bird_shapes = |bird, cam_focal| {
		feet = Camera.project(
			{
				right: bird.right,
				forward: bird.forward,
				height: bird.lift,
			},
			cam_focal,
		)
		StillDraw.still_shapes(
			{
				feet,
				flip: AsDrawn,
				height_px: BirdSighting.height_px({ forward: bird.forward, cam_focal }),
			},
			BirdStills.pose_polygons(bird.pose),
		)
	}
}

# A perched bird straight ahead, its feet at the camera's height, so they land
# on the horizon in the middle of the screen.
level_bird : BirdSighting
level_bird = {
	right: Distance.metres(0.0),
	forward: Distance.metres(110.0),
	lift: Camera.eye_h,
	pose: Perched,
}

## How many pixels tall a bird `forward` ahead is, through `cam_focal`.
height_on_screen : Distance, Pixels -> F64
height_on_screen = |forward, cam_focal| BirdSighting.height_px({ forward, cam_focal }).to_f64()

expect
	[
		(BirdSighting.bird_height.to_metres(), 2.2),
		(height_on_screen(Distance.metres(110.0), Pixels.of(500.0)), 10.0),
		(height_on_screen(Distance.metres(220.0), Pixels.of(500.0)), 5.0),
		(height_on_screen(Distance.metres(110.0), Pixels.of(1000.0)), 20.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)

# The perched still's first corner is (-0.0344, 0.5715), at a height of 10 px
# from feet at (480, 300). 11 m to the right and 11 m above the camera, at
# 110 m, is 50 px each way.
expect {
	first_corner = |bird|
		match BirdDraw.bird_shapes(bird, Pixels.of(500.0)) {
			[Poly(polygon), ..] => polygon.points.take_first(2)
			_ => crash "a bird draws polygons"
		}
	moved_bird = {
		..level_bird,
		right: Distance.metres(11.0),
		lift: Camera.eye_h.plus(Distance.metres(11.0)),
	}
	[(level_bird, [479.656, 294.285]), (moved_bird, [529.656, 244.285])].all(
		|(bird, want)| {
			got = first_corner(bird)
			got.len() == 2 and got.map2(want, |x, y| (x - y).abs()).all(|miss| miss <= 0.000000001)
		},
	)
}

# Each still's polygons, in their colours, as a bird in each pose draws them.
expect {
	fill_of = |shape|
		match shape {
			Poly(polygon) => polygon.fill
			_ => crash "a bird's still is polygons"
		}
	drawn = [Side(WingsDown), Diving].join_map(
		|pose| BirdDraw.bird_shapes({ ..level_bird, pose }, Pixels.of(500.0)).map(fill_of),
	)
	stills = BirdStills.side_wings_down.concat(BirdStills.diving_polygons)
	drawn == stills.map(|poly| Flat(Brush.opaque(poly.color)))
}
