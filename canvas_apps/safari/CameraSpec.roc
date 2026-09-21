# CameraSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Camera
import Geom
import Grade
import Text

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

at : F64, F64, F64 -> Camera.ScreenPt
at = |right, forward, height| Camera.project({ right: right, forward: forward, height: height }, 800.0, 960.0)

x_got : List(F64)
x_got = [at(0.0, 10.0, 1.2).x, at(10.0, 10.0, 1.2).x, at((0.0 - 5.0), 10.0, 1.2).x, at(10.0, 5.0, 1.2).x]

x_want : List(F64)
x_want = [480.0, 1280.0, 80.0, 2080.0]

y_got : List(F64)
y_got = [at(0.0, 10.0, 1.2).y, at(0.0, 10.0, 11.2).y, at(0.0, 10.0, 6.2).y, at(0.0, 10.0, 0.2).y, at(0.0, 4.0, 3.2).y]

y_want : List(F64)
y_want = [300.0, (-500.0), (-100.0), 380.0, (-100.0)]

depth_got : List(F64)
depth_got = [at(4.0, 4.0, 1.2).x, at(4.0, 8.0, 1.2).x, at(4.0, 16.0, 1.2).x, at(0.0, 4.0, 5.2).y, at(0.0, 8.0, 5.2).y, at(0.0, 16.0, 5.2).y]

depth_want : List(F64)
depth_want = [1280.0, 880.0, 680.0, (-500.0), (-100.0), 100.0]

fixed_got : List(F64)
fixed_got = [Camera.camera_h, Camera.eye_h]

fixed_want : List(F64)
fixed_want = [600.0, 1.2]

three : List(Geom.Vec3)
three = [{ right: 0.0, forward: 10.0, height: 1.2 }, { right: 10.0, forward: 10.0, height: 1.2 }, { right: 0.0, forward: 10.0, height: 11.2 }]

all_got : List(F64)
all_got = ({
	sp = Camera.project_all(three, 800.0, 960.0, 0)
	[I64.to_f64(U64.to_i64_wrap(List.len(sp))), (List.get(sp, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).x, (List.get(sp, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).x, (List.get(sp, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).y, I64.to_f64(U64.to_i64_wrap(List.len(Camera.project_all([], 800.0, 960.0, 0))))]
})

all_want : List(F64)
all_want = [3.0, 480.0, 1280.0, (-500.0), 0.0]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_reals([24, 26, 73, 36, 2, 2, 2, 2], x_got, x_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([24, 26, 73, 30, 2, 2, 2, 2], y_got, y_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([24, 26, 73, 22, 13, 31, 14, 20], depth_got, depth_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([24, 26, 73, 28, 17, 36, 13, 22], fixed_got, fixed_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([24, 26, 73, 15, 23, 23, 2, 2], all_got, all_want, 0.0)))
	Ok({})
}
