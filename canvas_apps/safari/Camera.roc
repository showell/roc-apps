## The rider's camera: a pinhole at eye height, looking straight ahead. It
## puts a point in the rider's view onto the screen.
import Distance
import Pixels
import Geom
import Polygon
import Screen
import lib.RgbColor
import lib.Shapes

Camera :: [].{

	## The camera's height above the ground, in metres.
	eye_height : Distance
	eye_height = Distance.metres(1.2)

	## Where a point in front of the camera lands on the screen, through a
	## lens of focal length `cam_focal` in pixels.
	project : Geom.AheadPoint, Pixels -> Screen.Point
	project = |p, cam_focal| {
		slope_right = p.right().portion(p.forward())
		slope_up = p.height().minus(eye_height).portion(p.forward())
		{
			x: Screen.center_x.plus(cam_focal.times(slope_right)),
			y: Screen.horizon_y.minus(cam_focal.times(slope_up)),
		}
	}

	## How tall something of `height` stands on the screen, `forward` of the
	## camera, through a lens of focal length `cam_focal` in pixels.
	height_on_screen : { height : Distance, forward : Distance }, Pixels -> Pixels
	height_on_screen = |{ height, forward }, cam_focal| cam_focal.times(height.portion(forward))

	projected_points : List(Geom.AheadPoint), Pixels -> List(Screen.Point)
	projected_points = |points, cam_focal| points.map(|p| project(p, cam_focal))

	## A polygon of one color, in the rider's view.
	FlatPolygon : { color : RgbColor, corners : List(Geom.RaisedPoint) }

	## A polygon on screen, cut at the near plane, unless it's wholly behind the
	## camera.
	clipped_polygon : Camera.FlatPolygon, Pixels -> Try(Shapes.Shape, [BehindCamera])
	clipped_polygon = |{ color, corners }, cam_focal| {
		in_front = Geom.clipped_points(corners)
		if in_front.is_empty() {
			Err(BehindCamera)
		} else {
			Ok(Polygon.flat_polygon(color, projected_points(in_front, cam_focal)))
		}
	}
}

## `point` past the near plane, which every point in these tests is.
ahead : Geom.RaisedPoint -> Geom.AheadPoint
ahead = |point| Geom.ahead_point(point) ?? crash "a test's point is past the near plane"

screen_point : Geom.RaisedPoint -> Screen.Point
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
		|(height, forward, cam_focal, on_screen)|
			Camera.height_on_screen(
				{ height: Distance.metres(height), forward: Distance.metres(forward) },
				Pixels.of(cam_focal),
			)
				== Pixels.of(on_screen),
	)

expect Screen.height.to_f64() == 600.0
expect Camera.eye_height.to_metres() == 1.2

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

# A triangle at these distances ahead, on the ground.
sample_clipped_polygon : List(F64) -> Try(Shapes.Shape, [BehindCamera])
sample_clipped_polygon = |forwards|
	Camera.clipped_polygon(
		{
			color: RgbColor.of(0x2F7E8C),
			corners: forwards.map(
				|forward| {
					right: Distance.metres(forward),
					forward: Distance.metres(forward),
					height: Distance.zero,
				},
			),
		},
		Pixels.of(800.0),
	)

# The number of coordinates a triangle's polygon holds, 2 to a corner.
clipped_coordinate_count : List(F64) -> U64
clipped_coordinate_count = |forwards|
	match sample_clipped_polygon(forwards) {
		Ok(Poly(polygon)) => polygon.coordinates.len()
		_ => 0
	}

expect clipped_coordinate_count([5.0, 6.0, 7.0]) == 6
expect clipped_coordinate_count([-1.0, 5.0, 6.0]) == 8
expect clipped_coordinate_count([-3.0, -2.0, -1.0]) == 0
expect sample_clipped_polygon([-3.0, -2.0, -1.0]).is_err()
