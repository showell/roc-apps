## ShapeRead answers the spec apps' questions about what a drawing module
## built. A question put to the wrong kind of shape crashes, so a spec that
## expected a flat polygon can't pass on something else.
import lib.Brush
import lib.Shapes

ShapeRead :: [].{

	## A polygon's points, flat as x0, y0, x1, y1, ...
	pts_of : Shapes.Shape -> List(F64)
	pts_of = |shape| polygon_of(shape).pts

	## A flat polygon's colour, as 0xRRGGBB.
	flat_color_of : Shapes.Shape -> I64
	flat_color_of = |shape|
		match polygon_of(shape).fill {
			Flat(color) => {
				red = F64.to_i64_wrap(color.r)
				green = F64.to_i64_wrap(color.g)
				blue = F64.to_i64_wrap(color.b)
				red * 65536 + green * 256 + blue
			}
			Skip | Span(_) | Radial(_) | Linear(_) | Ellipse(_) | Glow(_) =>
				crash "ShapeRead.flat_color_of: this polygon is not flat"
		}
}

polygon_of : Shapes.Shape -> { pts : List(F64), fill : Brush.Fill }
polygon_of = |shape|
	match shape {
		Poly(polygon) => polygon
		Pieces(_) | Disc(_) | Rect(_) | Blend(_) | View(_) | Image(_) =>
			crash "ShapeRead.polygon_of: this shape is not a polygon"
	}
