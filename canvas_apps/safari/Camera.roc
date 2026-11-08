## The rider's camera: a pinhole at eye height, looking straight ahead. It
## puts a point in the rider's view onto the screen.
import Angle
import Distance
import FarHeight
import Lens
import Pixels
import RiderView
import Screen

Camera :: [].{

	## The camera's height above the ground, in metres.
	eye_height : Distance
	eye_height = Distance.metres(1.2)

	## Where a point in front of the camera lands on the screen, through a
	## lens of `focal_length` in pixels.
	project : RiderView.RaisedPointAhead, Pixels -> Screen.Point
	project = |p, focal_length| {
		slope_right = p.right().ratio_to(p.forward())
		slope_up = p.height().minus(eye_height).ratio_to(p.forward())
		{
			x: x_for_slope(slope_right, focal_length),
			y: Screen.horizon_y.minus(focal_length.times(slope_up)),
		}
	}

	## Where something infinitely far away lands on the screen, through a lens
	## of `focal_length`: `turn` to the right of where the camera faces, and
	## `height` above the horizon. This is the one projection for far
	## directions, the sun's and the skyline's. A far height is an elevation as
	## the resting lens holds it, its tangent times the resting focal length
	## (`Lens.height_at_elevation`), so both axes follow one rule: the focal
	## length times the tangent of the angle off the middle of the view. The
	## height isn't stretched toward the screen's sides, as a pinhole would
	## stretch it, so a far height stays level across the view as the rider
	## turns. The turn stays under a quarter turn either way, in front of the
	## camera.
	far_point : {
		turn : Angle.Turn,
		height : FarHeight,
		focal_length : Pixels,
	} -> Screen.Point
	far_point = |{ turn, height, focal_length }| {
		x: x_for_slope(turn.to_radians().tan(), focal_length),
		y: Lens.y_for_height({ height, focal_length }),
	}

	## How far to the right of where the camera faces the screen's `x` looks,
	## through a lens of `focal_length`: the way back from `far_point`'s x.
	turn_at_x : { x : Pixels, focal_length : Pixels } -> Angle.Turn
	turn_at_x = |{ x, focal_length }| {
		slope = x.minus(Screen.center_x).ratio_to(focal_length)
		Angle.Turn.radians(slope.atan())
	}

	## How tall something of `height` stands on the screen, `forward` of the
	## camera, through a lens of `focal_length` in pixels.
	height_on_screen : { height : Distance, forward : Distance }, Pixels -> Pixels
	height_on_screen = |{ height, forward }, focal_length|
		focal_length.times(height.ratio_to(forward))

	## Where an upright object stands on the screen: `foot`, its foot at `base`
	## put on the screen, and `height_on_screen`, how far up the screen its top
	## is from there, `height` above `base`. A tree, a still and a billboard all
	## stand this way.
	upright_on_screen : RiderView.RaisedPointAhead,
	{
		height : Distance,
		focal_length : Pixels,
	} -> { foot : Screen.Point, height_on_screen : Pixels }
	upright_on_screen = |base, { height, focal_length }| {
		foot = project(base, focal_length)
		top = project(base.at_height(base.height().plus(height)), focal_length)
		{ foot, height_on_screen: foot.y.minus(top.y) }
	}

	## Each of `points` put on the screen, in order, through a lens of focal
	## length `focal_length`.
	projected_points : List(RiderView.RaisedPointAhead), Pixels -> List(Screen.Point)
	projected_points = |points, focal_length| points.map(|p| project(p, focal_length))
}

## The pinhole's rule across the screen: the x for a line of sight that goes
## `slope` to the right for every unit forward, through a lens of `focal_length`.
## A near point's slope and a far direction's both land here.
x_for_slope : F64, Pixels -> Pixels
x_for_slope = |slope, focal_length| Screen.center_x.plus(focal_length.times(slope))

## `point` past the near plane, which every point in these tests is.
ahead : RiderView.RaisedPoint -> RiderView.RaisedPointAhead
ahead = |point| RiderView.raised_point_ahead(point) ?? crash "a test's point is past the near plane"

screen_point : RiderView.RaisedPoint -> Screen.Point
screen_point = |point| Camera.project(ahead(point), Pixels.of(800.0))

