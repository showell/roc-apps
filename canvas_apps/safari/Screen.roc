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

	## How far past each edge of the screen the backdrop and the skyline reach,
	## so the camera's roll never shows their edges. The roll turns the screen
	## about its middle, and 200 pixels covers a roll of up to 30° either way.
	## Nothing caps the roll, but the ride's leans stay under 18°. It is a whole,
	## even number of pixels, so the skyline's columns, two pixels apart from
	## this far left, land on the screen's own whole pixels.
	roll_margin : Pixels
	roll_margin = Pixels.of(200.0)
}

# At a roll of 30°, the screen's corners turn no further from its middle than
# the margin reaches: up and down, and left and right.
expect {
	roll = 30.0 * F64.pi / 180.0
	half_width = Screen.width.to_f64() / 2.0
	half_height = Screen.height.to_f64() / 2.0
	reach_down = half_width * roll.sin() + half_height * roll.cos()
	reach_across = half_width * roll.cos() + half_height * roll.sin()
	reach_down <= half_height + Screen.roll_margin.to_f64()
		and reach_across <= half_width + Screen.roll_margin.to_f64()
}

# At 31°, the corners would pass the margin up and down.
expect {
	roll = 31.0 * F64.pi / 180.0
	half_width = Screen.width.to_f64() / 2.0
	half_height = Screen.height.to_f64() / 2.0
	half_width * roll.sin() + half_height * roll.cos() > half_height + Screen.roll_margin.to_f64()
}
