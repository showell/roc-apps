## The rider's camera: a pinhole at eye height, looking straight ahead. It
## puts a point in the rider's view onto the screen, and a polygon there once
## it is cut at the camera's near plane.
import Distance
import Lens
import lib.Brush
import lib.Point
import lib.Pixels
import lib.RgbColor
import lib.Shapes
import RiderView

Camera :: [].{

	## The camera's height above the ground.
	eye_height : Distance
	eye_height = Distance.metres(1.2)

	## Where a point in front of the camera lands on the screen, through a
	## lens of `focal_length`.
	project : RiderView.RaisedPointAhead, Pixels -> Point.Point
	project = |p, focal_length| {
		slope_right = p.right().ratio_to(p.forward())
		slope_up = p.height().minus(eye_height).ratio_to(p.forward())
		{
			x: Lens.x_for_slope({ slope: slope_right, focal_length }),
			y: Lens.y_for_slope({ slope: slope_up, focal_length }),
		}
	}

	## How tall something of `height` stands on the screen, `forward` of the
	## camera, through a lens of `focal_length`.
	height_on_screen : { height : Distance, forward : Distance }, Pixels -> Pixels
	height_on_screen = |{ height, forward }, focal_length|
		Lens.height_for_slope({ slope: height.ratio_to(forward), focal_length })

	## An upright object on the screen: where its foot is, and how far up the
	## screen its top is from there. A tree, a still and a billboard all stand
	## this way.
	Upright : { foot : Point.Point, height_on_screen : Pixels }

	## The object standing at `base`, `height` tall, on the screen.
	upright_on_screen : RiderView.RaisedPointAhead,
	{
		height : Distance,
		focal_length : Pixels,
	} -> Camera.Upright
	upright_on_screen = |base, { height, focal_length }| {
		foot = project(base, focal_length)
		top = project(base.at_height(base.height().plus(height)), focal_length)
		{ foot, height_on_screen: foot.y.minus(top.y) }
	}

	## Each of `points` put on the screen, in order, through a lens of focal
	## length `focal_length`.
	projected_points : List(RiderView.RaisedPointAhead), Pixels -> List(Point.Point)
	projected_points = |points, focal_length| points.map(|p| project(p, focal_length))

	## A polygon of one color, in the rider's view.
	FlatPolygon : { color : RgbColor, corners : List(RiderView.RaisedPoint) }

	## A polygon on screen, cut at the near plane, unless it's wholly behind the
	## camera. What is left of a polygon of three corners or more has three or
	## more, so fewer is a bug in the code that asked, and it crashes.
	clipped_polygon : Camera.FlatPolygon, Pixels -> Try(Shapes.Shape, [BehindCamera])
	clipped_polygon = |{ color, corners }, focal_length| {
		in_front = RiderView.clipped_points(corners)
		if in_front.is_empty() {
			Err(BehindCamera)
		} else if in_front.len() < 3 {
			crash "Camera.clipped_polygon: a polygon needs at least three corners"
		} else {
			Ok(
				Polygon({
					corners: projected_points(in_front, focal_length),
					fill: Brush.flat(color),
				}),
			)
		}
	}
}

## `point` past the near plane, which every point in these tests is.
ahead : RiderView.RaisedPoint -> RiderView.RaisedPointAhead
ahead = |point| RiderView.raised_point_ahead(point) ?? crash "a test's point is past the near plane"

screen_point : RiderView.RaisedPoint -> Point.Point
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
			Point.at(480.0, 300.0),
			Point.at(1280.0, 300.0),
			Point.at(480.0, -500.0),
		]

expect Camera.projected_points([], Pixels.of(800.0)).len() == 0
