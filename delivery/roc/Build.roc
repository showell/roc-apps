## Construction: the day's orders become clusters, one free cluster per
## neighborhood and a pinned seed for each anchor, and greedy Clarke-Wright
## merges join them into routes while a merge saves pain. When merges alone
## can't bring the routes down to the fleet, the routes merge regardless,
## then the leftovers are packed onto the trucks with room. Last, the
## overflow neighborhoods (Bellevue, and Medina in half the race) fill the
## trucks' room where they cost least.

import Houses
import Orders
import Pain
import Replay
import Route
import Seattle
import Stop

Build :: [].{

	## How a piece too big for any one truck is split: onto the truck with
	## the most room, or onto the one where it costs least.
	Chunking : [Roomiest, Cheapest]

	Built : { routes : List(List(Stop)), moves : List(Replay.Move) }

	## The day's orders as clusters, in the order the day drew them: an
	## anchor's first two houses pinned to its truck, its other houses free,
	## and every other neighborhood one free cluster (chunked at the largest
	## cap, which no neighborhood's orders reach).
	clusters_of : List(Orders.NeighborhoodOrders) -> List(List(Stop))
	clusters_of = |orders| {
		var $out = []
		for o in orders {
			$out = match Seattle.anchor_slot(o.nbhd) {
				NoAnchor => free_clusters_onto($out, { nbhd: o.nbhd, houses: o.houses })
				Anchors(slot) => {
					seeded = $out.append([
						{
							nbhd: o.nbhd,
							houses: o.houses.take_first(anchor_seed),
							pin: Pinned(slot),
						},
					])
					free_clusters_onto(
						seeded,
						{ nbhd: o.nbhd, houses: o.houses.drop_first(anchor_seed) },
					)
				}
			}
		}
		$out
	}

	## Greedy Clarke-Wright: apply the merge that saves the most, while one
	## saves any (`Saving`), or until the routes are down to the fleet
	## (`ToFleet`). A merge's snapshot is the routes before it.
	merge_routes : Built, [Saving, ToFleet] -> Built
	merge_routes = |built, until| {
		var $routes = built.routes
		var $moves = built.moves
		var $going = True
		while $going {
			pains = $routes.map(Pain.pain_of)
			var $best = NoMerge
			for i in 0..<$routes.len() {
				ri = route_stops_at($routes, i)
				for j in (i + 1)..<$routes.len() {
					rj = route_stops_at($routes, j)
					cap = if Route.has_anchor(ri) {
						Route.cap(ri)
					} else {
						Route.cap(rj)
					}
					fits = Route.load(ri) + Route.load(rj) <= cap
					if fits and !(Route.has_anchor(ri) and Route.has_anchor(rj)) {
						joined = best_joined_stops(ri, rj)
						saved = pain_at(pains, i) + pain_at(pains, j) - Pain.pain_of(joined)
						is_better =
							match $best {
								NoMerge => True
								Merge(b) => saved > b.saved
							}
						if is_better {
							$best = Merge({ saved, i, j, joined })
						}
					}
				}
			}
			match $best {
				NoMerge => {
					$going = False
				}

				Merge(b) => {
					is_done =
						match until {
							Saving => b.saved <= 0
							ToFleet => $routes.len() <= Seattle.truck_count
						}
					if is_done {
						$going = False
					} else {
						names = Str.join_with(b.joined.map(|s| Seattle.name_of(s.nbhd)), " · ")
						$moves = $moves.append({
							kind: Merge,
							saved: b.saved,
							detail: names,
							frame_routes: $routes,
							touched: Replay.stop_keys(b.joined),
						})
						$routes = (
							$routes.set(
								b.i,
								b.joined,
							) ?? crash "Build.merge_routes: in range"
						).drop_at(b.j)
					}
				}
			}
		}
		{ routes: $routes, moves: $moves }
	}

	## The last resort when merging can't reach the fleet: keep the anchored
	## routes and the biggest free ones, a truck each, and pack every stop of
	## the rest onto the kept trucks with room, whole where one truck can take
	## it, else a chunk at a time.
	##
	## solver.ts's kept routes are the same objects as its routes' entries,
	## so a snapshot here is the routes as they came in, each kept one as it
	## is now.
	force_placed : Built, Chunking -> Built
	force_placed = |built, chunking| {
		routes = built.routes
		indexed = routes.map_with_index(|r, i| { route_stops: r, at: i })
		anchored = indexed.keep_if(|e| Route.has_anchor(e.route_stops))
		clusters = items_by_load_desc(
			indexed.keep_if(|e| !Route.has_anchor(e.route_stops) and !e.route_stops.is_empty()),
			|e| Route.load(e.route_stops),
		)
		keep = if anchored.len() < Seattle.truck_count {
			Seattle.truck_count - anchored.len()
		} else {
			0
		}
		var $kept_routes = anchored.concat(clusters.take_first(keep))
		surplus = clusters.drop_first(keep)
		var $moves = built.moves
		for extra in surplus {
			for stop in extra.route_stops {
				var $remaining = stop.houses
				while !$remaining.is_empty() {
					n = $remaining.count()
					var $whole = NoTruck
					for k in 0..<$kept_routes.len() {
						kept = $kept_routes.get(k) ?? crash "Build.force_placed: a kept route"
						ks = kept.route_stops
						if room_of(ks) >= n.to_i64_wrap() {
							c = appending_pain(ks, { nbhd: stop.nbhd, houses: $remaining })
							is_better =
								match $whole {
									NoTruck => True
									Truck(b) => c < b.pain
								}
							if is_better {
								$whole = Truck({ k, pain: c })
							}
						}
					}
					match $whole {
						Truck(b) => {
							$kept_routes = kept_routes_with_stop(
								$kept_routes,
								{ k: b.k, stop: Route.free_stop(stop.nbhd, $remaining) },
							)
							$moves = $moves.append({
								kind: Relocate,
								saved: 0,
								detail: "capacity placement: ${Seattle.name_of(stop.nbhd)} (${n.to_str()}) onto a truck with room",
								frame_routes: aliased_frame_routes(routes, $kept_routes),
								touched: Replay.house_keys(stop.nbhd, $remaining),
							})
							$remaining = Houses.empty
						}

						NoTruck => {
							into = chunk_target(
								$kept_routes.map(|e| e.route_stops),
								{
									nbhd: stop.nbhd,
									houses: $remaining,
									chunking,
									place: Appended,
								},
							)
							take = $remaining.take_first(into.take)
							$remaining = $remaining.drop_first(into.take)
							$kept_routes = kept_routes_with_stop(
								$kept_routes,
								{ k: into.k, stop: Route.free_stop(stop.nbhd, take) },
							)
							$moves = $moves.append({
								kind: Relocate,
								saved: 0,
								detail: "capacity split: ${Seattle.name_of(stop.nbhd)} ${into.take.to_str()} tote(s) onto a truck with room",
								frame_routes: aliased_frame_routes(routes, $kept_routes),
								touched: Replay.house_keys(stop.nbhd, take),
							})
						}
					}
				}
			}
		}
		{ routes: $kept_routes.map(|e| e.route_stops), moves: $moves }
	}

	## The overflow neighborhoods into the trucks' room, the biggest first:
	## each whole into the route where it costs least, else a chunk at a time.
	## The captions keep solver.ts's words ("deferred fill"), which the gold
	## pins.
	overflow_placed : Built, { overflow_routes : List(List(Stop)), chunking : Chunking } -> Built
	overflow_placed = |built, { overflow_routes, chunking }| {
		ordered = items_by_load_desc(overflow_routes.map(|r| Route.stop_at(r, 0)), Stop.load)
		var $routes = built.routes
		var $moves = built.moves
		for stop in ordered {
			var $remaining = stop.houses
			while !$remaining.is_empty() {
				n = $remaining.count()
				var $whole = NoTruck
				for ri in 0..<$routes.len() {
					rs = route_stops_at($routes, ri)
					if room_of(rs) >= n.to_i64_wrap() {
						candidate = Route.insert_best(rs, Route.free_stop(stop.nbhd, $remaining))
						delta = Pain.pain_of(candidate) - Pain.pain_of(rs)
						is_better =
							match $whole {
								NoTruck => True
								Truck(b) => delta < b.delta
							}
						if is_better {
							$whole = Truck({ ri, delta, route_stops: candidate })
						}
					}
				}
				match $whole {
					Truck(b) => {
						$routes = $routes.set(
							b.ri,
							b.route_stops,
						) ?? crash "Build.overflow_placed: in range"
						$moves = $moves.append({
							kind: Relocate,
							saved: 0,
							detail: "deferred fill: ${Seattle.name_of(stop.nbhd)} (${n.to_str()}) into slack",
							frame_routes: $routes,
							touched: Replay.house_keys(stop.nbhd, $remaining),
						})
						$remaining = Houses.empty
					}

					NoTruck => {
						into = chunk_target(
							$routes,
							{
								nbhd: stop.nbhd,
								houses: $remaining,
								chunking,
								place: Inserted,
							},
						)
						take = $remaining.take_first(into.take)
						$remaining = $remaining.drop_first(into.take)
						placed = Route.insert_best(
							route_stops_at($routes, into.k),
							Route.free_stop(stop.nbhd, take),
						)
						$routes = $routes.set(
							into.k,
							placed,
						) ?? crash "Build.overflow_placed: in range"
						$moves = $moves.append({
							kind: Relocate,
							saved: 0,
							detail: "deferred split: ${Seattle.name_of(stop.nbhd)} ${into.take.to_str()} tote(s) into slack",
							frame_routes: $routes,
							touched: Replay.house_keys(stop.nbhd, take),
						})
					}
				}
			}
		}
		{ routes: $routes, moves: $moves }
	}

	## A list stably sorted by a load, the biggest first (JS's sort is
	## stable).
	items_by_load_desc : List(a), (a -> U64) -> List(a)
	items_by_load_desc = |items, load_of| {
		indexed = items.map_with_index(|item, i| { item, i, load: load_of(item) })
		sorted = indexed.sort_with(
			|p, q|
				if p.load > q.load {
					Before
				} else if p.load < q.load {
					After
				} else if p.i < q.i {
					Before
				} else if p.i > q.i {
					After
				} else {
					Same
				},
		)
		sorted.map(|e| e.item)
	}
}

