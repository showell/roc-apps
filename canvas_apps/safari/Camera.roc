## The rider's camera: a pinhole at eye height, looking straight ahead. It
## puts a point in the rider's view onto the screen.
import Distance
import Geom
import Screen

Camera :: [].{

	## The camera's height above the ground, in metres.
	eye_h : Distance
	eye_h = Distance.metres(1.2)

	## Where a point in front of the camera lands on the screen, through a
	## lens of focal length `cam_focal` in pixels.
	project : Geom.RaisedPoint, F64 -> Screen.Point
	project = |p, cam_focal| {
		x: (Screen.center_x + (p.right.ratio_to(p.forward) * cam_focal)),
		y: (Screen.horizon_y - (p.height.minus(eye_h).ratio_to(p.forward) * cam_focal)),
	}

	project_all : List(Geom.RaisedPoint), F64 -> List(Screen.Point)
	project_all = |points, cam_focal| points.map(|p| project(p, cam_focal))
}

at : Geom.RaisedPoint -> Screen.Point
at = |point| Camera.project(point, 800.0)

expect at({
	right: Distance.metres(0.0),
	forward: Distance.metres(10.0),
	height: Distance.metres(1.2),
}).x == 480.0
expect at({
	right: Distance.metres(10.0),
	forward: Distance.metres(10.0),
	height: Distance.metres(1.2),
}).x == 1280.0
expect at({
	right: Distance.metres(0.0 - 5.0),
	forward: Distance.metres(10.0),
	height: Distance.metres(1.2),
}).x == 80.0
expect at({
	right: Distance.metres(10.0),
	forward: Distance.metres(5.0),
	height: Distance.metres(1.2),
}).x == 2080.0
expect at({
	right: Distance.metres(0.0),
	forward: Distance.metres(10.0),
	height: Distance.metres(1.2),
}).y == 300.0
expect at({
	right: Distance.metres(0.0),
	forward: Distance.metres(10.0),
	height: Distance.metres(11.2),
}).y == -500.0
expect at({
	right: Distance.metres(0.0),
	forward: Distance.metres(10.0),
	height: Distance.metres(6.2),
}).y == -100.0
expect at({
	right: Distance.metres(0.0),
	forward: Distance.metres(10.0),
	height: Distance.metres(0.2),
}).y == 380.0
expect at({
	right: Distance.metres(0.0),
	forward: Distance.metres(4.0),
	height: Distance.metres(3.2),
}).y == -100.0

# The same point twice as far off is half as far from the screen's middle.
expect at({
	right: Distance.metres(4.0),
	forward: Distance.metres(4.0),
	height: Distance.metres(1.2),
}).x == 1280.0
expect at({
	right: Distance.metres(4.0),
	forward: Distance.metres(8.0),
	height: Distance.metres(1.2),
}).x == 880.0
expect at({
	right: Distance.metres(4.0),
	forward: Distance.metres(16.0),
	height: Distance.metres(1.2),
}).x == 680.0
expect at({
	right: Distance.metres(0.0),
	forward: Distance.metres(4.0),
	height: Distance.metres(5.2),
}).y == -500.0
expect at({
	right: Distance.metres(0.0),
	forward: Distance.metres(8.0),
	height: Distance.metres(5.2),
}).y == -100.0
expect at({
	right: Distance.metres(0.0),
	forward: Distance.metres(16.0),
	height: Distance.metres(5.2),
}).y == 100.0
expect Screen.height == 600.0
expect Camera.eye_h.to_metres() == 1.2

expect
	Camera.project_all(
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
		800.0,
	)
		== [
			{ x: 480.0, y: 300.0 },
			{ x: 1280.0, y: 300.0 },
			{ x: 480.0, y: -500.0 },
		]

expect Camera.project_all([], 800.0).len() == 0
