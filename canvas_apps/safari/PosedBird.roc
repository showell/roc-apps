## A Roc bird at one moment of its flight: how it looks, and how high its feet
## are. The Roc bird is roc-lang.org's logo, sitting on treetops beside the road
## and flying off as the rider comes. BirdFlight says where a bird is and how it
## looks, CrossingSighting finds the birds in view, and BirdStills holds their
## drawings.
import Pixels
import BirdFlight
import BirdStills
import Camera
import Geom
import Picture
import StillShapes
import Distance
import lib.Brush
import lib.RgbColor
import lib.Shapes

PosedBird := { pose : BirdFlight.BirdPose, lift : Distance }.{

	## How tall a bird `forward` metres ahead is on screen.
	height_px : { forward : Distance, cam_focal : Pixels } -> Pixels
	height_px = |{ forward, cam_focal }| cam_focal.times(BirdFlight.bird_height.ratio_to(forward))

	scenery_height : PosedBird -> Distance
	scenery_height = |_bird| BirdFlight.bird_height

	## A bird on screen, its feet where it is. Its still is unflipped: a bird
	## from a left-hand tree crosses the road toward +x, the way its beak points.
	scenery_picture : PosedBird, Picture.Setting({}) -> Picture
	scenery_picture = |bird, { foot, cam_focal, .. }| {
		feet = Camera.project(foot.at_height(bird.lift), cam_focal)
		Picture.from_shapes(
			StillShapes.still_shapes(
				{
					feet,
					flip: AsDrawn,
					height_px: PosedBird.height_px({ forward: foot.forward(), cam_focal }),
				},
				BirdStills.pose_polygons(bird.pose),
			),
		)
	}
}

# A perched bird with its feet at the camera's height, so that straight ahead
# they land on the horizon in the middle of the screen.
level_bird : PosedBird
level_bird = { lift: Camera.eye_height, pose: Perched }

## `bird` 110 m ahead and `right` of the camera, through a 500 px focal length.
bird_shapes_at : PosedBird, Distance -> List(Shapes.Shape)
bird_shapes_at = |bird, right| {
	foot =
		Geom.ahead_on_level({ right, forward: Distance.metres(110.0) })
			?? crash "a test's bird is past the near plane"
	bird.scenery_picture({ foot, cam_focal: Pixels.of(500.0), context: {} }).to_shapes()
}

## How many pixels tall a bird `forward` ahead is, through `cam_focal`.
height_on_screen : Distance, Pixels -> F64
height_on_screen = |forward, cam_focal| PosedBird.height_px({ forward, cam_focal }).to_f64()

expect
	[
		(height_on_screen(Distance.metres(110.0), Pixels.of(500.0)), 10.0),
		(height_on_screen(Distance.metres(220.0), Pixels.of(500.0)), 5.0),
		(height_on_screen(Distance.metres(110.0), Pixels.of(1000.0)), 20.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)

# A bird's height is the same in every pose.
expect
	[level_bird, { ..level_bird, pose: Diving }].all(
		|bird| bird.scenery_height() == BirdFlight.bird_height,
	)

# The perched still's first corner is (-0.0344, 0.5715), at a height of 10 px
# from feet at (480, 300). 11 m to the right and 11 m above the camera, at
# 110 m, is 50 px each way.
expect {
	first_corner = |bird, right|
		match bird_shapes_at(bird, right) {
			[Poly(polygon), ..] => polygon.coordinates.take_first(2)
			_ => crash "a bird draws polygons"
		}
	raised_bird = { ..level_bird, lift: Camera.eye_height.plus(Distance.metres(11.0)) }
	[
		(level_bird, Distance.metres(0.0), [479.656, 294.285]),
		(raised_bird, Distance.metres(11.0), [529.656, 244.285]),
	].all(
		|(bird, right, want)| {
			got = first_corner(bird, right)
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
		|pose| bird_shapes_at({ ..level_bird, pose }, Distance.metres(0.0)).map(fill_of),
	)
	stills = BirdStills.side_wings_down.concat(BirdStills.diving_polygons)
	drawn == stills.map(|poly| Flat(Brush.opaque(RgbColor.of(poly.color))))
}
