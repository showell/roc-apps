## These are Ground's checks: how far the earth's curve lowers a point, and
## which patches draw.
app [main!] {
	lib: "../lib/main.roc",
}

import Geom
import Grade
import Ground
import ShapeRead
import lib.Shapes

points : List(Geom.RiderPoint)
points = [
	{ right: 0.0, forward: 0.0 },
	{ right: 3.0, forward: 10.0 },
	{ right: (-5.0), forward: 40.0 },
	{ right: 12.5, forward: 100.0 },
]

on_ground : List(Geom.SpacePoint)
on_ground = points.map(Ground.ground_point)

height_got : List(F64)
height_got = on_ground.map(|point| point.height)

height_want : List(F64)
height_want = [
	0.0,
	(-0.000545),
	(-0.008125),
	(-0.05078125),
]

carry_got : List(F64)
carry_got = [
	point_at(on_ground, 1).right,
	point_at(on_ground, 1).forward,
	point_at(on_ground, 3).right,
	point_at(on_ground, 3).forward,
]

carry_want : List(F64)
carry_want = [3.0, 10.0, 12.5, 100.0]

point_at : List(Geom.SpacePoint), U64 -> Geom.SpacePoint
point_at = |list, i| list.get(i) ?? crash "GroundSpec: an index past the list's end"

quad : List(Geom.RiderPoint)
quad = [
	{ right: (-5.0), forward: 10.0 },
	{ right: 5.0, forward: 10.0 },
	{ right: 5.0, forward: 20.0 },
	{ right: (-5.0), forward: 20.0 },
]

behind : List(Geom.RiderPoint)
behind = [
	{ right: (-5.0), forward: (-10.0) },
	{ right: 5.0, forward: (-10.0) },
	{ right: 5.0, forward: (-20.0) },
	{ right: (-5.0), forward: (-20.0) },
]

two_points : List(Geom.RiderPoint)
two_points = [{ right: (-5.0), forward: 10.0 }, { right: 5.0, forward: 10.0 }]

## A patch of `count` corners, all ahead of the camera.
corners_ahead : I64 -> List(Geom.RiderPoint)
corners_ahead = |count|
	List.from_iter(I64.until(0, count)).map(
		|k| {
			offset = (count - k).to_f64()
			{ right: offset, forward: (10.0 + offset) }
		},
	)

patch_shapes : List(Geom.RiderPoint) -> List(Shapes.Shape)
patch_shapes = |corners| Ground.draw({
	corners,
	color: 3112588,
	cam_focal: 685.5110432362151,
	view_w: 960.0,
})

count_got : List(I64)
count_got = [
	patch_shapes(quad).len().to_i64_wrap(),
	patch_shapes(corners_ahead(8)).len().to_i64_wrap(),
	patch_shapes(corners_ahead(9)).len().to_i64_wrap(),
	patch_shapes(behind).len().to_i64_wrap(),
	patch_shapes(two_points).len().to_i64_wrap(),
]

count_want : List(I64)
count_want = [1, 1, 0, 0, 0]

shape_got : List(I64)
shape_got = {
	shape = patch_shapes(quad).first() ?? crash "GroundSpec: the quad draws one shape"
	[
		ShapeRead.flat_color_of(shape),
		ShapeRead.pts_of(shape).len().to_i64_wrap(),
	]
}

shape_want : List(I64)
shape_want = [3112588, 8]

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "gr-height",
			got: height_got,
			want: height_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "gr-carry ",
			got: carry_got,
			want: carry_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "gr-count ",
			got: count_got,
			want: count_want,
		}),
		Grade.ints({
			name: "gr-shape ",
			got: shape_got,
			want: shape_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
