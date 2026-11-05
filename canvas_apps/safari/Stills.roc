## A still is a small picture made of polygons, each filled with a flat
## colour or a gradient. Its points are in units of its height: x across,
## and y up from its feet. EmojiStills, CatStills and BirdStills hold the
## pictures, and Critter and CatDraw put them on screen.

Stills :: [].{
	StillPt : { x : F64, y : F64 }

	## A polygon's gradient as traced. A linear one (kind 1) runs from `a` to
	## `b`; a radial one (any other kind) is centred at `c`, with `u` and `v`
	## its two axes. Each runs from `rgba0` at offset `off0` to `rgba1` at
	## `off1`.
	StillGrad : {
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
	StillPoly : {
		color : I64,
		grad : List(Stills.StillGrad),
		pts : List(Stills.StillPt),
	}
}

sample_point : Stills.StillPt
sample_point = { x: 0.5, y: 1.5 }

sample_gradient : Stills.StillGrad
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

solid_poly : Stills.StillPoly
solid_poly = {
	color: 9066271,
	grad: [],
	pts: [sample_point, { x: 12.5, y: 13.5 }],
}

shaded_poly : Stills.StillPoly
shaded_poly = {
	color: 4989733,
	grad: [sample_gradient],
	pts: [sample_point],
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

expect solid_poly.color == 9066271
expect shaded_poly.color == 4989733
expect solid_poly.grad.len() == 0
expect shaded_poly.grad.len() == 1
expect solid_poly.pts.len() == 2
expect shaded_poly.pts.len() == 1

expect shaded_poly.grad.map(|gradient| gradient.ax) == [2.5]
expect shaded_poly.pts.map(|point| point.x) == [0.5]
expect solid_poly.pts.map(|point| point.y) == [1.5, 13.5]
