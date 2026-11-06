## The screen Safari draws on: its size in pixels, and where the horizon and
## the top of the grass cross it before the camera rolls.
import Pixels

Screen :: [].{

	## A point on the screen, in pixels from its top left corner. Either can be
	## negative, or past the far edge, for a point off the screen.
	Point : { x : Pixels, y : Pixels }

	point : F64, F64 -> Screen.Point
	point = |x, y| { x: Pixels.of(x), y: Pixels.of(y) }

	width_px : I64
	width_px = 960

	height_px : I64
	height_px = 600

	## The size again as lengths, for the geometry.
	width : Pixels
	width = Pixels.of(width_px.to_f64())

	height : Pixels
	height = Pixels.of(height_px.to_f64())

	## The camera looks at the middle of the screen, across its width.
	center_x : Pixels
	center_x = width.divided_by(2.0)

	## The horizon crosses the middle of the screen.
	horizon_y : Pixels
	horizon_y = height.divided_by(2.0)

	## The grass starts a pixel above the horizon, so no seam shows between
	## the two under the roll.
	grass_top_y : Pixels
	grass_top_y = horizon_y.minus(Pixels.of(1.0))
}
