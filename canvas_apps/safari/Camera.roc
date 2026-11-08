## The rider's camera: a pinhole at eye height, looking straight ahead. It
## puts a point in the rider's view onto the screen.
import Angle
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
			x: x_for_slope(slope_right, cam_focal),
			y: Screen.horizon_y.minus(cam_focal.times(slope_up)),
		}
	}

	## The screen's x for something infinitely far away, `turn` to the right of
	## where the camera faces, through a lens of `cam_focal`. The turn stays
	## under a quarter turn either way, in front of the camera.
	x_for_turn : { turn : Angle.Turn, cam_focal : Pixels } -> Pixels
	x_for_turn = |{ turn, cam_focal }| x_for_slope(turn.to_radians().tan(), cam_focal)

	## How far to the right of where the camera faces the screen's `x` looks,
	## through a lens of `cam_focal`: the way back from `x_for_turn`.
	turn_at_x : { x : Pixels, cam_focal : Pixels } -> Angle.Turn
	turn_at_x = |{ x, cam_focal }| {
		slope = x.minus(Screen.center_x).portion(cam_focal)
		Angle.Turn.radians(slope.atan())
	}

	## How tall something of `height` stands on the screen, `forward` of the
	## camera, through a lens of focal length `cam_focal` in pixels.
	height_on_screen : { height : Distance, forward : Distance }, Pixels -> Pixels
	height_on_screen = |{ height, forward }, cam_focal| cam_focal.times(height.portion(forward))

	## Where an upright object stands on the screen: `foot`, its foot at `base`
	## put on the screen, and `height_on_screen`, how far up the screen its top
	## is from there, `height` above `base`. A tree, a still and a billboard all
	## stand this way.
	upright_on_screen : Geom.AheadPoint,
	{
		height : Distance,
		cam_focal : Pixels,
	} -> { foot : Screen.Point, height_on_screen : Pixels }
	upright_on_screen = |base, { height, cam_focal }| {
		foot = project(base, cam_focal)
		top = project(base.at_height(base.height().plus(height)), cam_focal)
		{ foot, height_on_screen: foot.y.minus(top.y) }
	}

	## Each of `points` put on the screen, in order, through a lens of focal
	## length `cam_focal`.
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
			Ok(Polygon.flat_polygon(projected_points(in_front, cam_focal), color))
		}
	}
}

## The pinhole's rule across the screen: the x for a line of sight that goes
## `slope` to the right for every unit forward, through a lens of `cam_focal`.
## A near point's slope and a far direction's both land here.
x_for_slope : F64, Pixels -> Pixels
x_for_slope = |slope, cam_focal| Screen.center_x.plus(cam_focal.times(slope))

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

## The screen's x at a turn of `radians`, through a lens of 800 pixels.
x_at_turn : F64 -> Pixels
x_at_turn = |radians| {
	turn = Angle.Turn.radians(radians)
	Camera.x_for_turn({ turn, cam_focal: Pixels.of(800.0) })
}

# Straight ahead is the middle of the screen, a turn to the right lands right of
# it, and a turn to the left left of it.
expect x_at_turn(0.0) == Screen.center_x
expect x_at_turn(0.3) > Screen.center_x
expect x_at_turn(-0.3) < Screen.center_x
expect Camera.turn_at_x({ x: Screen.center_x, cam_focal: Pixels.of(800.0) }).to_radians() == 0.0

# The turn at an x is the way back from the x at a turn.
expect
	[-1.2, -0.3, 0.0, 0.4, 1.3].all(
		|radians| {
			back = Camera.turn_at_x({ x: x_at_turn(radians), cam_focal: Pixels.of(800.0) })
			(back.to_radians() - radians).abs() <= 0.000000001
		},
	)

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
