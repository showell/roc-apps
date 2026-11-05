## How far the rider leans. A bisection over leans near the current one
## finds the lean whose coasting arc ends nearest the line the rider wants.
import Angle
import Arc
import lib.DeviceMath
import Pose
import lib.Trig

LeanSearch :: [].{

	want_more_right : Arc.ArcOutcome, F64 -> Bool
	want_more_right = |sim, target| (
		match sim.shoulder {
			ShoulderLeft => True
			ShoulderRight => False
			ShoulderNone => (sim.end_across < target)
		}
	)

	asymptote_tuning : F64
	asymptote_tuning = 0.3

	center_lane_epsilon : F64
	center_lane_epsilon = 0.04

	lean_target : F64 -> F64
	lean_target = |across| (
		if DeviceMath.real_abs(across) < center_lane_epsilon {
			(
				if across >= 0.0 {
					center_lane_epsilon
				} else {
					(0.0 - center_lane_epsilon)
				}
			)
		} else {
			(across * asymptote_tuning)
		}
	)

	## The most the lean changes in one step.
	max_tilt_correction : Angle.Lean
	max_tilt_correction = Angle.Lean.degrees(1.0)

	lean_search_iters : I64
	lean_search_iters = 12

	## The lean between `low` and `high` whose arc ends nearest `target`
	## across the road, after the bisection's remaining steps from `at`.
	search_lean_from : Pose.RiderState,
	{
		target : F64,
		low : Angle.Lean,
		high : Angle.Lean,
		at : I64,
	} -> Angle.Lean
	search_lean_from = |
		state,
		{
			target,
			low,
			high,
			at,
		},
	| {
		mid = low.halfway_to(high)
		if at >= lean_search_iters {
			mid
		} else if want_more_right(Arc.project_arc(Pose.with_tilt(state, mid)), target) {
			search_lean_from(
				state,
				{
					target,
					low: mid,
					high,
					at: at + 1,
				},
			)
		} else {
			search_lean_from(
				state,
				{
					target,
					low,
					high: mid,
					at: at + 1,
				},
			)
		}
	}

	## The lean for the next step: within the most one step can change it.
	best_tilt_correction : Pose.RiderState -> Angle.Lean
	best_tilt_correction = |state|
		search_lean_from(
			state,
			{
				target: lean_target(state.across),
				low: state.tilt.minus(max_tilt_correction),
				high: state.tilt.plus(max_tilt_correction),
				at: 0,
			},
		)
}
