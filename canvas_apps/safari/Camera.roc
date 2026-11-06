## The rider's camera: a pinhole at eye height, looking straight ahead. It
## puts a point in the rider's view onto the screen.
import Distance
import Pixels
import Geom
import Screen

Camera :: [].{

	## The camera's height above the ground, in metres.
	eye_h : Distance
	eye_h = Distance.metres(1.2)

	## Where a point in front of the camera lands on the screen, through a
	## lens of focal length `cam_focal` in pixels.
	project : Geom.RaisedPoint, Pixels -> Screen.Point
	project = |p, cam_focal| {
		slope_right = p.right.ratio_to(p.forward)
		slope_up = p.height.minus(eye_h).ratio_to(p.forward)
		{
			x: Screen.center_x.plus(cam_focal.times(slope_right)),
			y: Screen.horizon_y.minus(cam_focal.times(slope_up)),
		}
	}

	projected_points : List(Geom.RaisedPoint), Pixels -> List(Screen.Point)
	projected_points = |points, cam_focal| points.map(|p| project(p, cam_focal))
}

screen_point : Geom.RaisedPoint -> Screen.Point
screen_point = |point| Camera.project(point, Pixels.of(800.0))

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
expect Screen.height.to_f64() == 600.0
expect Camera.eye_h.to_metres() == 1.2

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
		],
		Pixels.of(800.0),
	)
		== [
			Screen.point(480.0, 300.0),
			Screen.point(1280.0, 300.0),
			Screen.point(480.0, -500.0),
		]

expect Camera.projected_points([], Pixels.of(800.0)).len() == 0
