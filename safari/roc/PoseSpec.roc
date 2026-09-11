# PoseSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import Pose
import Tuple

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

probe : Pose.RiderState
probe = { segment: 7, along: 11.0, across: 2.5, yaw: 0.75, v: 3.25, tilt: 0.125, heading: 4.5, gaze_yaw: 0.375, focus: 6.75 }

new_tilt : F64
new_tilt = 9.5

reals : Pose.RiderState -> List(F64)
reals = |s| [s.along, s.across, s.yaw, s.v, s.tilt, s.heading, s.gaze_yaw, s.focus]

seg : Pose.RiderState -> List(I64)
seg = |s| [s.segment]

init_want : List(F64)
init_want = [0.0, 0.0, 0.0, 0.3, 0.0, 0.0, 0.0, 0.0]

init_seg_want : List(I64)
init_seg_want = [0]

tilt_want : List(F64)
tilt_want = [11.0, 2.5, 0.75, 3.25, 9.5, 4.5, 0.375, 6.75]

tilt_seg_want : List(I64)
tilt_seg_want = [7]

twice_want : List(F64)
twice_want = [11.0, 2.5, 0.75, 3.25, 9.5, 4.5, 0.375, 6.75]

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
	line!(Grade.grade_reals("p-init  ", reals(Pose.initial_rider_state), init_want, 0.0))
	line!(Grade.grade_ints("p-initsg", seg(Pose.initial_rider_state), init_seg_want))
	line!(Grade.grade_reals("p-tilt  ", reals(Pose.with_tilt(probe, new_tilt)), tilt_want, 0.0))
	line!(Grade.grade_ints("p-tiltsg", seg(Pose.with_tilt(probe, new_tilt)), tilt_seg_want))
	line!(Grade.grade_reals("p-twice ", reals(Pose.with_tilt(Pose.with_tilt(probe, 1.5), new_tilt)), twice_want, 0.0))
	Ok({})
}
