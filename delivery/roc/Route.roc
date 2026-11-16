## A truck's route is a list of stops, driven in order out of the FC and
## back. These are the edits the solver makes to one: its load and its
## cap, inserting a stop where it costs least, merging a neighborhood's
## stops into one, and 2-opt's tidy.
##
## Ties go to the first candidate in scan order everywhere (every compare
## is strict), so each scan's order is semantics, as in solver.ts.

import Houses
import Pain
import Seattle
import Stop

Route :: [].{

	## The route's totes. These helpers run inside the scans, so they read
	## the stops by index: a `for`, `fold` or `any` over the list would count
	## it up and down, atomically, each call.
	load : List(Stop) -> U64
	load = |stops| {
		var $n = 0
		for j in 0..<stops.len() {
			$n = $n + stop_at(stops, j).load()
		}
		$n
	}

	has_anchor : List(Stop) -> Bool
	has_anchor = |stops|
		match anchor_of(stops) {
			Anchored(_) => True
			Unanchored => False
		}

	## The totes a route may carry: its anchor's truck's cap, or, with no
	## anchor yet, the most any truck carries.
	cap : List(Stop) -> U64
	cap = |stops|
		match anchor_of(stops) {
			Anchored(slot) => Seattle.cap_of_slot(slot)
			Unanchored => Seattle.max_cap
		}

	## The route with `stop` at place `at`.
	insert_at : List(Stop), { at : U64, stop : Stop } -> List(Stop)
	insert_at = |stops, { at, stop }| stops.insert(at, stop) ?? crash "Route.insert_at: a place in the route"

	stop_at : List(Stop), U64 -> Stop
	stop_at = |stops, i| stops.get(i) ?? crash "Route.stop_at: a stop of the route"

	## One stop per neighborhood: each later stop's houses join the first's,
	## which keeps its place, and a pin joins with them.
	coalesce : List(Stop) -> List(Stop)
	coalesce = |stops|
		if has_repeat(stops) {
			coalesced(stops)
		} else {
			stops
		}

	## `stop` at its cheapest place, the earliest of equals.
	insert_best : List(Stop), Stop -> List(Stop)
	insert_best = |stops, stop| {
		n = stops.len()
		first = Pain.priced(stops, Inserted({ at: 0, stop }))
		var $route = first.stops
		var $best_at = 0
		var $best_pain = first.pain
		for at in 1..=n {
			p = Pain.priced($route, Inserted({ at, stop }))
			$route = p.stops
			if p.pain < $best_pain {
				$best_pain = p.pain
				$best_at = at
			}
		}
		insert_at($route, { at: $best_at, stop })
	}

	## `stop` at its cheapest place, merged into a stop of its neighborhood
	## the route already has: of equals, appending it at the end.
	cheapest_insert : List(Stop), Stop -> List(Stop)

	##
	## On a route with one stop a neighborhood, the only candidates that
	## differ are the append (the stop merged into its neighborhood's, or
	## added at the end) and, where the neighborhood has a stop at `e`, the
	## merged stop moved to each place up to `e`: so those are priced in
	## place, in the scan's order, and only the winner is built.
	cheapest_insert = |stops, stop| {
		match stops.find_first_index(|s| s.nbhd == stop.nbhd) {
			_ if has_repeat(stops) => cheapest_insert_by_building(stops, stop)
			Err(NotFound) => {
				var $best_at = stops.len()
				var $best_pain = Pain.pain_of_view(stops, Inserted({ at: stops.len(), stop }))
				for at in 0..<stops.len() {
					pain = Pain.pain_of_view(stops, Inserted({ at, stop }))
					if pain < $best_pain {
						$best_pain = pain
						$best_at = at
					}
				}
				insert_at(stops, { at: $best_at, stop })
			}

			Ok(e) => {
				old = stop_at(stops, e)
				back = {
					nbhd: old.nbhd,
					houses: old.houses.concat(stop.houses),
					pin: if stop.is_pinned() {
						stop.pin
					} else {
						old.pin
					},
				}
				front = {
					nbhd: stop.nbhd,
					houses: stop.houses.concat(old.houses),
					pin: if old.is_pinned() {
						old.pin
					} else {
						stop.pin
					},
				}
				appended = stops.set(e, back) ?? crash "Route.cheapest_insert: in range"
				rest = stops.drop_at(e)
				var $best_at = stops.len()
				var $best_pain = Pain.pain_of(appended)
				for at in 0..=e {
					pain = Pain.pain_of_view(rest, Inserted({ at, stop: front }))
					if pain < $best_pain {
						$best_pain = pain
						$best_at = at
					}
				}
				if $best_at == stops.len() {
					appended
				} else {
					insert_at(rest, { at: $best_at, stop: front })
				}
			}
		}
	}

	## The same as `cheapest_insert`, each candidate built and merged: for a
	## route that has two stops in one neighborhood.
	cheapest_insert_by_building : List(Stop), Stop -> List(Stop)
	cheapest_insert_by_building = |stops, stop| {
		var $best = coalesce(stops.append(stop))
		var $best_pain = Pain.pain_of($best)
		for at in 0..<stops.len() {
			candidate = coalesce(insert_at(stops, { at, stop }))
			pain = Pain.pain_of(candidate)
			if pain < $best_pain {
				$best_pain = pain
				$best = candidate
			}
		}
		$best
	}

	## The route without the stop at `at`, and `stop` at its cheapest place.
	reinsert : List(Stop), { at : U64, stop : Stop } -> List(Stop)
	reinsert = |stops, { at, stop }| insert_best(stops.drop_at(at), stop)

	## 2-opt: reverse any run of stops whose reversal cuts the pain, taking
	## each as found, until a whole scan finds none.
	two_opt : List(Stop) -> List(Stop)
	two_opt = |stops| {
		n = stops.len()
		start = Pain.priced(stops, Whole)
		var $route = start.stops
		var $pain = start.pain
		var $improved = True
		while $improved {
			$improved = False
			for i in 0..<n {
				for k in (i + 1)..<n {
					p = Pain.priced($route, Reversed({ first: i, last: k }))
					$route = p.stops
					if $pain - p.pain >= 1 {
						$route = reversed_run($route, { first: i, last: k })
						$pain = p.pain
						$improved = True
					}
				}
			}
		}
		$route
	}

	## The pain of a route as the solver will leave it, after 2-opt.
	tidied_pain : List(Stop) -> I64
	tidied_pain = |stops| Pain.pain_of(two_opt(stops))

	## A stop of `houses` in `nbhd`, free to move.
	free_stop : U8, Houses -> Stop
	free_stop = |nbhd, houses| { nbhd, houses, pin: Free }
}

