## The solver's front door. `routes_traced` gives a day's dispatch plan and
## the trace of how it was found, which the page replays: it races
## `attempt`, the algorithm in one screen (Clarke-Wright savings over the
## day's neighborhoods, then local search), over the strategy's variants,
## and keeps the attempt of least pain, the first of equals. The stages are
## Build's, Improve's and SlotSearch's, each threading the trace's moves
## along.

import Build
import Houses
import Improve
import Itinerary
import Orders
import Pain
import Replay
import Route
import Seattle
import SlotSearch
import Stop

Solve :: [].{

	## The day's orders, the fleet that carries them, and the map.
	Day : {
		orders : List(Orders.NeighborhoodOrders),
		fleet : Seattle.Fleet,
		geography : Seattle.Geography,
	}

	## The day's plan: each truck's itinerary, by its slot (an idle truck's
	## has no stops), and the stops no truck had room for (a legal plan has
	## none).
	DispatchPlan : { itineraries : List(Itinerary), unrouted : List(Stop) }

	## How the plan was found, for the page's replay: the routes the merging
	## started from, and every move since.
	Trace : { start_routes : List(List(Stop)), moves : List(Replay.Move) }

	## One way the strategy can run: how a piece too big for one truck is
	## split, and which neighborhoods are overflow ones, left out of the
	## merging and placed in the trucks' room at the end. `name` is in plain
	## words; `reference_label` is solver.ts's name for it, which the gold
	## pins.
	StrategyVariant : {
		name : Str,
		reference_label : Str,
		chunking : Build.Chunking,
		overflow_neighborhoods : List(U8),
	}

	## The day's dispatch plan, and the trace of how it was found.
	routes_traced : Day -> { dispatch_plan : DispatchPlan, trace : Trace }
	routes_traced = |day| {
		best = race(day).best
		{ dispatch_plan: dispatch_plan_of(best), trace: best.trace }
	}

	## An attempt's routes as itineraries.
	dispatch_plan_of : Attempt -> DispatchPlan
	dispatch_plan_of = |best| {
		itineraries: best.slot_routes.map(Itinerary.itinerary_of),
		unrouted: best.unrouted,
	}

	## The strategy's variants for a day: each way of splitting an oversized
	## piece, by each choice of which either-way neighborhoods are overflow,
	## all of them first.
	strategy_variants : Day -> List(StrategyVariant)
	strategy_variants = |{ geography, .. }| {
		always = geography_overflow(geography, Overflow)
		either_way = geography_overflow(geography, EitherWay)
		choices = overflow_choices(either_way)
		[Roomiest, Cheapest].join_map(
			|chunking|
				choices.map(
					|chosen| {
						name: variant_name(chunking, { either_way, chosen }),
						reference_label: reference_label(chunking, { either_way, chosen }),
						chunking,
						overflow_neighborhoods: List.concat(always, chosen),
					},
				),
		)
	}

	## One attempt at the day, the strategy run one way: Clarke and Wright's
	## savings, then local search.
	attempt : Day, StrategyVariant -> Attempt
	attempt = |{ orders, fleet, .. }, variant| {
		# One cluster per neighborhood, an anchor's first houses pinned to its
		# truck; the overflow neighborhoods' clusters wait for the end.
		{ overflow_routes, routes } = set_aside_overflow(
			clusters(orders),
			variant.overflow_neighborhoods,
		)

		# Clarke-Wright: join the two routes whose join saves the most pain,
		# while a join saves any.
		saved = merge_by_savings(routes)

		# Down to the fleet: join on regardless, then pack what is left onto
		# trucks with room; and the overflow neighborhoods into the room left.
		fitted = fit_to_fleet(saved, { fleet, chunking: variant.chunking })
		placed = place_overflow_neighborhoods(
			fitted,
			{ overflow_routes, chunking: variant.chunking },
		)

		# Local search: 2-opt, relocate, exchange, rebalance and split.
		improved = improve_routes(placed)

		# Each route its truck: an anchored one its anchor's.
		assigned = assign_trucks(improved, fleet)

		# Local search within each truck's own cap.
		finished = improve_assigned(assigned)

		{
			slot_routes: finished.slot_routes,
			unrouted: finished.unrouted,
			trace: { start_routes: routes, moves: finished.moves },
		}
	}

	## An attempt's routes, by slot, its unrouted stops and its trace.
	Attempt : {
		slot_routes : List(List(Stop)),
		unrouted : List(Stop),
		trace : Trace,
	}

	## Every variant's attempt and its pain, and the best: the least pain,
	## the first of equals.
	Race : {
		best : Attempt,
		winner : StrategyVariant,
		pains : List({ variant : StrategyVariant, pain : I64 }),
	}

	race : Day -> Race
	race = |day| {
		attempts = strategy_variants(day).map(|v| { variant: v, attempt: attempt(day, v) })
		pains = attempts.map(|a| { variant: a.variant, pain: attempt_pain(a.attempt) })
		first = attempts.first() ?? crash "Solve.race: a strategy has variants"
		var $best = first
		var $best_pain = attempt_pain(first.attempt)
		for a in attempts.drop_first(1) {
			pain = attempt_pain(a.attempt)
			if pain < $best_pain {
				$best_pain = pain
				$best = a
			}
		}
		{ best: $best.attempt, winner: $best.variant, pains }
	}

	## The day, with Seattle's fleet and geography.
	seattle_day : List(Orders.NeighborhoodOrders) -> Day
	seattle_day = |orders| { orders, fleet: Seattle.fleet, geography: Seattle.geography }

	## The page's plan: the routes with their display minutes and the trace.
	PagePlan : {
		slot_routes : List(List(Stop)),
		unrouted : List(Stop),
		minutes : List(Pain.Minutes),
		route_times : List(F64),
		travel : I64,
		local : F64,
		service : I64,
		time : F64,
		spread : F64,
		trace : Trace,
	}

	## The page's plan from the dispatch plan: each route's display minutes
	## (its time the itinerary's expected return), the totals in route order,
	## and the spread over the trucks deployed.
	page_plan : { dispatch_plan : DispatchPlan, trace : Trace } -> PagePlan
	page_plan = |{ dispatch_plan, trace }| {
		slot_routes = dispatch_plan.itineraries.map(Itinerary.route)
		minutes = slot_routes.map(Pain.minutes_of)
		route_times = dispatch_plan.itineraries.map(|i| i.expected_return)
		travel = minutes.fold(0, |n, m| n + m.travel)
		local = minutes.fold(0, |n, m| n + m.local)
		service = minutes.fold(0, |n, m| n + m.service)
		deployed = route_times.map_with_index(
			|time, i| { time, i },
		).keep_if(|e| !(slot_routes.get(e.i) ?? crash "Solve.page_plan: in range").is_empty()).map(|e| e.time)
		spread =
			match (deployed.max(), deployed.min()) {
				(Ok(most), Ok(least)) => most - least
				_ => 0
			}
		{
			slot_routes,
			unrouted: dispatch_plan.unrouted,
			minutes,
			route_times,
			travel,
			local,
			service,
			time: travel.to_f64() + local + service.to_f64(),
			spread,
			trace,
		}
	}
}

