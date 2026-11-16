## The solver's top level: `routes_for`, the algorithm in one screen
## (Clarke-Wright savings over the day's neighborhoods, then local search),
## each stage a function below it, and the race that runs it four ways (two
## ways of splitting an oversized piece by two of holding Medina back) and
## keeps the plan of least pain, the first of equals. The stages are
## Build's, Improve's and SlotSearch's; each threads the replay's moves
## along, and the display minutes are worked out from the routes after.

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

	## A day's trucks' routes, by slot, with the stops no truck had room
	## for (a legal plan has none), and the replay: the routes the merging
	## started from and every move since.
	Routes : {
		slot_routes : List(List(Stop)),
		unrouted : List(Stop),
		start_routes : List(List(Stop)),
		moves : List(Replay.Move),
	}

	## The day's orders, the fleet that carries them, and the map.
	Day : {
		orders : List(Orders.NeighborhoodOrders),
		fleet : Seattle.Fleet,
		geography : Seattle.Geography,
	}

	## This is the algorithm: Clarke and Wright's savings, then local search.
	## `variant` is how the race varies it: how a piece too big for one
	## truck is split, and whether Medina waits with Bellevue.
	routes_for : Day, Variant -> Routes
	routes_for = |{ orders, fleet, geography }, variant| {
		# One cluster per neighborhood, an anchor's first houses pinned to its
		# truck; the FC's doorstep neighborhoods wait for the end.
		{ held_routes, waiting_routes } = hold_back(clusters(orders), doorstep(geography, variant.medina))

		# Clarke-Wright: join the two routes whose join saves the most pain,
		# while a join saves any.
		saved = merge_by_savings(waiting_routes)

		# Down to the fleet: join on regardless, then pack what is left onto
		# trucks with room; and the held-back neighborhoods into the slack.
		fitted = fit_to_fleet(saved, { fleet, chunking: variant.chunking })
		joined = join_held_routes(fitted, { held_routes, chunking: variant.chunking })

		# Local search: 2-opt, relocate, exchange, rebalance and split.
		improved = improve_routes(joined)

		# Each route its truck: an anchored one its anchor's.
		assigned = assign_trucks(improved, fleet)

		# Local search within each truck's own cap.
		finished = improve_assigned(assigned)

		{
			slot_routes: finished.slot_routes,
			unrouted: finished.unrouted,
			moves: finished.moves,
			start_routes: waiting_routes,
		}
	}

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

## One variant's plan: its routes, and their display minutes.
solve_variant : List(Orders.NeighborhoodOrders), Solve.Variant -> Solve.Plan
solve_variant = |orders, variant|
	Solve.routes_for({ orders, fleet: Seattle.fleet, geography: Seattle.geography }, variant)
		|> plan_of

## Work in progress before the trucks are assigned: the routes, and the
## moves recorded so far.
Unassigned : { routes : List(List(Stop)), moves : List(Replay.Move) }

## One cluster per neighborhood of the day's orders, in the order the day
## drew them, an anchor's first houses pinned to its truck.
clusters : List(Orders.NeighborhoodOrders) -> List(List(Stop))
clusters = |orders| Build.clusters_of(orders)

## The doorstep neighborhoods this variant holds back.
doorstep : Seattle.Geography, [Deferred, InLine] -> List(U8)
doorstep = |geography, medina|
	match medina {
		Deferred => geography.always_held.concat(geography.sometimes_held)
		InLine => geography.always_held
	}

## The clusters split into those of the held-back neighborhoods and the
## rest, each in order.
hold_back : List(List(Stop)),
List(U8) -> {
	held_routes : List(List(Stop)),
	waiting_routes : List(List(Stop)),
}
hold_back = |all_routes, nbhds| {
	is_held = |route| nbhds.contains(Route.stop_at(route, 0).nbhd)
	{ held_routes: all_routes.keep_if(is_held), waiting_routes: all_routes.drop_if(is_held) }
}

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

join_held_routes : Unassigned, { held_routes : List(List(Stop)), chunking : Build.Chunking } -> Unassigned
join_held_routes = |work, { held_routes, chunking }| Build.deferred_placed(
	work,
	{ deferred: held_routes, chunking },
)

## 2-opt each route, relocate and exchange stops, 2-opt again, rebalance,
## split arcs off, exchange and rebalance again, and merge each route's
## stops of one neighborhood.
improve_routes : Unassigned -> Unassigned
improve_routes = |work| {
	tidied = { ..work, routes: work.routes.map(Route.two_opt_stops) }
	moved = Improve.exchange_stops(Improve.relocate_stops(tidied))
	retidied = { ..moved, routes: moved.routes.map(Route.two_opt_stops) }
	settled = Improve.rebalance_stops(retidied)
	split = Improve.rebalance_stops(Improve.exchange_stops(Improve.split(settled)))
	{ ..split, routes: split.routes.map(|r| Route.two_opt_stops(Route.coalesced_stops(r))) }
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
		slot_routes: repaired.slot_routes.map(Route.two_opt_stops),
		moves: [],
	})
	rebalanced = SlotSearch.arc_rebalanced({
		slot_routes: searched.slot_routes.map(Route.two_opt_stops),
		moves: [],
	})
	{
		slot_routes: SlotSearch.houses_tidied(rebalanced.slot_routes.map(Route.two_opt_stops)),
		unrouted: assigned.unrouted,
		moves: [assigned.moves, repaired.moves, searched.moves, rebalanced.moves].join(),
	}
}

## A plan's display minutes, worked out from its routes: each route's, the
## totals in route order, and the spread over the trucks deployed.
plan_of : Solve.Routes -> Solve.Plan
plan_of = |routes| {
	slot_routes = routes.slot_routes
	minutes = slot_routes.map(Pain.minutes_of)
	travel = minutes.fold(0, |n, m| n + m.travel)
	local = minutes.fold(0, |n, m| n + m.local)
	service = minutes.fold(0, |n, m| n + m.service)
	deployed = slot_routes.map_with_index(
		|r, i| { r, i },
	).keep_if(|e| !e.r.is_empty()).map(|e| (minutes.get(e.i) ?? crash "Solve.plan_of: in range").time)
	spread =
		match (deployed.max(), deployed.min()) {
			(Ok(most), Ok(least)) => most - least
			_ => 0
		}
	{
		slot_routes,
		unrouted: routes.unrouted,
		minutes,
		travel,
		local,
		service,
		time: travel.to_f64() + local + service.to_f64(),
		spread,
		start_routes: routes.start_routes,
		moves: routes.moves,
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
