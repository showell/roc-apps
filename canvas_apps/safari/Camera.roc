## The rider's camera: a pinhole at eye height, looking straight ahead. It
## puts a point in the rider's view onto the screen.
import Distance
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
			x: Lens.x_for_slope({ slope: slope_right, focal_length }),
			y: Screen.horizon_y.minus(focal_length.times(slope_up)),
		}
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
