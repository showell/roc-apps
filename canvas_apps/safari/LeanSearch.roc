## How far the rider leans. A bisection over leans near the current one
## finds the lean whose coast ends nearest the line the rider wants.
import Across
import Angle
import Coast
import Bike
import Distance
import Steps

LeanSearch :: [].{

	want_more_right : Coast.Outcome, Across -> Bool
	want_more_right = |coast, target|
		match coast {
			Leaves({ side: Left, .. }) => True
			Leaves({ side: Right, .. }) => False
			EndsAt(end_across) => end_across < target
		}

	asymptote_tuning : F64
	asymptote_tuning = 0.3

	center_road_epsilon : Distance
	center_road_epsilon = Distance.metres(0.04)

	lean_target : Across -> Across
	lean_target = |across|
		if across.distance_from_middle() < center_road_epsilon {
			if across >= Across.middle {
				Across.right_of_middle(center_road_epsilon)
			} else {
				Across.left_of_middle(center_road_epsilon)
			}
		} else {
			across.times(asymptote_tuning)
		}

	## The most the lean changes in one step.
	max_lean_change : Angle.Lean
	max_lean_change = Angle.Lean.degrees(1.0)

	lean_search_rounds : I64
	lean_search_rounds = 12

	## The lean between `low` and `high` whose coast ends nearest `target`
	## across the road, by bisection.
	search_lean : Bike.Motion(others),
	{
		target : Across,
		low : Angle.Lean,
		high : Angle.Lean,
	} -> Angle.Lean
	search_lean = |state, { target, low, high }| {
		var $low = low
		var $high = high
		for _ in 0..<lean_search_rounds {
			mid = $low.halfway_to($high)
			if want_more_right(Coast.project(Bike.with_lean(state, mid)), target) {
				$low = mid
			} else {
				$high = mid
			}
		}
		$low.halfway_to($high)
	}

	## The lean for the next step: within the most one step can change it.
	best_lean : Bike.Motion(others) -> Angle.Lean
	best_lean = |state|
		search_lean(
			state,
			{
				target: lean_target(state.across),
				low: state.lean.minus(max_lean_change),
				high: state.lean.plus(max_lean_change),
			},
		)
}

## Where the rider aims from `across` metres.
target_of : F64 -> F64
target_of = |across| LeanSearch.lean_target(Across.metres(across)).to_metres()

expect target_of(0.5) == 0.15
expect target_of(-0.5) == -0.15
expect target_of(2.0) == 0.6
expect target_of(-2.0) == -0.6
expect target_of(0.04) == 0.012
expect target_of(-0.04) == -0.012
expect target_of(0.0) == 0.04
expect target_of(0.039) == 0.04
expect target_of(-0.039) == -0.04
expect target_of(2.0) > 0.0
expect target_of(2.0) < 2.0
expect target_of(-2.0) < 0.0
expect target_of(-2.0) > -2.0
expect target_of(0.0) > 0.0

expect LeanSearch.asymptote_tuning == 0.3
expect LeanSearch.center_road_epsilon.to_metres() == 0.04
expect LeanSearch.max_lean_change.to_radians() == 0.017453292519943295
expect LeanSearch.lean_search_rounds == 12

off_left : Coast.Outcome
off_left = Leaves({ side: Left, after: Steps.one_step })

off_right : Coast.Outcome
off_right = Leaves({ side: Right, after: Steps.one_step })

## A coast that ends `metres` across the road.
ending_at : F64 -> Coast.Outcome
ending_at = |metres| EndsAt(Across.metres(metres))

expect LeanSearch.want_more_right(off_left, Across.metres(0.5))
expect !LeanSearch.want_more_right(off_right, Across.metres(0.5))
expect LeanSearch.want_more_right(ending_at(0.4), Across.metres(0.5))
expect !LeanSearch.want_more_right(ending_at(0.6), Across.metres(0.5))
expect !LeanSearch.want_more_right(ending_at(0.5), Across.metres(0.5))