## `Route.coalesce` of a route with a repeat, built anew.
coalesced : List(Stop) -> List(Stop)
coalesced = |stops| {
	var $out = []
	for s in stops {
		$out = match $out.find_first_index(|o| o.nbhd == s.nbhd) {
			Ok(i) => {
				{ list, prev } = $out.replace(i, s) ?? crash "Route.coalesce: in range"
				pin = if s.is_pinned() {
					s.pin
				} else {
					prev.pin
				}
				list.set(i, { nbhd: prev.nbhd, houses: prev.houses.concat(s.houses), pin }) ?? crash "Route.coalesce: in range"
			}

			Err(NotFound) => $out.append(s)
		}
	}
	$out
}

## The slot of the route's first pinned stop, if it has one.
anchor_of : List(Stop) -> [Anchored(U64), Unanchored]
anchor_of = |stops| {
	var $anchor = Unanchored
	var $j = stops.len()
	while $j > 0 {
		$j = $j - 1
		match Route.stop_at(stops, $j).pin {
			Pinned(slot) => {
				$anchor = Anchored(slot)
			}

			Free => {}
		}
	}
	$anchor
}

## Whether two of the stops are in one neighborhood.
has_repeat : List(Stop) -> Bool
has_repeat = |stops| {
	var $seen = 0
	var $repeat = False
	for j in 0..<stops.len() {
		bit = U64.shl_wrap(1, Route.stop_at(stops, j).nbhd)
		if $seen.bitwise_and(bit) != 0 {
			$repeat = True
		}
		$seen = $seen.bitwise_or(bit)
	}
	$repeat
}

## The route with the stops from `first` to `last` reversed.
reversed_run : List(Stop), { first : U64, last : U64 } -> List(Stop)
reversed_run = |stops, { first, last }|
	stops
		.take_first(first)
		.concat(stops.sublist({ start: first, len: last - first + 1 }).rev())
		.concat(stops.drop_first(last + 1))
