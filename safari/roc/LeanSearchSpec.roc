# LeanSearchSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Arc
import DeviceMath
import Grade
import LeanSearch
import Pose
import Text
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
	line!(Text.printed(Grade.grade_reals([23, 19, 73, 14, 15, 21, 29, 13, 14], target_got, target_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([23, 19, 73, 19, 17, 22, 13, 2, 2], side_got, side_want)))
	line!(Text.printed(Grade.grade_reals([23, 19, 73, 14, 25, 18, 17, 18, 29], tuning_got, tuning_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([23, 19, 73, 17, 14, 13, 21, 19, 2], iters_got, iters_want)))
	line!(Text.printed(Grade.grade_bools([23, 19, 73, 21, 13, 15, 22, 2, 2], read_got, read_want)))
	line!(Text.printed(Grade.grade_bools([23, 19, 73, 32, 21, 15, 24, 34, 14], bracket_got, bracket_want)))
	line!(Text.printed(Grade.grade_bools([23, 19, 73, 24, 13, 18, 14, 21, 13], centred_on_got, centred_on_want)))
	line!(Text.printed(Grade.grade_reals([23, 19, 73, 19, 14, 15, 32, 23, 13], stable_got, stable_want, 0.0)))
	Ok({})
}
