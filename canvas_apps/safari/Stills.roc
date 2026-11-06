## A still is a small picture made of polygons, each filled with a flat
## colour or a gradient. Its points are in units of its height: x across,
## and y up from its feet. EmojiStills, CatStills and BirdStills hold the
## pictures, and StillDraw puts them on screen.

Stills :: [].{
	StillPt : { x : F64, y : F64 }

	## A polygon's gradient as traced. A linear one (kind 1) runs from `a` to
	## `b`; a radial one (any other kind) is centred at `c`, with `u` and `v`
	## its two axes. Each runs from `rgba0` at offset `off0` to `rgba1` at
	## `off1`.
	StillGradient : {
		kind : I64,
		rgba0 : I64,
		rgba1 : I64,
		off0 : F64,
		off1 : F64,
		ax : F64,
		ay : F64,
		bx : F64,
		by : F64,
		cx : F64,
		cy : F64,
		ux : F64,
		uy : F64,
		vx : F64,
		vy : F64,
	}

	## One polygon of a still: its colour, and its gradient if it has one.
	StillPolygon : {
		color : I64,
		gradient : List(Stills.StillGradient),
		points : List(Stills.StillPt),
	}

	## Whether a polygon can be drawn: it has three corners, and a linear
	## gradient of its has a length. StillDraw crashes on anything less.
	is_drawable : Stills.StillPolygon -> Bool
	is_drawable = |polygon| polygon.points.len() >= 3 and !polygon.gradient.any(has_no_length)
}

## Whether a gradient is a linear one that starts where it ends.
has_no_length : Stills.StillGradient -> Bool
has_no_length = |gradient|
	gradient.kind == 1 and gradient.ax == gradient.bx and gradient.ay == gradient.by

# A flat polygon of `count` corners, all at one point.
polygon_of : U64 -> Stills.StillPolygon
polygon_of = |count| {
	color: 7,
	gradient: [],
	points: List.repeat({ x: 0.0, y: 0.0 }, count),
}

expect Stills.is_drawable(polygon_of(3))
expect !Stills.is_drawable(polygon_of(2))

sample_point : Stills.StillPt
sample_point = { x: 0.5, y: 1.5 }

sample_gradient : Stills.StillGradient
sample_gradient = {
	kind: 2,
	rgba0: 16711680,
	rgba1: 255,
	off0: 0.25,
	off1: 0.75,
	ax: 2.5,
	ay: 3.5,
	bx: 4.5,
	by: 5.5,
	cx: 6.5,
	cy: 7.5,
	ux: 8.5,
	uy: 9.5,
	vx: 10.5,
	vy: 11.5,
}

# A linear gradient that ends where it starts.
gradient_in_place : Stills.StillGradient
gradient_in_place = {
	..sample_gradient,
	kind: 1,
	bx: 2.5,
	by: 3.5,
}

# A linear gradient needs a length, and only a linear one has `a` and `b`.
expect has_no_length(gradient_in_place)
expect !has_no_length({ ..gradient_in_place, bx: 4.5 })
expect !has_no_length({ ..gradient_in_place, by: 5.5 })
expect !has_no_length({ ..gradient_in_place, kind: 2 })
expect !Stills.is_drawable({ ..polygon_of(3), gradient: [gradient_in_place] })

solid_polygon : Stills.StillPolygon
solid_polygon = {
	color: 9066271,
	gradient: [],
	points: [sample_point, { x: 12.5, y: 13.5 }],
}

shaded_polygon : Stills.StillPolygon
shaded_polygon = {
	color: 4989733,
	gradient: [sample_gradient],
	points: [sample_point],
}

expect sample_gradient.off0 == 0.25
expect sample_gradient.off1 == 0.75
expect sample_gradient.ax == 2.5
expect sample_gradient.ay == 3.5
expect sample_gradient.bx == 4.5
expect sample_gradient.by == 5.5
expect sample_gradient.cx == 6.5
expect sample_gradient.cy == 7.5
expect sample_gradient.ux == 8.5
expect sample_gradient.uy == 9.5
expect sample_gradient.vx == 10.5
expect sample_gradient.vy == 11.5

expect sample_gradient.kind == 2
expect sample_gradient.rgba0 == 16711680
expect sample_gradient.rgba1 == 255

expect solid_polygon.color == 9066271
expect shaded_polygon.color == 4989733
expect solid_polygon.gradient.len() == 0
expect shaded_polygon.gradient.len() == 1
expect solid_polygon.points.len() == 2
expect shaded_polygon.points.len() == 1

expect shaded_polygon.gradient.map(|gradient| gradient.ax) == [2.5]
expect shaded_polygon.points.map(|point| point.x) == [0.5]
expect solid_polygon.points.map(|point| point.y) == [1.5, 13.5]