anchor_seed : U64
anchor_seed = 2

free_clusters_onto : List(List(Stop)), { nbhd : U8, houses : Houses } -> List(List(Stop))
free_clusters_onto = |out, { nbhd, houses }| {
	var $out = out
	var $rest = houses
	while !$rest.is_empty() {
		$out = $out.append([Route.free_stop(nbhd, $rest.take_first(Seattle.max_cap))])
		$rest = $rest.drop_first(Seattle.max_cap)
	}
	$out
}

## The totes a route has room for (negative when it is over its cap).
room_of : List(Stop) -> I64
room_of = |stops| Route.cap(stops).to_i64_wrap() - Route.load(stops).to_i64_wrap()

route_stops_at : List(List(Stop)), U64 -> List(Stop)
route_stops_at = |routes, i| routes.get(i) ?? crash "Build.route_stops_at: a route of the plan"

pain_at : List(I64), U64 -> I64
pain_at = |pains, i| pains.get(i) ?? crash "Build.pain_at: a route's pain"

## `a` and `b` laid end to end the cheapest of four ways, ties to the first:
## a then b, a then b reversed, a reversed then b, both reversed.
best_joined_stops : List(Stop), List(Stop) -> List(Stop)
best_joined_stops = |a, b| {
	# Each way read in place: a then b reversed is the run after a reversed,
	# a reversed then b the run before it, and both reversed is b then a,
	# reversed whole.
	ab = a.concat(b)
	ba = b.concat(a)
	n = ab.len()
	cut = a.len()
	ways = [
		{ stops: ab, view: Whole },
		{
			stops: ab,
			view: if cut < n {
				Reversed({ first: cut, last: n - 1 })
			} else {
				Whole
			},
		},
		{
			stops: ab,
			view: if cut > 0 {
				Reversed({ first: 0, last: cut - 1 })
			} else {
				Whole
			},
		},
		{
			stops: ba,
			view: if n > 0 {
				Reversed({ first: 0, last: n - 1 })
			} else {
				Whole
			},
		},
	]
	var $best = 0
	var $best_pain = Pain.pain_of(ab)
	for w in 1..<4 {
		way = ways.get(w) ?? crash "Build.best_joined_stops: four ways"
		pain = Pain.pain_of_view(way.stops, way.view)
		if pain < $best_pain {
			$best_pain = pain
			$best = w
		}
	}
	match $best {
		0 => ab
		1 => a.concat(b.rev())
		2 => a.rev().concat(b)
		_ => ba.rev()
	}
}