attempt_pain : Solve.Attempt -> I64
attempt_pain = |a| a.slot_routes.fold(0, |n, r| n + Pain.pain_of(r))

## The neighborhoods of the geography with this overflow tag, in map order.
geography_overflow : Seattle.Geography, [Overflow, EitherWay] -> List(U8)
geography_overflow = |geography, tag|
	geography.neighborhoods.map_with_index(|n, i| { n, i }).keep_if(
		|e|
			match (e.n.overflow, tag) {
				(Overflow, Overflow) => True
				(EitherWay, EitherWay) => True
				_ => False
			},
	).map(|e| e.i.to_u8_wrap())

## Every choice of the either-way neighborhoods to make overflow: all of
## them first, then by dropping the last ones first.
overflow_choices : List(U8) -> List(List(U8))
overflow_choices = |either_way|
	match either_way {
		[] => [[]]
		[first, .. as rest] => {
			later = overflow_choices(rest)
			List.concat(later.map(|c| c.prepend(first)), later)
		}
	}

variant_name : Build.Chunking, { either_way : List(U8), chosen : List(U8) } -> Str
variant_name = |chunking, { either_way, chosen }| {
	truck =
		match chunking {
			Roomiest => "roomiest truck"
			Cheapest => "cheapest truck"
		}
	parts = either_way.map(
		|n|
			if chosen.contains(n) {
				"${Seattle.name_of(n)} as overflow"
			} else {
				"${Seattle.name_of(n)} routed"
			},
	)
	Str.join_with(List.concat([truck], parts), ", ")
}

