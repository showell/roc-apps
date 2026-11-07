## How far the rider leans. A bisection over leans near the current one
## finds the lean whose coast ends nearest the road's middle.
import Across
import Angle
import Coast
import Motorcycle
import Steps

LeanSearch :: [].{

	want_more_right : Coast.Outcome, Across -> Bool
	want_more_right = |coast, target|
		match coast {
			Leaves({ side: Left, .. }) => True
			Leaves({ side: Right, .. }) => False
			EndsAt(end_across) => end_across < target
		}

	## The most the lean changes in one step.
	max_lean_change : Angle.LeanChange
	max_lean_change = Angle.LeanChange.degrees(1.0)

	lean_search_round_count : U8
	lean_search_round_count = 12

	## The lean between `low` and `high` whose coast ends nearest `target`
	## across the road, by bisection.
	search_lean : Motorcycle,
	{
		target : Across,
		low : Angle.Lean,
		high : Angle.Lean,
	} -> Angle.Lean
	search_lean = |state, { target, low, high }| {
		var $low = low
		var $high = high
		for _ in 0..<lean_search_round_count {
			mid = $low.halfway_to($high)
			if want_more_right(Coast.project(state.with_lean(mid)), target) {
				$low = mid
			} else {
				$high = mid
			}
		}
		$low.halfway_to($high)
	}

	## The lean for the next step, aimed at the road's middle: within the most
	## one step can change it.
	best_lean : Motorcycle -> Angle.Lean
	best_lean = |state|
		search_lean(
			state,
			{
				target: Across.middle,
				low: state.lean.minus(max_lean_change),
				high: state.lean.plus(max_lean_change),
			},
		)
}

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

## The lean the search picks for a motorcycle at the start of the segment, in
## radians.
searched_lean : F64, F64 -> F64
searched_lean = |across, lean_radians|
	LeanSearch.best_lean({
		..Motorcycle.initial,
		across: Across.metres(across),
		lean: Angle.Lean.radians(lean_radians),
	}).to_radians()

centred : F64
centred = searched_lean(0.0, 0.0)

held : F64
held = searched_lean(0.0, 0.5)

# An upright rider right of the middle leans left, and one left of it leans
# right.
expect searched_lean(1.0, 0.0) < 0.0
expect searched_lean(-1.0, 0.0) > 0.0
expect held > centred
