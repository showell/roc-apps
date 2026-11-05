## These are Critter's checks: how a still's points and vectors land on
## screen, mirrored and not, the guard on a polygon's size, and when a
## critter is too small, or unknown, to draw.
app [main!] {
	lib: "../lib/main.roc",
}

import Critter
import EmojiStills
import Distance
import Grade
import Stills
import Screen
import ShapeRead

feet : Screen.Point
feet = { x: 100.0, y: 200.0 }

## A still 50 pixels tall, standing on `feet`, as drawn.
upright : Critter.Anchor
upright = {
	feet,
	flip: AsDrawn,
	height_px: 50.0,
}

## The same still, mirrored.
mirrored : Critter.Anchor
mirrored = {
	feet,
	flip: Mirrored,
	height_px: 50.0,
}

facing_got : List(F64)
facing_got = [Critter.x_sign(Mirrored), Critter.x_sign(AsDrawn)]

facing_want : List(F64)
facing_want = [(-1.0), 1.0]

point_got : List(F64)
point_got = {
	a = Critter.screen_point(upright, { x: 0.5, y: 0.4 })
	b = Critter.screen_point(mirrored, { x: 0.5, y: 0.4 })
	c = Critter.screen_point(upright, { x: 0.0, y: 0.0 })
	[
		a.x,
		a.y,
		b.x,
		b.y,
		c.x,
		c.y,
	]
}

point_want : List(F64)
point_want = [125.0, 180.0, 75.0, 180.0, 100.0, 200.0]

vector_got : List(F64)
vector_got = {
	a = Critter.screen_vector(upright, { x: 0.5, y: 0.4 })
	b = Critter.screen_vector(mirrored, { x: 0.5, y: 0.4 })
	c = Critter.screen_vector(upright, { x: 0.0, y: 0.0 })
	[
		a.x,
		a.y,
		b.x,
		b.y,
		c.x,
		c.y,
	]
}

vector_want : List(F64)
vector_want = [
	25.0,
	(-20.0),
	(-25.0),
	(-20.0),
	0.0,
	0.0,
]

anchor_got : List(F64)
anchor_got = {
	p = Critter.screen_point(upright, { x: 0.5, y: 0.4 })
	v = Critter.screen_vector(upright, { x: 0.5, y: 0.4 })
	[(p.x - v.x), (p.y - v.y)]
}

anchor_want : List(F64)
anchor_want = [100.0, 200.0]

mapped_got : List(F64)
mapped_got = {
	points = Critter.screen_points(
		upright,
		[
			{ x: 0.0, y: 0.0 },
			{ x: 0.5, y: 0.4 },
			{ x: 1.0, y: 1.0 },
		],
	)
	List.concat([points.len().to_f64()], points.join_map(|point| [point.x, point.y]))
}

mapped_want : List(F64)
mapped_want = [3.0, 100.0, 200.0, 125.0, 180.0, 150.0, 150.0]

## A solid polygon of colour 7 with `count` points, all at the feet.
flat_poly : U64 -> Stills.StillPoly
flat_poly = |count| {
	color: 7,
	grad: [],
	pts: List.repeat({ x: 0.0, y: 0.0 }, count),
}

poly_shape_count : U64 -> I64
poly_shape_count = |count| Critter.draw_poly(upright, flat_poly(count)).len().to_i64_wrap()

guard_got : List(I64)
guard_got = [
	Critter.max_still_points.to_i64_wrap(),
	poly_shape_count(3),
	poly_shape_count(512),
	poly_shape_count(513),
	poly_shape_count(2),
]

guard_want : List(I64)
guard_want = [512, 1, 1, 0, 0]

solid_got : List(I64)
solid_got = {
	shape = Critter.draw_poly(
		upright,
		flat_poly(3),
	).first() ?? crash "CritterSpec: a solid polygon is one shape"
	[
		ShapeRead.flat_color_of(shape),
		ShapeRead.pts_of(shape).len().to_i64_wrap(),
	]
}

solid_want : List(I64)
solid_want = [7, 6]

## How many shapes draw an elephant of `height` metres, `forward` metres
## ahead.
shape_count : {
	forward : F64,
	height : Distance,
	codepoint : I64,
} -> I64
shape_count = |
	{
		forward,
		height,
		codepoint,
	},
|
	Critter.draw(
		{
			right: 0.0,
			forward,
			height,
			codepoint,
			facing: FacesLeft,
		},
		500.0,
	).len().to_i64_wrap()

elephant : I64
elephant = 128024

size_got : List(I64)
size_got = [
	shape_count({
		forward: 1000.0,
		height: Distance.metres(2.0),
		codepoint: elephant,
	}),
	shape_count({
		forward: 2000.0,
		height: Distance.metres(2.0),
		codepoint: elephant,
	}),
	shape_count({
		forward: 1000.0,
		height: Distance.metres(1.9),
		codepoint: elephant,
	}),
	shape_count({
		forward: 100.0,
		height: Distance.metres(2.0),
		codepoint: elephant,
	}),
]

size_want : List(I64)
size_want = [6, 0, 0, 6]

unknown_got : List(I64)
unknown_got = [
	EmojiStills.emoji_polys_for(1).len().to_i64_wrap(),
	shape_count({
		forward: 100.0,
		height: Distance.metres(2.0),
		codepoint: 1,
	}),
	EmojiStills.emoji_polys_for(elephant).len().to_i64_wrap(),
]

unknown_want : List(I64)
unknown_want = [0, 0, 6]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "cr-facing",
			got: facing_got,
			want: facing_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "cr-point ",
			got: point_got,
			want: point_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "cr-vector",
			got: vector_got,
			want: vector_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "cr-anchor",
			got: anchor_got,
			want: anchor_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "cr-mapped",
			got: mapped_got,
			want: mapped_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "cr-guard ",
			got: guard_got,
			want: guard_want,
		}),
		Grade.ints({
			name: "cr-solid ",
			got: solid_got,
			want: solid_want,
		}),
		Grade.ints({
			name: "cr-size  ",
			got: size_got,
			want: size_want,
		}),
		Grade.ints({
			name: "cr-unknwn",
			got: unknown_got,
			want: unknown_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