## solver.ts's label: `room` or `cost`, then each either-way neighborhood's
## initial with `+` when it is overflow (`room/whole/M+`).
reference_label : Build.Chunking, { either_way : List(U8), chosen : List(U8) } -> Str
reference_label = |chunking, { either_way, chosen }| {
	kind =
		match chunking {
			Roomiest => "room"
			Cheapest => "cost"
		}
	marks = either_way.map(
		|n| {
			initial = Str.from_utf8(Seattle.name_of(n).to_utf8().take_first(1)) ?? crash "Solve.reference_label: an ASCII name"
			if chosen.contains(n) {
				"${initial}+"
			} else {
				"${initial}-"
			}
		},
	)
	"${kind}/whole/${Str.join_with(marks, "")}"
}

## Work in progress before the trucks are assigned: the routes, and the
## moves recorded so far.
Unassigned : { routes : List(List(Stop)), moves : List(Replay.Move) }

## One cluster per neighborhood of the day's orders, in the order the day
## drew them, an anchor's first houses pinned to its truck.
clusters : List(Orders.NeighborhoodOrders) -> List(List(Stop))
clusters = |orders| Build.clusters_of(orders)

## The clusters split into the overflow neighborhoods' and the rest, each
## in order.
set_aside_overflow : List(List(Stop)),
List(U8) -> {
	overflow_routes : List(List(Stop)),
	routes : List(List(Stop)),
}
set_aside_overflow = |all_routes, overflow_neighborhoods| {
	is_overflow = |route| overflow_neighborhoods.contains(Route.stop_at(route, 0).nbhd)
	{ overflow_routes: all_routes.keep_if(is_overflow), routes: all_routes.drop_if(is_overflow) }
}

## Clarke and Wright's savings over the clusters, the trace's moves
## starting from none.
merge_by_savings : List(List(Stop)) -> Unassigned
merge_by_savings = |routes| Build.merge_routes({ routes, moves: [] }, Saving)

## Joins on regardless while there are more routes than trucks, then, if
## that can't reach the fleet, packs the rest onto the trucks with room.
fit_to_fleet : Unassigned, { fleet : Seattle.Fleet, chunking : Build.Chunking } -> Unassigned
fit_to_fleet = |work, { fleet, chunking }| {
	joined =
		if work.routes.len() > fleet.truck_count {
			Build.merge_routes(work, ToFleet)
		} else {
			work
		}
	if joined.routes.len() > fleet.truck_count {
		Build.force_placed(joined, chunking)
	} else {
		joined
	}
}

## The overflow neighborhoods into the trucks' room, each where it costs
## least.
place_overflow_neighborhoods : Unassigned,
{
	overflow_routes : List(List(Stop)),
	chunking : Build.Chunking,
} -> Unassigned
place_overflow_neighborhoods = |
	work,
	{ overflow_routes, chunking },
| Build.overflow_placed(work, { overflow_routes, chunking })

## 2-opt each route, relocate and exchange stops, 2-opt again, rebalance,
## split arcs off, exchange and rebalance again, and merge each route's
## stops of one neighborhood.
improve_routes : Unassigned -> Unassigned
improve_routes = |work| {
	tidied = { ..work, routes: work.routes.map(Route.two_opt) }
	moved = Improve.exchange_stops(Improve.relocate_stops(tidied))
	retidied = { ..moved, routes: moved.routes.map(Route.two_opt) }
	settled = Improve.rebalance_stops(retidied)
	split = Improve.rebalance_stops(Improve.exchange_stops(Improve.split(settled)))
	{ ..split, routes: split.routes.map(|r| Route.two_opt(Route.coalesce(r))) }
}

## The routes given their trucks (`slots_of`); routes past the fleet, which
## a legal plan never has, are unrouted.
assign_trucks : Unassigned,
Seattle.Fleet -> {
	slot_routes : List(List(Stop)),
	unrouted : List(Stop),
	moves : List(Replay.Move),
}
assign_trucks = |work, fleet| {
	kept = work.routes.take_first(fleet.truck_count)
	spilled = work.routes.drop_first(fleet.truck_count).rev().join_map(|r| r)
	slotted = slots_of(kept, spilled)
	{
		slot_routes: slotted.slot_routes,
		unrouted: slotted.unrouted,
		moves: work.moves,
	}
}