expect screen_point({
	right: Distance.metres(0.0),
	forward: Distance.metres(10.0),
	height: Distance.metres(1.2),
}).x.to_f64() == 480.0
expect screen_point({
	right: Distance.metres(10.0),
	forward: Distance.metres(10.0),
	height: Distance.metres(1.2),
}).x.to_f64() == 1280.0
expect screen_point({
	right: Distance.metres(-5.0),
	forward: Distance.metres(10.0),
	height: Distance.metres(1.2),
}).x.to_f64() == 80.0
expect screen_point({
	right: Distance.metres(10.0),
	forward: Distance.metres(5.0),
	height: Distance.metres(1.2),
}).x.to_f64() == 2080.0
expect screen_point({
	right: Distance.metres(0.0),
	forward: Distance.metres(10.0),
	height: Distance.metres(1.2),
}).y.to_f64() == 300.0
expect screen_point({
	right: Distance.metres(0.0),
	forward: Distance.metres(10.0),
	height: Distance.metres(11.2),
}).y.to_f64() == -500.0
expect screen_point({
	right: Distance.metres(0.0),
	forward: Distance.metres(10.0),
	height: Distance.metres(6.2),
}).y.to_f64() == -100.0
expect screen_point({
	right: Distance.metres(0.0),
	forward: Distance.metres(10.0),
	height: Distance.metres(0.2),
}).y.to_f64() == 380.0
expect screen_point({
	right: Distance.metres(0.0),
	forward: Distance.metres(4.0),
	height: Distance.metres(3.2),
}).y.to_f64() == -100.0

# The same point twice as far off is half as far from the screen's middle.
expect screen_point({
	right: Distance.metres(4.0),
	forward: Distance.metres(4.0),
	height: Distance.metres(1.2),
}).x.to_f64() == 1280.0
expect screen_point({
	right: Distance.metres(4.0),
	forward: Distance.metres(8.0),
	height: Distance.metres(1.2),
}).x.to_f64() == 880.0
expect screen_point({
	right: Distance.metres(4.0),
	forward: Distance.metres(16.0),
	height: Distance.metres(1.2),
}).x.to_f64() == 680.0
expect screen_point({
	right: Distance.metres(0.0),
	forward: Distance.metres(4.0),
	height: Distance.metres(5.2),
}).y.to_f64() == -500.0
expect screen_point({
	right: Distance.metres(0.0),
	forward: Distance.metres(8.0),
	height: Distance.metres(5.2),
}).y.to_f64() == -100.0
expect screen_point({
	right: Distance.metres(0.0),
	forward: Distance.metres(16.0),
	height: Distance.metres(5.2),
}).y.to_f64() == 100.0
expect
	[
		(1.0, 4.0, 800.0, 200.0),
		(1.0, 8.0, 800.0, 100.0),
		(2.0, 8.0, 800.0, 200.0),
		(1.0, 4.0, 400.0, 100.0),
	].all(
		|(height, forward, focal_length, on_screen)|
			Camera.height_on_screen(
				{ height: Distance.metres(height), forward: Distance.metres(forward) },
				Pixels.of(focal_length),
			)
				== Pixels.of(on_screen),
	)

expect
	Camera.projected_points(
		[
			{
				right: Distance.metres(0.0),
				forward: Distance.metres(10.0),
				height: Distance.metres(1.2),
			},
			{
				right: Distance.metres(10.0),
				forward: Distance.metres(10.0),
				height: Distance.metres(1.2),
			},
			{
				right: Distance.metres(0.0),
				forward: Distance.metres(10.0),
				height: Distance.metres(11.2),
			},
		].map(ahead),
		Pixels.of(800.0),
	)
		== [
			Screen.point(480.0, 300.0),
			Screen.point(1280.0, 300.0),
			Screen.point(480.0, -500.0),
		]

expect Camera.projected_points([], Pixels.of(800.0)).len() == 0

## The screen's x at a turn of `radians`, through the lens at rest.
x_at_turn : F64 -> Pixels
x_at_turn = |radians| {
	turn = Angle.Turn.radians(radians)
	Camera.far_point({ turn, height: FarHeight.zero, focal_length: Lens.resting_focal }).x
}

# A far direction at an elevation lands the focal length times the elevation's
# tangent above the horizon through any lens, as a turn lands the focal length
# times its tangent beside the middle: the sun's elevation and the skyline's far
# heights are one measure on the screen.
expect
	[
		(10.0, 600.0),
		(-4.0, 600.0),
		(25.0, 300.0),
	].all(
		|(degrees, focal)| {
			elevation = Angle.Turn.degrees(degrees)
			height = Lens.height_at_elevation(elevation)
			got = Camera.far_point({
				turn: Angle.straight_ahead,
				height,
				focal_length: Pixels.of(focal),
			})
			want = Screen.horizon_y.minus(Pixels.of(focal * elevation.to_radians().tan()))
			got.y.minus(want).abs() <= Pixels.of(0.000000001) and got.x == Screen.center_x
		},
	)

# Straight ahead is the middle of the screen, a turn to the right lands right of
# it, and a turn to the left left of it.
expect x_at_turn(0.0) == Screen.center_x
expect x_at_turn(0.3) > Screen.center_x
expect x_at_turn(-0.3) < Screen.center_x
expect Camera.turn_at_x({ x: Screen.center_x, focal_length: Pixels.of(800.0) }).to_radians() == 0.0

# The turn at an x is the way back from the x at a turn.
expect
	[-1.2, -0.3, 0.0, 0.4, 1.3].all(
		|radians| {
			back = Camera.turn_at_x({ x: x_at_turn(radians), focal_length: Lens.resting_focal })
			(back.to_radians() - radians).abs() <= 0.000000001
		},
	)
