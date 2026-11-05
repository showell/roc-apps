## These are CanvasRoll's checks: leans inside the deadband, at its edge,
## and well past it, each way.
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import CanvasRoll
import Grade
import World
import Pose

band_got : List(F64)
band_got = [CanvasRoll.roll_deadband]

band_want : List(F64)
band_want = [0.001]

tilt_in : List(F64)
tilt_in = [
	0.0,
	F64.from_bits(4532020583610935537),
	0.0005,
	(-0.0005),
	0.0009999,
	0.001,
	(-0.001),
	0.002,
	(-0.002),
	0.35,
	(-0.42),
]

roll_want : List(F64)
roll_want = [
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	0.001,
	(-0.001),
	0.002,
	(-0.002),
	0.35,
	(-0.42),
]

as_rider : F64 -> Pose.RiderState
as_rider = |tilt| {
	segment: World.SegmentIndex.number(0),
	along: 0.0,
	across: 0.0,
	yaw: Angle.Turn.radians(0.0),
	v: 0.3,
	tilt: Angle.Lean.radians(tilt),
	heading: Angle.Bearing.radians(0.0),
	gaze_yaw: Angle.Turn.radians(0.0),
	focus: 0.0,
}

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "cr-band",
			got: band_got,
			want: band_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "cr-roll",
			got: tilt_in.map(|tilt| CanvasRoll.rider_roll(as_rider(tilt))),
			want: roll_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
