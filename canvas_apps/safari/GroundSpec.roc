## These are Ground's checks: how far the earth's curve lowers a point, and
## which patches draw.
app [main!] {
	lib: "../lib/main.roc",
}

import Geom
import Grade
import Ground
import Paint

points : List(Geom.RiderPt)
points = [
	{ right: 0.0, forward: 0.0 },
	{ right: 3.0, forward: 10.0 },
	{ right: (-5.0), forward: 40.0 },
	{ right: 12.5, forward: 100.0 },
]

on_ground : List(Geom.Vec3)
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

point_at : List(Geom.Vec3), U64 -> Geom.Vec3
point_at = |list, i| list.get(i) ?? crash "GroundSpec: an index past the list's end"

quad : List(Geom.RiderPt)
quad = [
	{ right: (-5.0), forward: 10.0 },
	{ right: 5.0, forward: 10.0 },
	{ right: 5.0, forward: 20.0 },
	{ right: (-5.0), forward: 20.0 },
]

behind : List(Geom.RiderPt)
behind = [
	{ right: (-5.0), forward: (-10.0) },
	{ right: 5.0, forward: (-10.0) },
	{ right: 5.0, forward: (-20.0) },
	{ right: (-5.0), forward: (-20.0) },
]

two_points : List(Geom.RiderPt)
two_points = [{ right: (-5.0), forward: 10.0 }, { right: 5.0, forward: 10.0 }]

## A patch of `count` corners, all ahead of the camera.
corners_ahead : I64 -> List(Geom.RiderPt)
corners_ahead = |count|
	List.from_iter(I64.until(0, count)).map(
		|k| {
			offset = (count - k).to_f64()
			{ right: offset, forward: (10.0 + offset) }
		},
	)

patch_commands : List(Geom.RiderPt) -> List(Paint.DrawCmd)
patch_commands = |corners| Ground.draw({
	corners,
	color: 3112588,
	cam_focal: 685.5110432362151,
	view_w: 960.0,
})

count_got : List(I64)
count_got = [
	patch_commands(quad).len().to_i64_wrap(),
	patch_commands(corners_ahead(8)).len().to_i64_wrap(),
	patch_commands(corners_ahead(9)).len().to_i64_wrap(),
	patch_commands(behind).len().to_i64_wrap(),
	patch_commands(two_points).len().to_i64_wrap(),
]

count_want : List(I64)
count_want = [1, 1, 0, 0, 0]

cmd_got : List(I64)
cmd_got = {
	cmd = patch_commands(quad).first() ?? crash "GroundSpec: the quad draws one command"
	[
		cmd.tag,
		cmd.color,
		cmd.color2,
		cmd.pts.len().to_i64_wrap(),
		cmd.geom.len().to_i64_wrap(),
	]
}

cmd_want : List(I64)
cmd_want = [0, 3112588, 0, 8, 0]

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
			name: "gr-cmd   ",
			got: cmd_got,
			want: cmd_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
