## How far the rider leans. A bisection over leans near the current one
## finds the lean whose coast ends nearest the road's middle.
import Across
import Angle
import Coast
import Motorcycle
import Steps

LeanSearch :: [].{

	## Which way the next try should lean, from where this try's coast went:
	## off the left shoulder means more right, off the right means more left,
	## and a coast that stays on the road compares its end with `target`. A
	## coast that ends exactly on the target means lean left.
	lean_correction : Coast.Outcome, Across -> [MoreRight, MoreLeft]
	lean_correction = |coast, target|
		match coast {
			Leaves({ side: Left, .. }) => MoreRight
			Leaves({ side: Right, .. }) => MoreLeft
			EndsAt(end_across) =>
				if end_across < target {
					MoreRight
				} else {
					MoreLeft
				}
		}

	## The most the lean changes in one step.
	max_lean_change : Angle.LeanChange
	max_lean_change = Angle.LeanChange.degrees(1.0)

	## How many times the search halves its bounds. They start 2° wide, a
	## degree either side of the lean, so 12 halvings narrow them to about
	## 0.0005°.
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
			match lean_correction(Coast.project(state.with_lean(mid)), target) {
				MoreRight => {
					$low = mid
				}
				MoreLeft => {
					$high = mid
				}
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

expect LeanSearch.lean_correction(off_left, Across.metres(0.5)) == MoreRight
expect LeanSearch.lean_correction(off_right, Across.metres(0.5)) == MoreLeft
expect LeanSearch.lean_correction(ending_at(0.4), Across.metres(0.5)) == MoreRight
expect LeanSearch.lean_correction(ending_at(0.6), Across.metres(0.5)) == MoreLeft
expect LeanSearch.lean_correction(ending_at(0.5), Across.metres(0.5)) == MoreLeft

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
