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

	## The leans a try searches between.
	LeanBounds : { low : Angle.Lean, high : Angle.Lean }

	## The lean halfway between `bounds`, which a try tries.
	middle_lean : LeanSearch.LeanBounds -> Angle.Lean
	middle_lean = |{ low, high }| low.halfway_to(high)

	## The motorcycle a try coasts: `motorcycle`, the one the search started
	## from, with the lean halfway between `bounds`.
	tried_motorcycle : Motorcycle, LeanSearch.LeanBounds -> Motorcycle
	tried_motorcycle = |motorcycle, bounds|
		motorcycle.with_lean(LeanSearch.middle_lean(bounds))

	## One try of the search: the bounds it tried between, and where the coast
	## with the lean halfway between them went.
	LeanTry : { bounds : LeanSearch.LeanBounds, outcome : Coast.Outcome }

	## The tries of the bisection over the leans one step can reach from the
	## motorcycle's own, in the order tried. Each try's bounds are the half of the one
	## before it that its coast pointed to.
	search_tries : Motorcycle -> List(LeanSearch.LeanTry)
	search_tries = |motorcycle| {
		var $bounds = first_bounds(motorcycle)
		var $tries = []
		for _ in 0..<lean_search_round_count {
			tried = lean_try(motorcycle, $bounds)
			$tries = $tries.append(tried)
			$bounds = bounds_after(tried)
		}
		$tries
	}

	## The lean for the next step, whose coast ends nearest the road's middle:
	## halfway between the bounds the last try narrowed to.
	best_lean : Motorcycle -> Angle.Lean
	best_lean = |motorcycle| {
		var $bounds = first_bounds(motorcycle)
		for _ in 0..<lean_search_round_count {
			$bounds = bounds_after(lean_try(motorcycle, $bounds))
		}
		LeanSearch.middle_lean($bounds)
	}
}

## The bounds of the search's first try: the leans one step can reach from the
## motorcycle's own.
first_bounds : Motorcycle -> LeanSearch.LeanBounds
first_bounds = |motorcycle| {
	low: motorcycle.lean.minus(max_lean_change),
	high: motorcycle.lean.plus(max_lean_change),
}

## The most the lean changes in one step.
max_lean_change : Angle.LeanChange
max_lean_change = Angle.LeanChange.degrees(1.0)

## The try between `bounds`: where the coast of the tried motorcycle goes.
lean_try : Motorcycle, LeanSearch.LeanBounds -> LeanSearch.LeanTry
lean_try = |motorcycle, bounds| {
	bounds,
	outcome: Coast.coast_outcome(LeanSearch.tried_motorcycle(motorcycle, bounds)),
}

## The half of a try's bounds its coast points to.
bounds_after : LeanSearch.LeanTry -> LeanSearch.LeanBounds
bounds_after = |{ bounds, outcome }| {
	mid = LeanSearch.middle_lean(bounds)
	match LeanSearch.lean_correction(outcome) {
		MoreRight => { low: mid, high: bounds.high }
		MoreLeft => { low: bounds.low, high: mid }
	}
}

## A coast that ends `metres` across the road.
ending_at : F64 -> Coast.Outcome
ending_at = |metres| EndsAt(Across.metres(metres))

expect LeanSearch.lean_correction(ending_at(-0.1)) == MoreRight
expect LeanSearch.lean_correction(ending_at(0.1)) == MoreLeft
expect LeanSearch.lean_correction(ending_at(0.0)) == MoreLeft

## Bounds a degree either side of upright.
upright_bounds : LeanSearch.LeanBounds
upright_bounds = { low: Angle.Lean.degrees(-1.0), high: Angle.Lean.degrees(1.0) }

# A try halves its bounds, keeping the half its coast points to.
expect LeanSearch.middle_lean(upright_bounds) == Angle.Lean.degrees(0.0)
expect
	bounds_after({ bounds: upright_bounds, outcome: ending_at(-0.1) })
		== { low: Angle.Lean.degrees(0.0), high: Angle.Lean.degrees(1.0) }
expect
	bounds_after({ bounds: upright_bounds, outcome: ending_at(0.1) })
		== { low: Angle.Lean.degrees(-1.0), high: Angle.Lean.degrees(0.0) }

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

## The search's tries for the motorcycle the ride starts with.
initial_tries : List(LeanSearch.LeanTry)
initial_tries = LeanSearch.search_tries(Motorcycle.initial)

# The search makes its rounds of tries, the first between the leans one step can
# reach, and each after it between the half of the one before that its coast
# pointed to.
expect initial_tries.len() == LeanSearch.lean_search_round_count.to_u64()
expect initial_tries.first().map_ok(|first| first.bounds) == Ok(first_bounds(Motorcycle.initial))
expect
	initial_tries
		.map2(initial_tries.drop_first(1), |before, after| after.bounds == bounds_after(before))
		.all(|is_followed| is_followed)

# The lean the search picks is the middle of the half its last try pointed to.
expect {
	picked = initial_tries.last().map_ok(|last| LeanSearch.middle_lean(bounds_after(last)))
	picked == Ok(LeanSearch.best_lean(Motorcycle.initial))
}

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
