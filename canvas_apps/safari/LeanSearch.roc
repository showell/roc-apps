## How far the rider leans. A bisection over leans near the current one
## finds the lean whose coast ends nearest the road's middle.
import Across
import Angle
import Coast
import Motorcycle

LeanSearch :: [].{

	## Where the search aims a coast to end: the road's middle.
	aimed_across : Across
	aimed_across = Across.middle

	## Which way the next try should lean, from where this try's coast went:
	## off the left shoulder means more right, off the right means more left,
	## and a coast that stays on the road compares its end with
	## `aimed_across`. A coast that ends exactly there means lean left.
	lean_correction : Coast.Outcome -> [MoreRight, MoreLeft]
	lean_correction = |coast|
		match coast {
			Leaves({ side: Left, .. }) => MoreRight
			Leaves({ side: Right, .. }) => MoreLeft
			EndsAt(end_across) =>
				if end_across < LeanSearch.aimed_across {
					MoreRight
				} else {
					MoreLeft
				}
		}

	## How many times the search halves its bounds. They start 2° wide, a
	## degree either side of the lean, so 12 halvings narrow them to about
	## 0.0005°.
	lean_search_round_count : U8
	lean_search_round_count = 12

	## One try of the search: the bounds it tried between, and where the coast
	## with the lean halfway between them went.
	LeanTry : {
		low : Angle.Lean,
		high : Angle.Lean,
		outcome : Coast.Outcome,
	}

	## The lean a try tried, halfway between its bounds.
	tried_lean : LeanTry -> Angle.Lean
	tried_lean = |{ low, high, .. }| middle_lean({ low, high })

	## The motorcycle a try coasts: `motorcycle`, the one the search started
	## from, with the lean halfway between the try's bounds. It takes the bounds
	## alone, so the search can ask for it before the try has an outcome.
	tried_motorcycle : Motorcycle, { low : Angle.Lean, high : Angle.Lean, .. } -> Motorcycle
	tried_motorcycle = |motorcycle, { low, high, .. }|
		motorcycle.with_lean(middle_lean({ low, high }))

	## The tries of the bisection over the leans one step can reach from the
	## motorcycle's own, in the order tried. Each try's bounds are the half of the one
	## before it that its coast pointed to.
	search_tries : Motorcycle -> List(LeanSearch.LeanTry)
	search_tries = |motorcycle| {
		var $bounds = {
			low: motorcycle.lean.minus(max_lean_change),
			high: motorcycle.lean.plus(max_lean_change),
		}
		var $tries = []
		for _ in 0..<lean_search_round_count {
			lean_try = {
				low: $bounds.low,
				high: $bounds.high,
				outcome: Coast.coast_outcome(LeanSearch.tried_motorcycle(motorcycle, $bounds)),
			}
			$tries = $tries.append(lean_try)
			$bounds = bounds_after(lean_try)
		}
		$tries
	}

	## The lean for the next step, whose coast ends nearest the road's middle:
	## halfway between the bounds the last try narrowed to.
	best_lean : Motorcycle -> Angle.Lean
	best_lean = |motorcycle| {
		last_try = LeanSearch.search_tries(motorcycle).last() ?? crash "LeanSearch.best_lean: the search makes at least one try"
		middle_lean(bounds_after(last_try))
	}
}

## The leans a try searches between.
LeanBounds : { low : Angle.Lean, high : Angle.Lean }

## The lean halfway between `bounds`, which a try tries.
middle_lean : LeanBounds -> Angle.Lean
middle_lean = |{ low, high }| low.halfway_to(high)

## The most the lean changes in one step.
max_lean_change : Angle.LeanChange
max_lean_change = Angle.LeanChange.degrees(1.0)

## The half of a try's bounds its coast points to.
bounds_after : LeanSearch.LeanTry -> LeanBounds
bounds_after = |lean_try| {
	mid = LeanSearch.tried_lean(lean_try)
	match LeanSearch.lean_correction(lean_try.outcome) {
		MoreRight => { low: mid, high: lean_try.high }
		MoreLeft => { low: lean_try.low, high: mid }
	}
}

## A coast that ends `metres` across the road.
ending_at : F64 -> Coast.Outcome
ending_at = |metres| EndsAt(Across.metres(metres))

expect LeanSearch.lean_correction(ending_at(-0.1)) == MoreRight
expect LeanSearch.lean_correction(ending_at(0.1)) == MoreLeft
expect LeanSearch.lean_correction(ending_at(0.0)) == MoreLeft

## The lean the search picks for a motorcycle at the start of the segment, in
## radians.
searched_lean : F64, F64 -> F64
searched_lean = |across, lean_radians|
	LeanSearch.best_lean({
		..Motorcycle.initial,
		route_place: {
			..Motorcycle.initial.route_place,
			road_point: {
				..Motorcycle.initial.route_place.road_point,
				across: Across.metres(across),
			},
		},
		lean: Angle.Lean.radians(lean_radians),
	}).to_radians()

# An upright rider right of the middle leans left, and one left of it leans
# right.
expect searched_lean(1.0, 0.0) < 0.0
expect searched_lean(-1.0, 0.0) > 0.0

# A lean held to the right stays further right than an upright rider's.
expect {
	held = searched_lean(0.0, 0.5)
	centred = searched_lean(0.0, 0.0)
	held > centred
}
