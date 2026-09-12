# ViewYawSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import Pose
import ViewYaw

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

s0 : Pose.RiderState
s0 = { segment: 0, along: 0.0, across: 0.0, yaw: 0.0, v: 0.3, tilt: 0.0, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }

s1 : Pose.RiderState
s1 = { segment: 0, along: 0.0, across: 0.0, yaw: 0.0, v: 0.3, tilt: 0.125, heading: 4.5, gaze_yaw: 0.375, focus: 0.0 }

s2 : Pose.RiderState
s2 = { segment: 0, along: 0.0, across: 0.0, yaw: 0.0, v: 0.3, tilt: 0.5, heading: 1.0, gaze_yaw: (-0.25), focus: 0.0 }

s3 : Pose.RiderState
s3 = { segment: 0, along: 0.0, across: 0.0, yaw: 0.0, v: 0.3, tilt: (-0.75), heading: (-2.0), gaze_yaw: 0.125, focus: 0.0 }

s4 : Pose.RiderState
s4 = { segment: 0, along: 0.0, across: 0.0, yaw: 0.0, v: 0.3, tilt: 1.25, heading: 0.5, gaze_yaw: 0.0, focus: 0.0 }

frac_got : List(F64)
frac_got = [ViewYaw.head_yaw_frac]

frac_want : List(F64)
frac_want = [0.15]

yaw_got : List(F64)
yaw_got = [ViewYaw.view_yaw_for(s0), ViewYaw.view_yaw_for(s1), ViewYaw.view_yaw_for(s2), ViewYaw.view_yaw_for(s3), ViewYaw.view_yaw_for(s4)]

yaw_want : List(F64)
yaw_want = [0.0, 0.39375, (-0.175), 0.012500000000000011, 0.1875]

head_got : List(F64)
head_got = [ViewYaw.heading_for(s0), ViewYaw.heading_for(s1), ViewYaw.heading_for(s2), ViewYaw.heading_for(s3), ViewYaw.heading_for(s4)]

head_want : List(F64)
head_want = [0.0, 4.89375, 0.825, (-1.9875), 0.6875]

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("vy-frac", frac_got, frac_want, 0.0))
	line!(Grade.grade_reals("vy-yaw ", yaw_got, yaw_want, 0.0))
	line!(Grade.grade_reals("vy-head", head_got, head_want, 0.0))
	Ok({})
}
