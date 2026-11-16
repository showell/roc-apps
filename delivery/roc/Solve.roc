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
		by_slot : List(List(Stop)),
		unrouted : List(Stop),
		minutes : List(Pain.Minutes),
		travel : I64,
		local : F64,
		service : I64,
		time : F64,
		spread : F64,
		start_frame : List(List(Stop)),
		moves : List(Replay.Move),
	}

	Variant : { label : Str, chunking : Build.Chunking, medina : [Deferred, InLine] }

	variants : List(Variant)
	variants = [
		{ label: "room/whole/M+", chunking: Roomiest, medina: Deferred },
		{ label: "room/whole/M-", chunking: Roomiest, medina: InLine },
		{ label: "cost/whole/M+", chunking: Cheapest, medina: Deferred },
		{ label: "cost/whole/M-", chunking: Cheapest, medina: InLine },
	]

	Race : { best : Plan, winner : Str, pains : List({ label : Str, pain : I64 }) }

	race : List(Orders.NeighborhoodOrders) -> Race
	race = |orders| {
		plans = variants.map(|v| { label: v.label, plan: solved(orders, v) })
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
plan_pain = |plan| plan.by_slot.fold(0, |n, r| n + Pain.pain_of(r))

solved : List(Orders.NeighborhoodOrders), Solve.Variant -> Solve.Plan
solved = |orders, variant| {
	all = Build.clusters_of(orders)
	is_deferred = |route| {
		nbhd = (Route.stop_at(route, 0)).nbhd
		nbhd == Seattle.bellevue or (nbhd == Seattle.medina and variant.medina == Deferred)
	}
	deferred = all.keep_if(is_deferred)
	routes = all.drop_if(is_deferred)

	saving = Build.merged({ routes, moves: [] }, Saving)
	to_fleet = if saving.routes.len() > Seattle.truck_count {
		Build.merged(saving, ToFleet)
	} else {
		saving
	}
	forced = if to_fleet.routes.len() > Seattle.truck_count {
		Build.force_placed(to_fleet, variant.chunking)
	} else {
		to_fleet
	}
	built = Build.deferred_placed(forced, { deferred, chunking: variant.chunking })

	tidied = { ..built, routes: built.routes.map(Route.two_opt) }
	moved = Improve.exchanged(Improve.relocated(tidied))
	retidied = { ..moved, routes: moved.routes.map(Route.two_opt) }
	settled = Improve.rebalanced(retidied)
	split = Improve.rebalanced(Improve.exchanged(Improve.split(settled)))
	merged = split.routes.map(|r| Route.two_opt(Route.coalesce(r)))

	fleet = merged.take_first(Seattle.truck_count)
	spilled = merged.drop_first(Seattle.truck_count).rev().join_map(|r| r)
	slotted = slots_of(fleet, spilled)

	# The corridor race: shackled against free, the cheaper by tidied pain,
	# ties to the shackled.
	start = { by_slot: slotted.by_slot, moves: [] }
	shackled = SlotSearch.corridor_repaired(start, CapacityNeutral)
	free = SlotSearch.corridor_repaired(start, AnyShift)
	shackled_pain = shackled.by_slot.fold(0, |n, r| n + Route.tidied_pain(r))
	free_pain = free.by_slot.fold(0, |n, r| n + Route.tidied_pain(r))
	repaired = if free_pain < shackled_pain {
		free
	} else {
		shackled
	}

	searched = SlotSearch.relocated_or_swapped({ by_slot: repaired.by_slot.map(Route.two_opt), moves: [] })
	rebalanced = SlotSearch.arc_rebalanced({ by_slot: searched.by_slot.map(Route.two_opt), moves: [] })
	by_slot = SlotSearch.houses_tidied(rebalanced.by_slot.map(Route.two_opt))

	minutes = by_slot.map(Pain.minutes_of)
	travel = minutes.fold(0, |n, m| n + m.travel)
	local = minutes.fold(0, |n, m| n + m.local)
	service = minutes.fold(0, |n, m| n + m.service)
	deployed = by_slot.map_with_index(|r, i| { r, i }).keep_if(|e| !e.r.is_empty()).map(|e| (minutes.get(e.i) ?? crash "Solve.solved: in range").time)
	spread =
		match (deployed.max(), deployed.min()) {
			(Ok(most), Ok(least)) => most - least
			_ => 0
		}
	{
		by_slot,
		unrouted: slotted.unrouted,
		minutes,
		travel,
		local,
		service,
		time: travel.to_f64() + local + service.to_f64(),
		spread,
		start_frame: routes,
		moves: split.moves.concat(repaired.moves).concat(searched.moves).concat(rebalanced.moves),
	}
}

## The routes given their trucks' slots: an anchored route its anchor's
## truck, then the rest into idle trucks that can take them, the biggest
## first, or spilled across the trucks with the most room. `spilled` is the
## stops of routes past the fleet, which no truck takes.
slots_of : List(List(Stop)), List(Stop) -> { by_slot : List(List(Stop)), unrouted : List(Stop) }
slots_of = |routes, spilled| {
	var $slots = List.repeat([], Seattle.truck_count)
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
		match $slots.map_with_index(|s, i| { s, i }).find_first(|e| e.s.is_empty() and Route.load(r) <= Seattle.cap_of_slot(e.i)) {
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
							free = Seattle.cap_of_slot(i).to_i64_wrap() - Route.load(slot_route($slots, i)).to_i64_wrap()
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
							$slots = $slots.set($into, slot_route($slots, $into).append(Route.free_stop(stop.nbhd, $houses.take_first(take)))) ?? crash "Solve.slots_of: in range"
							$houses = $houses.drop_first(take)
						}
					}
				}
		}
	}
	{ by_slot: $slots.map(Route.coalesce), unrouted: $unrouted }
}

slot_route : List(List(Stop)), U64 -> List(Stop)
slot_route = |slots, i| slots.get(i) ?? crash "Solve.slot_route: one of the eight slots"
