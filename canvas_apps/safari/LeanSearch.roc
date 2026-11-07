## How far the rider leans. A bisection over leans near the current one
## finds the lean whose coast ends nearest the line the rider wants.
import Across
import Angle
import Coast
import Motorcycle
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

	## The share of the rider's distance from the middle that the line they want
	## keeps.
	line_offset_share : F64
	line_offset_share = 0.3

	## How close to the middle the rider's line comes: a rider nearer than this
	## aims this far off it, on their own side.
	least_line_offset : Distance
	least_line_offset = Distance.metres(0.04)

	lean_target : Across -> Across
	lean_target = |across|
		if across.distance_from_middle() < least_line_offset {
			if across >= Across.middle {
				Across.right_of_middle(least_line_offset)
			} else {
				Across.left_of_middle(least_line_offset)
			}
		} else {
			across.times(line_offset_share)
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

	## The lean for the next step: within the most one step can change it.
	best_lean : Motorcycle -> Angle.Lean
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

max_correction : F64
max_correction = LeanSearch.max_lean_change.to_radians()

centred : F64
centred = searched_lean(0.0, 0.0)

offset : F64
offset = searched_lean(1.0, 0.0)

held : F64
held = searched_lean(0.0, 0.5)

expect offset.abs() <= max_correction
expect (held - 0.5).abs() <= max_correction
expect centred.abs() <= max_correction
expect held > centred
