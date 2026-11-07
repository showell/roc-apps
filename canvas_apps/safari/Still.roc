## A still is a small picture made of polygons, each filled with a flat
## colour or a gradient. It is drawn in its own frame, in units of its height:
## its feet at y 0, y up, and its height 1, with x across from its middle. A
## still that is wider than it is tall, such as a flying bird, has x past 1.
## EmojiStills, CatStills and BirdStills hold the pictures, and StillShapes
## puts them on screen.
import Polygon
import lib.RgbColor

Still := List(Still.Polygon).{

	## A corner of a still's polygon, in the still's frame.
	Vertex : { x : F64, y : F64 }

	## A polygon's gradient as traced, with its two colours and where each
	## sits along it. A linear one runs from `start` to `end`. A radial one
	## spreads over an ellipse about `center`, whose two axes are the steps
	## `axis_u` and `axis_v`.
	Gradient : [
		Linear(
			{
				stops : Polygon.ColorStops,
				start : Still.Vertex,
				end : Still.Vertex,
			},
		),
		Radial(
			{
				stops : Polygon.ColorStops,
				center : Still.Vertex,
				axis_u : Still.Vertex,
				axis_v : Still.Vertex,
			},
		),
	]

	## One polygon of a still: how it is filled, and its corners.
	Polygon : { fill : [Flat(RgbColor), Shaded(Still.Gradient)], points : List(Still.Vertex) }

	## The still's polygons, in the order they are drawn.
	polygons : Still -> List(Still.Polygon)
	polygons = |Still.(still_polygons)| still_polygons

	is_eq : _
}
