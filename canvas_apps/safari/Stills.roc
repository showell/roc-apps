## A still is a small picture made of polygons, each filled with a flat
## colour or a gradient. Its points are in units of its height: x across,
## and y up from its feet. EmojiStills, CatStills and RocBird hold the
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
	StillPoly : { color : I64, grad : List(Stills.StillGrad), pts : List(Stills.StillPt) }
}
