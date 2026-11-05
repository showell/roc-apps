# LeanSearchSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Fraction
import Arc
import lib.DeviceMath
import Along
import Across
import Distance
import Grade
import LeanSearch
import World
import Pose
import Steps
import VehicleLimits

## Where the rider aims from `across` metres.
target_of : F64 -> F64
target_of = |across| LeanSearch.lean_target(Across.metres(across)).to_metres()

target_got : List(F64)
target_got = [
	target_of(0.5),
	target_of((0.0 - 0.5)),
	target_of(2.0),
	target_of((0.0 - 2.0)),
	target_of(0.04),
	target_of((0.0 - 0.04)),
	target_of(0.0),
	target_of(0.039),
	target_of((0.0 - 0.039)),
]

target_want : List(F64)
target_want = [
	0.15,
	(-0.15),
	0.6,
	(-0.6),
	0.012,
	(-0.012),
	0.04,
	0.04,
	(-0.04),
]

side_got : List(Bool)
side_got = [
	(target_of(2.0) > 0.0),
	(target_of(2.0) < 2.0),
	(target_of((0.0 - 2.0)) < 0.0),
	(target_of((0.0 - 2.0)) > (0.0 - 2.0)),
	(target_of(0.0) > 0.0),
]

side_want : List(Bool)
side_want = [True, True, True, True, True]

tuning_got : List(F64)
tuning_got = [
	LeanSearch.asymptote_tuning,
	LeanSearch.center_lane_epsilon.to_metres(),
	max_correction,
]

tuning_want : List(F64)
tuning_want = [0.3, 0.04, 0.017453292519943295]

iters_got : List(I64)
iters_got = [LeanSearch.lean_search_iters]

iters_want : List(I64)
iters_want = [12]

outcome : Arc.Shoulder, F64 -> Arc.ArcOutcome
outcome = |sh, end_across| {
	shoulder: sh,
	forward: Distance.metres(10.0),
	crossed: False,
	end_across: Across.metres(end_across),
	frames: Steps.of(100),
}

read_got : List(Bool)
read_got = [
	LeanSearch.want_more_right(outcome(ShoulderLeft, 99.0), Across.metres(0.5)),
	LeanSearch.want_more_right(outcome(ShoulderLeft, (0.0 - 99.0)), Across.metres(0.5)),
	LeanSearch.want_more_right(outcome(ShoulderRight, 99.0), Across.metres(0.5)),
	LeanSearch.want_more_right(outcome(ShoulderRight, (0.0 - 99.0)), Across.metres(0.5)),
	LeanSearch.want_more_right(outcome(ShoulderNone, 0.4), Across.metres(0.5)),
	LeanSearch.want_more_right(outcome(ShoulderNone, 0.6), Across.metres(0.5)),
	LeanSearch.want_more_right(outcome(ShoulderNone, 0.5), Across.metres(0.5)),
]

read_want : List(Bool)
read_want = [True, True, False, False, True, False, False]

rider : F64, F64 -> Pose.RiderState
rider = |across, tilt| {
	segment: World.SegmentIndex.number(0),
	along: Along.metres(0.0),
	across: Across.metres(across),
	yaw: Angle.Turn.radians(0.0),
	speed: VehicleLimits.v_base,
	tilt: Angle.Lean.radians(tilt),
	heading: Angle.Bearing.radians(0.0),
	gaze_yaw: Angle.Turn.radians(0.0),
	focus: Fraction.zero,
}

## The most the lean changes in a step, in radians.
max_correction : F64
max_correction = LeanSearch.max_tilt_correction.to_radians()

## The lean the search picks for `state`, in radians.
best_lean : Pose.RiderState -> F64
best_lean = |state| LeanSearch.best_tilt_correction(state).to_radians()

centred : F64
centred = best_lean(rider(0.0, 0.0))

offset : F64
offset = best_lean(rider(1.0, 0.0))

held : F64
held = best_lean(rider(0.0, 0.5))

bracket_got : List(Bool)
bracket_got = [
	(centred >= (0.0 - max_correction)),
	(centred <= max_correction),
	(offset >= (0.0 - max_correction)),
	(offset <= max_correction),
	(held >= (0.5 - max_correction)),
	(held <= (0.5 + max_correction)),
]

bracket_want : List(Bool)
bracket_want = [True, True, True, True, True, True]

centred_on_got : List(Bool)
centred_on_got = [
	(DeviceMath.real_abs((held - 0.5)) <= max_correction),
	(DeviceMath.real_abs(centred) <= max_correction),
	(held > centred),
]

centred_on_want : List(Bool)
centred_on_want = [True, True, True]

stable_got : List(F64)
stable_got = [(best_lean(rider(1.0, 0.0)) - offset), (best_lean(rider(0.0, 0.5)) - held)]

stable_want : List(F64)
stable_want = [0.0, 0.0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "ls-target",
			got: target_got,
			want: target_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "ls-side  ",
			got: side_got,
			want: side_want,
		}),
		Grade.reals({
			name: "ls-tuning",
			got: tuning_got,
			want: tuning_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "ls-iters ",
			got: iters_got,
			want: iters_want,
		}),
		Grade.bools({
			name: "ls-read  ",
			got: read_got,
			want: read_want,
		}),
		Grade.bools({
			name: "ls-brackt",
			got: bracket_got,
			want: bracket_want,
		}),
		Grade.bools({
			name: "ls-centre",
			got: centred_on_got,
			want: centred_on_want,
		}),
		Grade.reals({
			name: "ls-stable",
			got: stable_got,
			want: stable_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
