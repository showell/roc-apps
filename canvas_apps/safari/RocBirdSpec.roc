## These are RocBird's checks: how tall a bird is on screen, where its feet go,
## and which drawing it is drawn from.
app [main!] {
	lib: "../lib/main.roc",
}

import BirdStills
import Camera
import Distance
import Grade
import RocBird
import ShapeRead
import lib.Shapes

cam_focal : F64
cam_focal = 500.0

## A perched bird straight ahead, its feet at the camera's height, so they
## land on the horizon in the middle of the screen.
level_bird : RocBird.PlacedBird
level_bird = {
	right: 0.0,
	forward: 110.0,
	lift: Distance.metres(Camera.eye_h),
	pose: Perched,
}

## The first corner of the first shape, on screen.
first_corner : List(Shapes.Shape) -> List(F64)
first_corner = |shapes| {
	first_shape = shapes.first() ?? crash "RocBirdSpec: a bird draws shapes"
	ShapeRead.pts_of(first_shape).take_first(2)
}

height_got : List(F64)
height_got = [
	RocBird.bird_height.to_metres(),
	RocBird.height_px({ forward: 110.0, cam_focal: 500.0 }),
	RocBird.height_px({ forward: 220.0, cam_focal: 500.0 }),
	RocBird.height_px({ forward: 110.0, cam_focal: 1000.0 }),
]

height_want : List(F64)
height_want = [2.2, 10.0, 5.0, 20.0]

## The perched still's first corner is (-0.0344, 0.5715), at a height of 10 px
## from feet at (480, 300).
perched_got : List(F64)
perched_got = first_corner(RocBird.draw(level_bird, cam_focal))

perched_want : List(F64)
perched_want = [479.656, 294.285]

## 11 m to the right and 11 m above the camera, at 110 m, is 50 px each way.
moved_got : List(F64)
moved_got = first_corner(
	RocBird.draw(
		{
			..level_bird,
			right: 11.0,
			lift: Distance.metres(Camera.eye_h + 11.0),
		},
		cam_focal,
	),
)

moved_want : List(F64)
moved_want = [529.656, 244.285]

## Each still's polygons, in their colours, as a bird in each pose draws them.
colours_got : List(I64)
colours_got = [
	Side(WingsDown),
	Diving,
].join_map(|pose| RocBird.draw({ ..level_bird, pose }, cam_focal).map(ShapeRead.flat_color_of))

colours_want : List(I64)
colours_want = List.concat(BirdStills.side_wings_down, BirdStills.diving).map(|poly| poly.color)

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "rb-height ",
			got: height_got,
			want: height_want,
			tol: 0.000000001,
		}),
		Grade.reals({
			name: "rb-perched",
			got: perched_got,
			want: perched_want,
			tol: 0.000000001,
		}),
		Grade.reals({
			name: "rb-moved  ",
			got: moved_got,
			want: moved_want,
			tol: 0.000000001,
		}),
		Grade.ints({
			name: "rb-colours",
			got: colours_got,
			want: colours_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
