## The screen Safari draws on: its size in pixels, and where the horizon and
## the top of the grass cross it before the camera rolls.
Screen :: [].{

	## A point on the screen, in pixels from its top left corner.
	Point : { x : F64, y : F64 }

	width_px : I64
	width_px = 960

	height_px : I64
	height_px = 600

	## The size again as floats, for the geometry.
	width : F64
	width = I64.to_f64(width_px)

	height : F64
	height = I64.to_f64(height_px)

	## The camera looks at the middle of the screen, across its width.
	center_x : F64
	center_x = width / 2.0

	## The horizon crosses the middle of the screen.
	horizon_y : F64
	horizon_y = height / 2.0

	## The grass starts a pixel above the horizon, so no seam shows between
	## the two under the roll.
	grass_top_y : F64
	grass_top_y = horizon_y - 1.0
}
