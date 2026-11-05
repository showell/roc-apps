# ViewYawSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Fraction
import Grade
import Pose
import Speed
import World
import ViewYaw

s0 : Pose.RiderState
s0 = {
	segment: World.SegmentIndex.number(0),
	along: 0.0,
	across: 0.0,
	yaw: Angle.Turn.radians(0.0),
	speed: Speed.metres_a_step(0.3),
	tilt: Angle.Lean.radians(0.0),
	heading: Angle.Bearing.radians(0.0),
	gaze_yaw: Angle.Turn.radians(0.0),
	focus: Fraction.zero,
}

s1 : Pose.RiderState
s1 = {
	segment: World.SegmentIndex.number(0),
	along: 0.0,
	across: 0.0,
	yaw: Angle.Turn.radians(0.0),
	speed: Speed.metres_a_step(0.3),
	tilt: Angle.Lean.radians(0.125),
	heading: Angle.Bearing.radians(4.5),
	gaze_yaw: Angle.Turn.radians(0.375),
	focus: Fraction.zero,
}

s2 : Pose.RiderState
s2 = {
	segment: World.SegmentIndex.number(0),
	along: 0.0,
	across: 0.0,
	yaw: Angle.Turn.radians(0.0),
	speed: Speed.metres_a_step(0.3),
	tilt: Angle.Lean.radians(0.5),
	heading: Angle.Bearing.radians(1.0),
	gaze_yaw: Angle.Turn.radians((-0.25)),
	focus: Fraction.zero,
}

s3 : Pose.RiderState
s3 = {
	segment: World.SegmentIndex.number(0),
	along: 0.0,
	across: 0.0,
	yaw: Angle.Turn.radians(0.0),
	speed: Speed.metres_a_step(0.3),
	tilt: Angle.Lean.radians((-0.75)),
	heading: Angle.Bearing.radians((-2.0)),
	gaze_yaw: Angle.Turn.radians(0.125),
	focus: Fraction.zero,
}

s4 : Pose.RiderState
s4 = {
	segment: World.SegmentIndex.number(0),
	along: 0.0,
	across: 0.0,
	yaw: Angle.Turn.radians(0.0),
	speed: Speed.metres_a_step(0.3),
	tilt: Angle.Lean.radians(1.25),
	heading: Angle.Bearing.radians(0.5),
	gaze_yaw: Angle.Turn.radians(0.0),
	focus: Fraction.zero,
}

frac_got : List(F64)
frac_got = [ViewYaw.head_yaw_frac]

frac_want : List(F64)
frac_want = [0.15]

yaw_got : List(F64)
yaw_got = [
	s0,
	s1,
	s2,
	s3,
	s4,
].map(|s| ViewYaw.view_yaw_for(s).to_radians())

yaw_want : List(F64)
yaw_want = [
	0.0,
	0.39375,
	(-0.175),
	0.012500000000000011,
	0.1875,
]

head_got : List(F64)
head_got = [
	s0,
	s1,
	s2,
	s3,
	s4,
].map(|s| ViewYaw.heading_for(s).to_radians())

head_want : List(F64)
head_want = [
	0.0,
	4.89375,
	0.825,
	(-1.9875),
	0.6875,
]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "vy-frac",
			got: frac_got,
			want: frac_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "vy-yaw ",
			got: yaw_got,
			want: yaw_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "vy-head",
			got: head_got,
			want: head_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
