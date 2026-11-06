## The rider's camera: a pinhole at eye height, looking straight ahead. It
## puts a point in the rider's view onto the screen.
import Geom
import Screen

Camera :: [].{

	## The camera's height above the ground, in metres.
	eye_h : F64
	eye_h = 1.2

	## Where a point in front of the camera lands on the screen, through a
	## lens of focal length `cam_focal` in pixels.
	project : Geom.RaisedPoint, F64 -> Screen.Point
	project = |p, cam_focal| {
		x: (Screen.center_x + ((p.right / p.forward) * cam_focal)),
		y: (Screen.horizon_y - (((p.height - eye_h) / p.forward) * cam_focal)),
	}

	project_all : List(Geom.RaisedPoint), F64 -> List(Screen.Point)
	project_all = |points, cam_focal| points.map(|p| project(p, cam_focal))
}

at : Geom.RaisedPoint -> Screen.Point
at = |point| Camera.project(point, 800.0)

expect at({
	right: 0.0,
	forward: 10.0,
	height: 1.2,
}).x == 480.0
expect at({
	right: 10.0,
	forward: 10.0,
	height: 1.2,
}).x == 1280.0
expect at({
	right: (0.0 - 5.0),
	forward: 10.0,
	height: 1.2,
}).x == 80.0
expect at({
	right: 10.0,
	forward: 5.0,
	height: 1.2,
}).x == 2080.0
expect at({
	right: 0.0,
	forward: 10.0,
	height: 1.2,
}).y == 300.0
expect at({
	right: 0.0,
	forward: 10.0,
	height: 11.2,
}).y == -500.0
expect at({
	right: 0.0,
	forward: 10.0,
	height: 6.2,
}).y == -100.0
expect at({
	right: 0.0,
	forward: 10.0,
	height: 0.2,
}).y == 380.0
expect at({
	right: 0.0,
	forward: 4.0,
	height: 3.2,
}).y == -100.0

# The same point twice as far off is half as far from the screen's middle.
expect at({
	right: 4.0,
	forward: 4.0,
	height: 1.2,
}).x == 1280.0
expect at({
	right: 4.0,
	forward: 8.0,
	height: 1.2,
}).x == 880.0
expect at({
	right: 4.0,
	forward: 16.0,
	height: 1.2,
}).x == 680.0
expect at({
	right: 0.0,
	forward: 4.0,
	height: 5.2,
}).y == -500.0
expect at({
	right: 0.0,
	forward: 8.0,
	height: 5.2,
}).y == -100.0
expect at({
	right: 0.0,
	forward: 16.0,
	height: 5.2,
}).y == 100.0
expect Screen.height == 600.0
expect Camera.eye_h == 1.2

expect
	Camera.project_all(
		[
			{
				right: 0.0,
				forward: 10.0,
				height: 1.2,
			},
			{
				right: 10.0,
				forward: 10.0,
				height: 1.2,
			},
			{
				right: 0.0,
				forward: 10.0,
				height: 11.2,
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
