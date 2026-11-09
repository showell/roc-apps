## The screen Safari draws on: its size in pixels, and where the horizon
## crosses it before the camera rolls, and the space the frame leans in once it
## does.
import Angle
import lib.Point
import lib.Pixels
import lib.Brush
import lib.Shapes

Screen :: [].{

	## The distance between two points on the screen.
	distance : { from : Point.Point, to : Point.Point } -> Pixels
	distance = |{ from, to }| {
		dx = from.x.minus(to.x).to_f64()
		dy = from.y.minus(to.y).to_f64()
		Pixels.of((dx * dx + dy * dy).sqrt())
	}

	## How far the farthest of `points` is from `center`, or zero for no
	## points.
	farthest_distance : List(Point.Point), Point.Point -> Pixels
	farthest_distance = |points, center|
		points.fold_rev(
			Pixels.zero,
			|corner, farthest| Screen.distance({ from: corner, to: center }).max(farthest),
		)

	width_px : I64
	width_px = 960

	height_px : I64
	height_px = 600

	## The size again as lengths, for the geometry.
	width : Pixels
	width = Pixels.of(width_px.to_f64())

	height : Pixels
	height = Pixels.of(height_px.to_f64())

	## The middle of the screen, halfway across it and halfway down.
	middle : Point.Point
	middle = { x: width.divided_by(2.0), y: height.divided_by(2.0) }

	## The camera looks at the middle of the screen, across its width.
	center_x : Pixels
	center_x = middle.x

	## The horizon crosses the screen halfway down, by rule: the camera looks
	## level, and a level line of sight lands halfway down the screen. It sits
	## at `middle.y` only because of that choice; a camera tilted up or down
	## would move it.
	horizon_y : Pixels
	horizon_y = height.divided_by(2.0)

	## How far past each edge of the screen the backdrop and the skyline reach,
	## so the camera's roll never shows their edges. The roll turns the screen
	## about its middle, and 200 pixels covers a roll of up to 30° either way.
	## Nothing caps the roll, but the ride's leans stay under 18°. It is a whole,
	## even number of pixels, so the skyline's columns, two pixels apart from
	## this far left, land on the screen's own whole pixels.
	roll_margin : Pixels
	roll_margin = Pixels.of(200.0)

	## The left edge of what the backdrop and the skyline draw: `roll_margin`
	## left of the screen.
	drawn_left : Pixels
	drawn_left = roll_margin.opposite()

	## The right edge of what the backdrop and the skyline draw: `roll_margin`
	## right of the screen.
	drawn_right : Pixels
	drawn_right = width.plus(roll_margin)

	## A rectangle from `top` down to `bottom`, painted with `fill`, from
	## `drawn_left` across to `drawn_right`.
	margin_rect : { top : Pixels, bottom : Pixels }, Brush.Fill -> Shapes.Shape
	margin_rect = |{ top, bottom }, fill|
		Rectangle({
			top_left: { x: drawn_left, y: top },
			width: drawn_right.minus(drawn_left),
			height: bottom.minus(top),
			fill,
		})

	## The rectangle above the horizon, painted with `fill`: from `roll_margin`
	## above the screen down to the horizon, and `roll_margin` past each side.
	above_horizon_rect : Brush.Fill -> Shapes.Shape
	above_horizon_rect = |fill|
		margin_rect({ top: roll_margin.opposite(), bottom: horizon_y }, fill)

	## The space the whole frame is drawn in when the camera rolls by `roll`:
	## the screen turns by minus the roll about its middle.
	leaned_by : Angle.Lean -> Shapes.Space
	leaned_by = |roll| {
		Shapes.world_space({
			target: middle,
			offset: middle,
			rotation: 0.0 - roll.to_degrees(),
			zoom: 1.0,
		})
	}
}

expect Screen.distance({ from: Point.at(3.0, 4.0), to: Point.at(0.0, 0.0) }).to_f64() == 5.0
expect Screen.distance({ from: Point.at(0.0, 0.0), to: Point.at(3.0, 4.0) }).to_f64() == 5.0
expect Screen.distance({ from: Point.at(0.0, 0.0), to: Point.at(0.0, 0.0) }).to_f64() == 0.0

expect
	Screen.farthest_distance(
		[
			Point.at(3.0, 4.0),
			Point.at(6.0, 8.0),
			Point.at(0.0, 0.0),
			Point.at(7.0, 4.0),
		],
		Point.at(0.0, 0.0),
	).to_f64()
		== 10.0

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
