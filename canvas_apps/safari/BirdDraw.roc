## The Roc bird is roc-lang.org's logo, sitting on treetops beside the road
## and flying off as the rider comes. BirdFlight says where a bird is and how
## it looks, BirdSighting finds the birds in view, and BirdStills holds their
## drawings. This module draws one.
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
	draw : BirdSighting, F64 -> List(Shapes.Shape)
	draw = |bird, cam_focal| {
		feet = Camera.project(
			{
				right: Distance.metres(bird.right),
				forward: Distance.metres(bird.forward),
				height: bird.lift,
			},
			cam_focal,
		)
		StillDraw.draw_still(
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
	right: 0.0,
	forward: 110.0,
	lift: Camera.eye_h,
	pose: Perched,
}

expect
	[
		(BirdSighting.bird_height.to_metres(), 2.2),
		(BirdSighting.height_px({ forward: 110.0, cam_focal: 500.0 }), 10.0),
		(BirdSighting.height_px({ forward: 220.0, cam_focal: 500.0 }), 5.0),
		(BirdSighting.height_px({ forward: 110.0, cam_focal: 1000.0 }), 20.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)

# The perched still's first corner is (-0.0344, 0.5715), at a height of 10 px
# from feet at (480, 300). 11 m to the right and 11 m above the camera, at
# 110 m, is 50 px each way.
expect {
	first_corner = |bird|
		match BirdDraw.draw(bird, 500.0) {
			[Poly(polygon), ..] => polygon.pts.take_first(2)
			_ => crash "a bird draws polygons"
		}
	moved_bird = {
		..level_bird,
		right: 11.0,
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
		|pose| BirdDraw.draw({ ..level_bird, pose }, 500.0).map(fill_of),
	)
	stills = List.concat(BirdStills.side_wings_down, BirdStills.diving)
	drawn == stills.map(|poly| Flat(Brush.opaque(poly.color)))
}
