## These are Camera's checks: where a point lands across and down the
## screen, how depth shrinks it, and a list projected at once.
app [main!] {
	lib: "../lib/main.roc",
}

import Camera
import Geom
import Grade
import Screen

view : Camera.View
view = { cam_focal: 800.0, view_w: 960.0 }

at : F64, F64, F64 -> Camera.ScreenPt
at = |
	right,
	forward,
	height,
| Camera.project(
	{
		right,
		forward,
		height,
	},
	view,
)

x_got : List(F64)
x_got = [
	at(
		0.0,
		10.0,
		1.2,
	).x,
	at(
		10.0,
		10.0,
		1.2,
	).x,
	at(
		(0.0 - 5.0),
		10.0,
		1.2,
	).x,
	at(
		10.0,
		5.0,
		1.2,
	).x,
]

x_want : List(F64)
x_want = [480.0, 1280.0, 80.0, 2080.0]

y_got : List(F64)
y_got = [
	at(
		0.0,
		10.0,
		1.2,
	).y,
	at(
		0.0,
		10.0,
		11.2,
	).y,
	at(
		0.0,
		10.0,
		6.2,
	).y,
	at(
		0.0,
		10.0,
		0.2,
	).y,
	at(
		0.0,
		4.0,
		3.2,
	).y,
]

y_want : List(F64)
y_want = [
	300.0,
	(-500.0),
	(-100.0),
	380.0,
	(-100.0),
]

depth_got : List(F64)
depth_got = [
	at(
		4.0,
		4.0,
		1.2,
	).x,
	at(
		4.0,
		8.0,
		1.2,
	).x,
	at(
		4.0,
		16.0,
		1.2,
	).x,
	at(
		0.0,
		4.0,
		5.2,
	).y,
	at(
		0.0,
		8.0,
		5.2,
	).y,
	at(
		0.0,
		16.0,
		5.2,
	).y,
]

depth_want : List(F64)
depth_want = [
	1280.0,
	880.0,
	680.0,
	(-500.0),
	(-100.0),
	100.0,
]

fixed_got : List(F64)
fixed_got = [Screen.height, Camera.eye_h]

fixed_want : List(F64)
fixed_want = [600.0, 1.2]

ahead_right_above : List(Geom.Vec3)
ahead_right_above = [
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
]

all_got : List(F64)
all_got = {
	projected = Camera.project_all(ahead_right_above, view)
	ahead = projected.get(0) ?? crash "CameraSpec: three points project to three"
	right = projected.get(1) ?? crash "CameraSpec: three points project to three"
	above = projected.get(2) ?? crash "CameraSpec: three points project to three"
	[
		I64.to_f64(projected.len().to_i64_wrap()),
		ahead.x,
		right.x,
		above.y,
		I64.to_f64(Camera.project_all([], view).len().to_i64_wrap()),
	]
}

all_want : List(F64)
all_want = [
	3.0,
	480.0,
	1280.0,
	(-500.0),
	0.0,
]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "cm-x    ",
			got: x_got,
			want: x_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "cm-y    ",
			got: y_got,
			want: y_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "cm-depth",
			got: depth_got,
			want: depth_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "cm-fixed",
			got: fixed_got,
			want: fixed_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "cm-all  ",
			got: all_got,
			want: all_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
