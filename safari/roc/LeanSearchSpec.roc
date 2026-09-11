# LeanSearchSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Arc
import DeviceMath
import Grade
import LeanSearch
import Pose
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

target_got : List(F64)
target_got = [LeanSearch.lean_target(0.5), LeanSearch.lean_target((0.0 - 0.5)), LeanSearch.lean_target(2.0), LeanSearch.lean_target((0.0 - 2.0)), LeanSearch.lean_target(0.04), LeanSearch.lean_target((0.0 - 0.04)), LeanSearch.lean_target(0.0), LeanSearch.lean_target(0.039), LeanSearch.lean_target((0.0 - 0.039))]

target_want : List(F64)
target_want = [0.15, (-0.15), 0.6, (-0.6), 0.012, (-0.012), 0.04, 0.04, (-0.04)]

side_got : List(Bool)
side_got = [(LeanSearch.lean_target(2.0) > 0.0), (LeanSearch.lean_target(2.0) < 2.0), (LeanSearch.lean_target((0.0 - 2.0)) < 0.0), (LeanSearch.lean_target((0.0 - 2.0)) > (0.0 - 2.0)), (LeanSearch.lean_target(0.0) > 0.0)]

side_want : List(Bool)
side_want = [True, True, True, True, True]

tuning_got : List(F64)
tuning_got = [LeanSearch.asymptote_tuning, LeanSearch.center_lane_epsilon, LeanSearch.max_tilt_correction]

tuning_want : List(F64)
tuning_want = [0.3, 0.04, 0.017453292519943295]

iters_got : List(I64)
iters_got = [LeanSearch.lean_search_iters]

iters_want : List(I64)
iters_want = [12]

outcome : Arc.Shoulder, F64 -> Arc.ArcOutcome
outcome = |sh, end_across| { shoulder: sh, forward: 10.0, crossed: False, end_across: end_across, frames: 100.0 }

read_got : List(Bool)
read_got = [LeanSearch.want_more_right(outcome(ShoulderLeft, 99.0), 0.5), LeanSearch.want_more_right(outcome(ShoulderLeft, (0.0 - 99.0)), 0.5), LeanSearch.want_more_right(outcome(ShoulderRight, 99.0), 0.5), LeanSearch.want_more_right(outcome(ShoulderRight, (0.0 - 99.0)), 0.5), LeanSearch.want_more_right(outcome(ShoulderNone, 0.4), 0.5), LeanSearch.want_more_right(outcome(ShoulderNone, 0.6), 0.5), LeanSearch.want_more_right(outcome(ShoulderNone, 0.5), 0.5)]

read_want : List(Bool)
read_want = [True, True, False, False, True, False, False]

seg : World.Segment
seg = World.segment_at(0)

rider : F64, F64 -> Pose.RiderState
rider = |across, tilt| { segment: 0, along: 0.0, across: across, yaw: 0.0, v: Pose.v_base, tilt: tilt, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }

centred : F64
centred = LeanSearch.best_tilt_correction(rider(0.0, 0.0), seg)

offset : F64
offset = LeanSearch.best_tilt_correction(rider(1.0, 0.0), seg)

held : F64
held = LeanSearch.best_tilt_correction(rider(0.0, 0.5), seg)

bracket_got : List(Bool)
bracket_got = [(centred >= (0.0 - LeanSearch.max_tilt_correction)), (centred <= LeanSearch.max_tilt_correction), (offset >= (0.0 - LeanSearch.max_tilt_correction)), (offset <= LeanSearch.max_tilt_correction), (held >= (0.5 - LeanSearch.max_tilt_correction)), (held <= (0.5 + LeanSearch.max_tilt_correction))]

bracket_want : List(Bool)
bracket_want = [True, True, True, True, True, True]

centred_on_got : List(Bool)
centred_on_got = [(DeviceMath.real_abs((held - 0.5)) <= LeanSearch.max_tilt_correction), (DeviceMath.real_abs(centred) <= LeanSearch.max_tilt_correction), (held > centred)]

centred_on_want : List(Bool)
centred_on_want = [True, True, True]

stable_got : List(F64)
stable_got = [(LeanSearch.best_tilt_correction(rider(1.0, 0.0), seg) - offset), (LeanSearch.best_tilt_correction(rider(0.0, 0.5), seg) - held)]

stable_want : List(F64)
stable_want = [0.0, 0.0]

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("ls-target", target_got, target_want, 0.0))
	line!(Grade.grade_bools("ls-side  ", side_got, side_want))
	line!(Grade.grade_reals("ls-tuning", tuning_got, tuning_want, 0.0))
	line!(Grade.grade_ints("ls-iters ", iters_got, iters_want))
	line!(Grade.grade_bools("ls-read  ", read_got, read_want))
	line!(Grade.grade_bools("ls-brackt", bracket_got, bracket_want))
	line!(Grade.grade_bools("ls-centre", centred_on_got, centred_on_want))
	line!(Grade.grade_reals("ls-stable", stable_got, stable_want, 0.0))
	Ok({})
}
