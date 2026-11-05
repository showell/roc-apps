## These are CanvasRoll's checks: leans inside the deadband, at its edge,
## and well past it, each way.
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import CanvasRoll
import Grade

band_got : List(F64)
band_got = [CanvasRoll.roll_deadband.to_radians()]

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
			got: tilt_in.map(|tilt| CanvasRoll.rider_roll(Angle.Lean.radians(tilt)).to_radians()),
			want: roll_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