## Corridor repair, raced two ways (capacity-neutral against free, the
## cheaper by tidied pain, ties to the capacity-neutral), then relocate and
## swap between trucks, arc-rebalance, and the houses tidied, each step
## after a 2-opt.
improve_assigned : {
	slot_routes : List(List(Stop)),
	unrouted : List(Stop),
	moves : List(Replay.Move),
} -> {
	slot_routes : List(List(Stop)),
	unrouted : List(Stop),
	moves : List(Replay.Move),
}
improve_assigned = |assigned| {
	start = { slot_routes: assigned.slot_routes, moves: [] }
	shackled = SlotSearch.corridor_repaired(start, CapacityNeutral)
	free = SlotSearch.corridor_repaired(start, AnyShift)
	shackled_pain = shackled.slot_routes.fold(0, |n, r| n + Route.tidied_pain(r))
	free_pain = free.slot_routes.fold(0, |n, r| n + Route.tidied_pain(r))
	repaired =
		if free_pain < shackled_pain {
			free
		} else {
			shackled
		}
	searched = SlotSearch.relocated_or_swapped({
		slot_routes: repaired.slot_routes.map(Route.two_opt),
		moves: [],
	})
	rebalanced = SlotSearch.arc_rebalanced({
		slot_routes: searched.slot_routes.map(Route.two_opt),
		moves: [],
	})
	{
		slot_routes: SlotSearch.houses_tidied(rebalanced.slot_routes.map(Route.two_opt)),
		unrouted: assigned.unrouted,
		moves: [assigned.moves, repaired.moves, searched.moves, rebalanced.moves].join(),
	}
}

## The routes given their trucks' slots: an anchored route its anchor's
## truck, then the rest into idle trucks that can take them, the biggest
## first, or spilled across the trucks with the most room. `spilled` is the
## stops of routes past the fleet, which no truck takes.
slots_of : List(List(Stop)), List(Stop) -> { slot_routes : List(List(Stop)), unrouted : List(Stop) }
slots_of = |routes, spilled| {
	var $slots = [].repeat(Seattle.truck_count)
	var $leftover = []
	for r in routes {
		if !r.is_empty() {
			match r.find_first(|s| s.is_pinned()) {
				Ok(stop) =>
					match stop.pin {
						Pinned(slot) => {
							$slots = $slots.set(slot, r) ?? crash "Solve.slots_of: a pin is a slot"
						}

						Free => crash "Solve.slots_of: a pinned stop has a slot"
					}

				Err(NotFound) => {
					$leftover = $leftover.append(r)
				}
			}
		}
	}
	var $unrouted = spilled
	for r in Build.stable_by_load_desc($leftover, Route.load) {
		match $slots.map_with_index(
			|s, i| { s, i },
		).find_first(|e| e.s.is_empty() and Route.load(r) <= Seattle.cap_of_slot(e.i)) {
			Ok(e) => {
				$slots = $slots.set(e.i, r) ?? crash "Solve.slots_of: in range"
			}

			Err(NotFound) =>
				for stop in r {
					var $houses = stop.houses
					while !$houses.is_empty() {
						var $room = 0
						var $into = 0
						for i in 0..<$slots.len() {
							free = Seattle.cap_of_slot(i).to_i64_wrap() - Route.load(
								slot_route($slots, i),
							).to_i64_wrap()
							if free > $room {
								$room = free
								$into = i
							}
						}
						if $room <= 0 {
							$unrouted = $unrouted.append(Route.free_stop(stop.nbhd, $houses))
							$houses = Houses.empty
						} else {
							take = $room.to_u64_wrap()
							piece = Route.free_stop(stop.nbhd, $houses.take_first(take))
							$slots = $slots.set(
								$into,
								slot_route($slots, $into).append(piece),
							) ?? crash "Solve.slots_of: in range"
							$houses = $houses.drop_first(take)
						}
					}
				}
		}
	}
	{ slot_routes: $slots.map(Route.coalesce), unrouted: $unrouted }
}

slot_route : List(List(Stop)), U64 -> List(Stop)
slot_route = |slots, i| slots.get(i) ?? crash "Solve.slot_route: one of the eight slots"
