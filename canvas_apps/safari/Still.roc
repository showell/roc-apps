## A still is a small picture made of polygons, each filled with a flat
## colour or a gradient. It is drawn in its own frame, in units of its height:
## its feet at y 0, y up, and its height 1, with x across from its middle. A
## still that is wider than it is tall, such as a flying bird, has x past 1.
## EmojiStills, CatStills and BirdStills hold the pictures, and StillShapes
## puts them on screen.
import Fraction
import lib.ArgbColor
import lib.RgbColor

Still :: List(Still.Polygon).{

	## The still made of `polygons`, drawn in their order.
	of : List(Still.Polygon) -> Still
	of = |polygons| Still.(polygons)

	## A place in the still's frame: a corner of a polygon, or where a
	## gradient starts, ends or is centred.
	Point : { x : F64, y : F64 }

	## A step across the still's frame, a direction and a length but not a
	## place: one of a radial gradient's axes, measured from its center.
	Step : { x : F64, y : F64 }

	## A gradient's two colours, and where each sits along it: the start
	## colour up to `start_offset`, the end colour from `end_offset`, and a
	## mix of the two between.
	ColorStops : {
		start_color : ArgbColor,
		end_color : ArgbColor,
		start_offset : Fraction,
		end_offset : Fraction,
	}

	## A polygon's gradient as traced, with its two colours and where each
	## sits along it. A linear one runs from `start` to `end`. A radial one
	## spreads over an ellipse about `center`, whose two axes are the steps
	## `axis_u` and `axis_v`.
	Gradient : [
		Linear(
			{
				stops : Still.ColorStops,
				start : Still.Point,
				end : Still.Point,
			},
		),
		Radial(
			{
				stops : Still.ColorStops,
				center : Still.Point,
				axis_u : Still.Step,
				axis_v : Still.Step,
			},
		),
	]

	## How a polygon of a still is filled: with one colour, or with a gradient.
	Fill : [Flat(RgbColor), Shaded(Still.Gradient)]

	## One polygon of a still: how it is filled, and its corners.
	Polygon : { fill : Still.Fill, points : List(Still.Point) }

	## The still's polygons, in the order they are drawn.
	polygons : Still -> List(Still.Polygon)
	polygons = |Still.(still_polygons)| still_polygons

	is_eq : _
}
