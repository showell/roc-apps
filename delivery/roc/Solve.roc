## One full solve of a day's orders, and the race of four solves the plan
## comes from. A solve builds the routes (Build), improves them before they
## have trucks (Improve), gives each its truck's slot, then improves them
## again within each truck's cap (SlotSearch), recording every move for the
## page's replay. The race solves the day four ways, two ways of splitting
## an oversized piece by two ways of holding Medina back, and keeps the
## plan of least pain, the first of equals.

import Build
import Houses
import Improve
import Orders
import Pain
import Replay
import Route
import Seattle
import SlotSearch
import Stop

Solve :: [].{

	## A solved day: each truck's route by slot (an idle truck's empty),
	## the stops no truck had room for (a legal plan has none), the display
	## minutes, and the replay: the clusters it started from, every move,
	## and the routes it ended with.
	Plan : {
		slot_routes : List(List(Stop)),
		unrouted : List(Stop),
		minutes : List(Pain.Minutes),
		travel : I64,
		local : F64,
		service : I64,
		time : F64,
		spread : F64,
		start_routes : List(List(Stop)),
		moves : List(Replay.Move),
	}

	Variant : {
		label : Str,
		chunking : Build.Chunking,
		medina : [Deferred, InLine],
	}

	variants : List(Variant)
	variants = [
		{
			label: "room/whole/M+",
			chunking: Roomiest,
			medina: Deferred,
		},
		{
			label: "room/whole/M-",
			chunking: Roomiest,
			medina: InLine,
		},
		{
			label: "cost/whole/M+",
			chunking: Cheapest,
			medina: Deferred,
		},
		{
			label: "cost/whole/M-",
			chunking: Cheapest,
			medina: InLine,
		},
	]

	Race : {
		best : Plan,
		winner : Str,
		pains : List({ label : Str, pain : I64 }),
	}

	race : List(Orders.NeighborhoodOrders) -> Race
	race = |orders| {
		plans = variants.map(|v| { label: v.label, plan: solve_variant(orders, v) })
		pains = plans.map(|p| { label: p.label, pain: plan_pain(p.plan) })
		first = plans.first() ?? crash "Solve.race: four variants"
		var $best = first
		var $best_pain = plan_pain(first.plan)
		for p in plans.drop_first(1) {
			pain = plan_pain(p.plan)
			if pain < $best_pain {
				$best_pain = pain
				$best = p
			}
		}
		{ best: $best.plan, winner: $best.label, pains }
	}
}

plan_pain : Solve.Plan -> I64
plan_pain = |plan| plan.slot_routes.fold(0, |n, r| n + Pain.pain_of(r))

solve_variant : List(Orders.NeighborhoodOrders), Solve.Variant -> Solve.Plan
solve_variant = |orders, variant| {
	all = Build.clusters_of(orders)
	is_deferred = |route| {
		nbhd = (Route.stop_at(route, 0)).nbhd
		nbhd == Seattle.bellevue or (nbhd == Seattle.medina and variant.medina == Deferred)
	}
	deferred = all.keep_if(is_deferred)
	routes = all.drop_if(is_deferred)

	saving = Build.merge_routes({ routes, moves: [] }, Saving)
	to_fleet = if saving.routes.len() > Seattle.truck_count {
		Build.merge_routes(saving, ToFleet)
	} else {
		saving
	}
	forced = if to_fleet.routes.len() > Seattle.truck_count {
		Build.force_placed(to_fleet, variant.chunking)
	} else {
		to_fleet
	}
	built = Build.deferred_placed(forced, { deferred, chunking: variant.chunking })

	tidied = { ..built, routes: built.routes.map(Route.two_opt_stops) }
	moved = Improve.exchange_stops(Improve.relocate_stops(tidied))
	retidied = { ..moved, routes: moved.routes.map(Route.two_opt_stops) }
	settled = Improve.rebalance_stops(retidied)
	split = Improve.rebalance_stops(Improve.exchange_stops(Improve.split(settled)))
	merged_routes = split.routes.map(|r| Route.two_opt_stops(Route.coalesced_stops(r)))

	fleet = merged_routes.take_first(Seattle.truck_count)
	spilled = merged_routes.drop_first(Seattle.truck_count).rev().join_map(|r| r)
	slotted = slots_of(fleet, spilled)

	# The corridor race: shackled against free, the cheaper by tidied pain,
	# ties to the shackled.
	start = { slot_routes: slotted.slot_routes, moves: [] }
	shackled = SlotSearch.corridor_repaired(start, CapacityNeutral)
	free = SlotSearch.corridor_repaired(start, AnyShift)
	shackled_pain = shackled.slot_routes.fold(0, |n, r| n + Route.tidied_pain(r))
	free_pain = free.slot_routes.fold(0, |n, r| n + Route.tidied_pain(r))
	repaired = if free_pain < shackled_pain {
		free
	} else {
		shackled
	}

	searched = SlotSearch.relocated_or_swapped({
		slot_routes: repaired.slot_routes.map(Route.two_opt_stops),
		moves: [],
	})
	rebalanced_slots = SlotSearch.arc_rebalanced({
		slot_routes: searched.slot_routes.map(Route.two_opt_stops),
		moves: [],
	})
	slot_routes = SlotSearch.houses_tidied(rebalanced_slots.slot_routes.map(Route.two_opt_stops))

	minutes = slot_routes.map(Pain.minutes_of)
	travel = minutes.fold(0, |n, m| n + m.travel)
	local = minutes.fold(0, |n, m| n + m.local)
	service = minutes.fold(0, |n, m| n + m.service)
	deployed = slot_routes.map_with_index(
		|r, i| { r, i },
	).keep_if(|e| !e.r.is_empty()).map(|e| (minutes.get(e.i) ?? crash "Solve.solve_variant: in range").time)
	spread =
		match (deployed.max(), deployed.min()) {
			(Ok(most), Ok(least)) => most - least
			_ => 0
		}
	{
		slot_routes,
		unrouted: slotted.unrouted,
		minutes,
		travel,
		local,
		service,
		time: travel.to_f64() + local + service.to_f64(),
		spread,
		start_routes: routes,
		moves: [split.moves, repaired.moves, searched.moves, rebalanced_slots.moves].join(),
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
	for r in Build.items_by_load_desc($leftover, Route.load) {
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
								slot_stops($slots, i),
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
								slot_stops($slots, $into).append(piece),
							) ?? crash "Solve.slots_of: in range"
							$houses = $houses.drop_first(take)
						}
					}
				}
		}
	}
	{ slot_routes: $slots.map(Route.coalesced_stops), unrouted: $unrouted }
}

slot_stops : List(List(Stop)), U64 -> List(Stop)
slot_stops = |slots, i| slots.get(i) ?? crash "Solve.slot_stops: one of the eight slots"