## How much appending a stop of these houses adds to a route's pain.
appending_pain : List(Stop), { nbhd : U8, houses : Houses } -> I64
appending_pain = |
	stops,
	{ nbhd, houses },
| Pain.pain_of(stops.append(Route.free_stop(nbhd, houses))) - Pain.pain_of(stops)

## A kept route of force placement, and its place in the routes it came from.
Kept : { route_stops : List(Stop), at : U64 }

kept_routes_with_stop : List(Kept), { k : U64, stop : Stop } -> List(Kept)
kept_routes_with_stop = |kept_routes, { k, stop }| {
	{ list, prev } = kept_routes.replace(
		k,
		{ route_stops: [], at: 0 },
	) ?? crash "Build.kept_routes_with_stop: a kept route"
	list.set(
		k,
		{ route_stops: prev.route_stops.append(stop), at: prev.at },
	) ?? crash "Build.kept_routes_with_stop: a kept route"
}

## The routes as solver.ts's snapshot sees them mid-placement: as they came
## in, with each kept route as it is now, in its old place.
aliased_frame_routes : List(List(Stop)), List(Kept) -> List(List(Stop))
aliased_frame_routes = |routes, kept_routes| kept_routes.fold(
	routes,
	|frame, k| frame.set(k.at, k.route_stops) ?? crash "Build.aliased_frame_routes: in range",
)

