# LeanSearch -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Arc
import lib.DeviceMath
import Pose
import lib.Trig
import World

LeanSearch :: [].{

	want_more_right : Arc.ArcOutcome, F64 -> Bool
	want_more_right = |sim, target| (match sim.shoulder {
		ShoulderLeft => True
		ShoulderRight => False
		ShoulderNone => (sim.end_across < target)
	})

	asymptote_tuning : F64
	asymptote_tuning = 0.3

	center_lane_epsilon : F64
	center_lane_epsilon = 0.04

	lean_target : F64 -> F64
	lean_target = |across| (if (DeviceMath.real_abs(across) < center_lane_epsilon) { (if (across >= 0.0) { center_lane_epsilon } else { (0.0 - center_lane_epsilon) }) } else { (across * asymptote_tuning) })

	max_tilt_correction : F64
	max_tilt_correction = (1.0 * Trig.deg)

	lean_search_iters : I64
	lean_search_iters = 12

	search_lean : Pose.RiderState, World.Segment, F64, F64, F64, I64 -> F64
	search_lean = |state, seg, target, lo, hi, i| (if (i >= lean_search_iters) { ((lo + hi) / 2.0) } else { search_step(state, seg, target, lo, hi, i, ((lo + hi) / 2.0)) })

	search_step : Pose.RiderState, World.Segment, F64, F64, F64, I64, F64 -> F64
	search_step = |state, seg, target, lo, hi, i, mid| (if want_more_right(Arc.project_arc(Pose.with_tilt(state, mid), seg), target) { search_lean(state, seg, target, mid, hi, (i + 1)) } else { search_lean(state, seg, target, lo, mid, (i + 1)) })

	best_tilt_correction : Pose.RiderState, World.Segment -> F64
	best_tilt_correction = |state, seg| search_lean(state, seg, lean_target(state.across), (state.tilt - max_tilt_correction), (state.tilt + max_tilt_correction), 0)
}
