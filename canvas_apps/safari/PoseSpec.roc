# PoseSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Grade
import Pose
import Text

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
	line!(Text.printed(Grade.grade_reals([31, 73, 17, 18, 17, 14, 2, 2], reals(Pose.initial_rider_state), init_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([31, 73, 17, 18, 17, 14, 19, 29], seg(Pose.initial_rider_state), init_seg_want)))
	line!(Text.printed(Grade.grade_reals([31, 73, 14, 17, 23, 14, 2, 2], reals(Pose.with_tilt(probe, new_tilt)), tilt_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([31, 73, 14, 17, 23, 14, 19, 29], seg(Pose.with_tilt(probe, new_tilt)), tilt_seg_want)))
	line!(Text.printed(Grade.grade_reals([31, 73, 14, 27, 17, 24, 13, 2], reals(Pose.with_tilt(Pose.with_tilt(probe, 1.5), new_tilt)), twice_want, 0.0)))
	Ok({})
}
