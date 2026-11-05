# PoseSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Bike
import Fraction
import Across
import Along
import Grade
import Pose
import Speed
import World

probe : Pose.RiderState
probe = {
	segment: World.SegmentIndex.number(7),
	along: Along.metres(11.0),
	across: Across.metres(2.5),
	yaw: Angle.Turn.radians(0.75),
	speed: Speed.metres_a_step(3.25),
	tilt: Angle.Lean.radians(0.125),
	heading: Angle.Bearing.radians(4.5),
	gaze_yaw: Angle.Turn.radians(0.375),
	focus: Fraction.of(0.75),
}

new_tilt : Angle.Lean
new_tilt = Angle.Lean.radians(9.5)

leaned_once : Pose.RiderState
leaned_once = Bike.with_tilt(probe, Angle.Lean.radians(1.5))

reals : Pose.RiderState -> List(F64)
reals = |s| [
	s.along.to_metres(),
	s.across.to_metres(),
	s.yaw.to_radians(),
	s.speed.to_metres_a_step(),
	s.tilt.to_radians(),
	s.heading.to_radians(),
	s.gaze_yaw.to_radians(),
	s.focus.to_f64(),
]

seg : Pose.RiderState -> List(I64)
seg = |s| [s.segment.to_i64()]

init_want : List(F64)
init_want = [0.0, 0.0, 0.0, 0.3, 0.0, 0.0, 0.0, 0.0]

init_seg_want : List(I64)
init_seg_want = [0]

tilt_want : List(F64)
tilt_want = [11.0, 2.5, 0.75, 3.25, 9.5, 4.5, 0.375, 0.75]

tilt_seg_want : List(I64)
tilt_seg_want = [7]

twice_want : List(F64)
twice_want = [11.0, 2.5, 0.75, 3.25, 9.5, 4.5, 0.375, 0.75]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "p-init  ",
			got: reals(Pose.initial_rider_state),
			want: init_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "p-initsg",
			got: seg(Pose.initial_rider_state),
			want: init_seg_want,
		}),
		Grade.reals({
			name: "p-tilt  ",
			got: reals(Bike.with_tilt(probe, new_tilt)),
			want: tilt_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "p-tiltsg",
			got: seg(Bike.with_tilt(probe, new_tilt)),
			want: tilt_seg_want,
		}),
		Grade.reals({
			name: "p-twice ",
			got: reals(Bike.with_tilt(leaned_once, new_tilt)),
			want: twice_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