## Where a piece of `houses` too big for one truck goes, and how much of
## it: the truck with the most room (the first of equals), or the truck
## where the most of it that fits costs least. `place` says how a piece
## goes on: appended (force placement) or at its best place (the overflow neighborhoods).
chunk_target : List(List(Stop)),
{
	nbhd : U8,
	houses : Houses,
	chunking : Build.Chunking,
	place : [Appended, Inserted],
} -> { k : U64, take : U64 }
chunk_target = |routes, { nbhd, houses, chunking, place }| {
	n = houses.count()
	var $best = NoTruck
	for k in 0..<routes.len() {
		ks = route_stops_at(routes, k)
		room = room_of(ks)
		if room > 0 {
			take = if room.to_u64_wrap() < n {
				room.to_u64_wrap()
			} else {
				n
			}
			match chunking {
				Roomiest => {
					is_better =
						match $best {
							NoTruck => True
							Truck(b) => room > b.score
						}
					if is_better {
						$best = Truck({ k, take, score: room })
					}
				}

				Cheapest => {
					piece = Route.free_stop(nbhd, houses.take_first(take))
					cost =
						match place {
							Appended => appending_pain(ks, { nbhd, houses: piece.houses })
							Inserted => Pain.pain_of(
								Route.insert_best(ks, piece),
							) - Pain.pain_of(ks)
						}
					is_better =
						match $best {
							NoTruck => True
							Truck(b) => cost < b.score
						}
					if is_better {
						$best = Truck({ k, take, score: cost })
					}
				}
			}
		}
	}
	match $best {
		Truck(b) => { k: b.k, take: b.take }
		NoTruck => crash "Build.chunk_target: no truck has room"
	}
}
