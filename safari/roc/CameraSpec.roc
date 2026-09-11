# CameraSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Camera
import Geom
import Grade
import Tuple

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

eq_tup2 : Tuple.Tup2(a, b), Tuple.Tup2(a, b) -> Bool
eq_tup2 = |ex, ey| (match ex {
	MkTup2(exf0, exf1) => (match ey {
		MkTup2(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

eq_tup3 : Tuple.Tup3(a, b, c), Tuple.Tup3(a, b, c) -> Bool
eq_tup3 = |ex, ey| (match ex {
	MkTup3(exf0, exf1, exf2) => (match ey {
		MkTup3(eyf0, eyf1, eyf2) => (((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2))
		_ => False
	})
})

eq_tup4 : Tuple.Tup4(a, b, c, d), Tuple.Tup4(a, b, c, d) -> Bool
eq_tup4 = |ex, ey| (match ex {
	MkTup4(exf0, exf1, exf2, exf3) => (match ey {
		MkTup4(eyf0, eyf1, eyf2, eyf3) => ((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3))
		_ => False
	})
})

eq_tup5 : Tuple.Tup5(a, b, c, d, e), Tuple.Tup5(a, b, c, d, e) -> Bool
eq_tup5 = |ex, ey| (match ex {
	MkTup5(exf0, exf1, exf2, exf3, exf4) => (match ey {
		MkTup5(eyf0, eyf1, eyf2, eyf3, eyf4) => (((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3)) and (exf4 == eyf4))
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("cm-x    ", x_got, x_want, 0.0))
	line!(Grade.grade_reals("cm-y    ", y_got, y_want, 0.0))
	line!(Grade.grade_reals("cm-depth", depth_got, depth_want, 0.0))
	line!(Grade.grade_reals("cm-fixed", fixed_got, fixed_want, 0.0))
	line!(Grade.grade_reals("cm-all  ", all_got, all_want, 0.0))
	Ok({})
}
