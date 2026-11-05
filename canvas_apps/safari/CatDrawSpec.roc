## These are CatDraw's checks: where a still's corners land on screen,
## the corner guard, and how many polygons a cat draws.
app [main!] {
	lib: "../lib/main.roc",
}

import Cat
import CatDraw
import CatStills
import Grade
import Stills
import Screen
import ShapeRead

feet : Screen.Point
feet = { x: 100.0, y: 200.0 }

## A cat 50 px tall, standing at `feet`.
standing : CatDraw.Anchor
standing = {
	feet,
	height_px: 50.0,
	lift: 0.0,
}

pt_got : List(F64)
pt_got = [
	{ x: 0.5, y: 0.4 },
	{ x: 0.0, y: 0.0 },
	{ x: (-1.0), y: 1.0 },
].join_map(
	|pt| {
		on_screen = CatDraw.screen_point(standing, pt)
		[on_screen.x, on_screen.y]
	},
)

pt_want : List(F64)
pt_want = [125.0, 180.0, 100.0, 200.0, 50.0, 150.0]

lift_got : List(F64)
lift_got = {
	a = CatDraw.screen_point({ ..standing, lift: 0.2 }, { x: 0.5, y: 0.4 })
	b = CatDraw.screen_point(
		{
			feet,
			height_px: 100.0,
			lift: 0.2,
		},
		{ x: 0.5, y: 0.4 },
	)
	z = CatDraw.screen_point(standing, { x: 0.5, y: 0.4 })
	[
		a.x,
		a.y,
		(z.y - a.y),
		b.y,
		(a.x - z.x),
	]
}

lift_want : List(F64)
lift_want = [125.0, 170.0, 10.0, 140.0, 0.0]

## A polygon of colour 9 with `n` corners, all at the feet.
poly_of : U64 -> Stills.StillPoly
poly_of = |n| {
	color: 9,
	grad: [],
	pts: List.repeat({ x: 0.0, y: 0.0 }, n),
}

pts_got : List(F64)
pts_got = {
	on_screen = [
		{ x: 0.0, y: 0.0 },
		{ x: 0.5, y: 0.4 },
	].map(|pt| CatDraw.screen_point(standing, pt))
	List.concat([I64.to_f64(on_screen.len().to_i64_wrap())], on_screen.join_map(|pt| [pt.x, pt.y]))
}

pts_want : List(F64)
pts_want = [2.0, 100.0, 200.0, 125.0, 180.0]

guard_got : List(I64)
guard_got = List.concat(
	[CatDraw.max_cat_pts],
	[
		3,
		256,
		257,
		2,
	].map(|n| CatDraw.polygon(standing, poly_of(n)).len().to_i64_wrap()),
)

guard_want : List(I64)
guard_want = [256, 1, 1, 0, 0]

solid_got : List(I64)
solid_got = {
	c = CatDraw.polygon(
		standing,
		poly_of(3),
	).first() ?? crash "CatDrawSpec: a triangle is one shape"
	[
		ShapeRead.flat_color_of(c),
		ShapeRead.pts_of(c).len().to_i64_wrap(),
	]
}

solid_want : List(I64)
solid_want = [9, 6]

polys_got : List(I64)
polys_got = {
	two = CatDraw.polygons(standing, [poly_of(3), poly_of(4)])
	second = two.get(1) ?? crash "CatDrawSpec: two polygons are two shapes"
	[
		CatDraw.polygons(
			standing,
			[
				poly_of(3),
				poly_of(4),
				poly_of(300),
			],
		).len().to_i64_wrap(),
		CatDraw.polygons(standing, []).len().to_i64_wrap(),
		ShapeRead.pts_of(second).len().to_i64_wrap(),
	]
}

polys_want : List(I64)
polys_want = [2, 0, 8]

## The cat `forward` metres ahead, `height` tall, in `pose` and raised by
## `lift`, through a 500 px focal length on a 960 px view.
cat_shapes : {
	forward : F64,
	height : F64,
	pose : Cat.Pose,
	lift : F64,
} -> I64
cat_shapes = |
	{
		forward,
		height,
		pose,
		lift,
	},
| CatDraw.draw({
	right: 0.0,
	forward,
	height,
	pose,
	lift,
	cam_focal: 500.0,
	view_w: 960.0,
}).len().to_i64_wrap()

## How many shapes a resting cat makes `forward` metres ahead.
shape_count : F64, F64 -> I64
shape_count = |forward, height| cat_shapes({
	forward,
	height,
	pose: Rest,
	lift: 0.0,
})

size_got : List(I64)
size_got = [
	shape_count(850.0, 1.7),
	shape_count(851.0, 1.7),
	shape_count(2000.0, 1.7),
]

size_want : List(I64)
size_want = [
	CatStills.pose_polys(Rest).len().to_i64_wrap(),
	0,
	0,
]

count_got : List(I64)
count_got = [
	{
		forward: 100.0,
		height: 1.7,
		pose: Rest,
		lift: 0.0,
	},
	{
		forward: 100.0,
		height: 1.7,
		pose: Rest,
		lift: 0.3,
	},
	{
		forward: 100.0,
		height: 1.7,
		pose: Frozen,
		lift: 0.0,
	},
].map(cat_shapes)

count_want : List(I64)
count_want = [Rest, Rest, Frozen].map(|pose| CatStills.pose_polys(pose).len().to_i64_wrap())

table_got : List(Bool)
table_got = [
	Rest,
	Stride,
	Frozen,
	Coil,
	Flight,
	Land,
	Collapse,
].map(|pose| CatStills.pose_polys(pose).len() > 0)

table_want : List(Bool)
table_want = [True, True, True, True, True, True, True]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "cd-pt    ",
			got: pt_got,
			want: pt_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "cd-lift  ",
			got: lift_got,
			want: lift_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "cd-pts   ",
			got: pts_got,
			want: pts_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "cd-guard ",
			got: guard_got,
			want: guard_want,
		}),
		Grade.ints({
			name: "cd-solid ",
			got: solid_got,
			want: solid_want,
		}),
		Grade.ints({
			name: "cd-polys ",
			got: polys_got,
			want: polys_want,
		}),
		Grade.ints({
			name: "cd-size  ",
			got: size_got,
			want: size_want,
		}),
		Grade.ints({
			name: "cd-count ",
			got: count_got,
			want: count_want,
		}),
		Grade.bools({
			name: "cd-table ",
			got: table_got,
			want: table_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
