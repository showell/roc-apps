## A still is a small picture made of polygons, each filled with a flat
## colour or a gradient. Its points are in units of its height: x across,
## and y up from its feet. EmojiStills, CatStills and BirdStills hold the
## pictures, and StillShapes puts them on screen.

import lib.ArgbColor
import lib.RgbColor

Stills :: [].{
	StillPt : { x : F64, y : F64 }

	## A polygon's gradient as traced. A linear one (kind 1) runs from `a` to
	## `b`; a radial one (any other kind) is centred at `c`, with `u` and `v`
	## its two axes. Each runs from `color0` at offset `off0` to `color1` at
	## `off1`.
	StillGradient : {
		kind : I64,
		color0 : ArgbColor,
		color1 : ArgbColor,
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
		color : RgbColor,
		gradients : List(Stills.StillGradient),
		points : List(Stills.StillPt),
	}
}
