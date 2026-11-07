## A still is a small picture made of polygons, each filled with a flat
## colour or a gradient. It is drawn in its own frame, in units of its height:
## its feet at y 0, y up, and its height 1, with x across from its middle. A
## still that is wider than it is tall, such as a flying bird, has x past 1.
## EmojiStills, CatStills and BirdStills hold the pictures, and StillShapes
## puts them on screen.
import lib.ArgbColor
import lib.RgbColor

Still := List(Still.Polygon).{

	## A corner of a still's polygon, in the still's frame.
	Vertex : { x : F64, y : F64 }

	## A polygon's gradient as traced. A linear one (kind 1) runs from `a` to
	## `b`; a radial one (any other kind) is centred at `c`, with `u` and `v`
	## its two axes. Each runs from `color0` at offset `off0` to `color1` at
	## `off1`.
	Gradient : {
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
	Polygon : {
		color : RgbColor,
		gradients : List(Still.Gradient),
		points : List(Still.Vertex),
	}

	## The still's polygons, in the order they are drawn.
	polygons : Still -> List(Still.Polygon)
	polygons = |Still.(still_polygons)| still_polygons

	is_eq : _
}
