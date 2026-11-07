## A Roc bird at one moment of its flight: how it looks. The Roc bird is
## roc-lang.org's logo, sitting on treetops beside the road and flying off as
## the rider comes. BirdFlight says where a bird is and how it looks,
## CrossingSighting finds the birds in view, and BirdStills holds their
## drawings.
import Pixels
import Across
import Along
import BirdStills
import Camera
import Geom
import Picture
import SegmentPlace
import Spot
import StillShapes
import Still
import Distance
import lib.Brush
import lib.Shapes

PosedBird := { pose : PosedBird.BirdPose }.{

	## Where the wings are in a beat.
	WingBeat : [WingsUp, WingsDown]

	## How the bird looks: sitting; side on as it takes off; seen from behind
	## as it flies off; and dropping onto its tree.
	BirdPose : [
		Perched,
		Side(PosedBird.WingBeat),
		Away(PosedBird.WingBeat),
		Diving,
	]

	## How tall a bird stands.
	bird_height : Distance
	bird_height = Distance.metres(2.2)

	scenery_height : PosedBird -> Distance
	scenery_height = |_bird| PosedBird.bird_height

	## A bird on screen, its feet where it is.
	scenery_picture : PosedBird, Picture.Setting({}) -> Picture
	scenery_picture = |bird, setting|
		Picture.from_shapes(
			# As drawn, because birds start on left-hand trees; facing joins the
			# pose when they fly both ways.
			StillShapes.standing_still_shapes(
				setting,
				{ height: PosedBird.bird_height, polygons: PosedBird.pose_polygons(bird.pose) },
			),
		)

	## The drawing for a pose.
	pose_polygons : PosedBird.BirdPose -> Still
	pose_polygons = |pose|
		match pose {
			Perched => BirdStills.perched_polygons
			Side(WingsUp) => BirdStills.side_wings_up_polygons
			Side(WingsDown) => BirdStills.side_wings_down_polygons
			Away(WingsUp) => BirdStills.away_wings_up_polygons
			Away(WingsDown) => BirdStills.away_wings_down_polygons
			Diving => BirdStills.diving_polygons
		}
}

expect PosedBird.bird_height.to_metres() == 2.2

# A perched bird.
level_bird : PosedBird
level_bird = { pose: Perched }

## The spot `forward` ahead, `right` of the camera and `lift` off the ground.
spot_at : {
	forward : Distance,
	right : Distance,
	lift : Distance,
} -> Spot
spot_at = |{ forward, right, lift }| {
	foot =
		Geom.ahead_on_level({ right, forward })
			?? crash "a test's bird is past the near plane"
	Spot.at({
		place: Ahead(SegmentPlace.Position.first),
		road_point: {
			along: Along.metres(forward.to_metres()),
			across: Across.metres(right.to_metres()),
		},
		lift,
		foot,
	})
}

## `bird` 110 m ahead, `right` of the camera and `lift` off the ground, through
## a 500 px focal length. A lift of the camera's height puts its feet on the
## horizon.
bird_shapes_at : PosedBird, { right : Distance, lift : Distance } -> List(Shapes.Shape)
bird_shapes_at = |bird, { right, lift }| {
	spot = spot_at({ forward: Distance.metres(110.0), right, lift })
	bird.scenery_picture({ spot, cam_focal: Pixels.of(500.0), context: {} }).to_shapes()
}

## How many pixels tall a bird `forward` ahead, on the ground, is through
## `cam_focal`.
height_on_screen : Distance, Pixels -> F64
height_on_screen = |forward, cam_focal| {
	spot = spot_at({ forward, right: Distance.zero, lift: Distance.zero })
	anchor = StillShapes.standing_anchor(
		{ spot, cam_focal, context: {} },
		{ height: PosedBird.bird_height, flip: AsDrawn },
	)
	anchor.height_on_screen.to_f64()
}

expect
	[
		(height_on_screen(Distance.metres(110.0), Pixels.of(500.0)), 10.0),
		(height_on_screen(Distance.metres(220.0), Pixels.of(500.0)), 5.0),
		(height_on_screen(Distance.metres(110.0), Pixels.of(1000.0)), 20.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)

# A bird's height is the same in every pose.
expect
	[level_bird, { ..level_bird, pose: Diving }].all(
		|bird| bird.scenery_height() == PosedBird.bird_height,
	)

# The perched still's first corner is (-0.0344, 0.5715), at a height of 10 px
# from feet at (480, 300). 11 m to the right and 11 m above the camera, at
# 110 m, is 50 px each way.
expect {
	first_corner = |perch|
		match bird_shapes_at(level_bird, perch) {
			[Poly(polygon), ..] => polygon.coordinates.take_first(2)
			_ => crash "a bird draws polygons"
		}
	raised = { right: Distance.metres(11.0), lift: Camera.eye_height.plus(Distance.metres(11.0)) }
	[
		({ right: Distance.metres(0.0), lift: Camera.eye_height }, [479.656, 294.285]),
		(raised, [529.656, 244.285]),
	].all(
		|(perch, want)| {
			got = first_corner(perch)
			got.len() == 2 and got.map2(want, |x, y| (x - y).abs()).all(|miss| miss <= 0.000000001)
		},
	)
}

# Each pose draws its own still.
expect
	[
		(Perched, BirdStills.perched_polygons),
		(Side(WingsUp), BirdStills.side_wings_up_polygons),
		(Side(WingsDown), BirdStills.side_wings_down_polygons),
		(Away(WingsUp), BirdStills.away_wings_up_polygons),
		(Away(WingsDown), BirdStills.away_wings_down_polygons),
		(Diving, BirdStills.diving_polygons),
	].all(|(pose, still)| PosedBird.pose_polygons(pose) == still)

# Each still's polygons, in their colours, as a bird in each pose draws them.
expect {
	fill_of = |shape|
		match shape {
			Poly(polygon) => polygon.fill
			_ => crash "a bird's still is polygons"
		}
	level = { right: Distance.metres(0.0), lift: Camera.eye_height }
	drawn = [Side(WingsDown), Diving].join_map(
		|pose| bird_shapes_at({ pose: pose }, level).map(fill_of),
	)
	side_down = BirdStills.side_wings_down_polygons.polygons()
	stills = side_down.concat(BirdStills.diving_polygons.polygons())
	drawn
		== stills.map(
			|poly|
				match poly.fill {
					Flat(color) => Flat(Brush.opaque(color))
					Shaded(_) => crash "a bird's still is flat"
				},
		)
}
