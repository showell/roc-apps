# PoseSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import Pose

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

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("p-init  ", reals(Pose.initial_rider_state), init_want, 0.0))
	line!(Grade.grade_ints("p-initsg", seg(Pose.initial_rider_state), init_seg_want))
	line!(Grade.grade_reals("p-tilt  ", reals(Pose.with_tilt(probe, new_tilt)), tilt_want, 0.0))
	line!(Grade.grade_ints("p-tiltsg", seg(Pose.with_tilt(probe, new_tilt)), tilt_seg_want))
	line!(Grade.grade_reals("p-twice ", reals(Pose.with_tilt(Pose.with_tilt(probe, 1.5), new_tilt)), twice_want, 0.0))
	Ok({})
}
