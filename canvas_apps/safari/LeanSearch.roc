## How far the rider leans. A bisection over leans near the current one
## finds the lean whose coasting arc ends nearest the line the rider wants.
import Across
import Angle
import Arc
import Bike
import Distance
import Steps

LeanSearch :: [].{

	want_more_right : Arc.ArcOutcome, Across -> Bool
	want_more_right = |sim, target| (
		match sim.shoulder {
			ShoulderLeft(_) => True
			ShoulderRight(_) => False
			ShoulderNone => (sim.end_across < target)
		}
	)

	asymptote_tuning : F64
	asymptote_tuning = 0.3

	center_lane_epsilon : Distance
	center_lane_epsilon = Distance.metres(0.04)

	lean_target : Across -> Across
	lean_target = |across| (
		if across.distance_from_middle() < center_lane_epsilon {
			(
				if across >= Across.middle {
					Across.right_of_middle(center_lane_epsilon)
				} else {
					Across.left_of_middle(center_lane_epsilon)
				}
			)
		} else {
			across.times(asymptote_tuning)
		}
	)

	## The most the lean changes in one step.
	max_tilt_correction : Angle.Lean
	max_tilt_correction = Angle.Lean.degrees(1.0)

	lean_search_iters : I64
	lean_search_iters = 12

	## The lean between `low` and `high` whose arc ends nearest `target`
	## across the road, after the bisection's remaining steps from `at`.
	search_lean_from : Bike.Motion(others),
	{
		target : Across,
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
		} else if want_more_right(Arc.project_arc(Bike.with_tilt(state, mid)), target) {
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
	best_tilt_correction : Bike.Motion(others) -> Angle.Lean
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

## Where the rider aims from `across` metres.
target_of : F64 -> F64
target_of = |across| LeanSearch.lean_target(Across.metres(across)).to_metres()

expect target_of(0.5) == 0.15
expect target_of((0.0 - 0.5)) == -0.15
expect target_of(2.0) == 0.6
expect target_of((0.0 - 2.0)) == -0.6
expect target_of(0.04) == 0.012
expect target_of((0.0 - 0.04)) == -0.012
expect target_of(0.0) == 0.04
expect target_of(0.039) == 0.04
expect target_of((0.0 - 0.039)) == -0.04
expect target_of(2.0) > 0.0
expect target_of(2.0) < 2.0
expect target_of((0.0 - 2.0)) < 0.0
expect target_of((0.0 - 2.0)) > (0.0 - 2.0)
expect target_of(0.0) > 0.0

expect LeanSearch.asymptote_tuning == 0.3
expect LeanSearch.center_lane_epsilon.to_metres() == 0.04
expect LeanSearch.max_tilt_correction.to_radians() == 0.017453292519943295
expect LeanSearch.lean_search_iters == 12

## An arc ending at `end_across`, on `shoulder` or not.
outcome : Arc.Shoulder, F64 -> Arc.ArcOutcome
outcome = |shoulder, end_across| {
	shoulder,
	forward: Distance.metres(10.0),
	crossed: False,
	end_across: Across.metres(end_across),
}

off_left : Arc.Shoulder
off_left = ShoulderLeft(Steps.one_step)

off_right : Arc.Shoulder
off_right = ShoulderRight(Steps.one_step)

expect LeanSearch.want_more_right(outcome(off_left, 99.0), Across.metres(0.5))
expect LeanSearch.want_more_right(outcome(off_left, (0.0 - 99.0)), Across.metres(0.5))
expect !(LeanSearch.want_more_right(outcome(off_right, 99.0), Across.metres(0.5)))
expect !(LeanSearch.want_more_right(outcome(off_right, (0.0 - 99.0)), Across.metres(0.5)))
expect LeanSearch.want_more_right(outcome(ShoulderNone, 0.4), Across.metres(0.5))
expect !(LeanSearch.want_more_right(outcome(ShoulderNone, 0.6), Across.metres(0.5)))
expect !(LeanSearch.want_more_right(outcome(ShoulderNone, 0.5), Across.metres(0.5)))
