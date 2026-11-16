## Local search over the built routes, before the routes are given their
## trucks: or-opt moves one stop to another route, exchange trades a stop
## between two, rebalance takes a pain-neutral move that evens the routes'
## pains, and the split pass hands an arc of a neighborhood's houses to a
## second truck. Each takes the best move a scan finds, the first of
## equals, until none is left; a gain is integer pain, so "saves any" is a
## gain of at least 1.

import Houses
import Pain
import Replay
import Route
import Seattle
import Stop

Improve :: [].{

	Searched : { routes : List(List(Stop)), moves : List(Replay.Move) }

	## Or-opt: move a free stop to the best place in another route while one
	## saves pain. The scan goes on after each move, from the next stop.
	relocated : Searched -> Searched
	relocated = |start| {
		var $routes = start.routes
		var $moves = start.moves
		var $improved = True
		while $improved {
			$improved = False
			var $r = 0
			while $r < $routes.len() {
				var $s = 0
				while $s < route_at($routes, $r).len() {
					from = route_at($routes, $r)
					stop = Route.stop_at(from, $s)
					if !stop.is_pinned() {
						without = from.drop_at($s)
						drop = Pain.pain_of(from) - Pain.pain_of(without)
						var $best = NoMove
						for t in 0..<$routes.len() {
							to = route_at($routes, t)
							if t != $r and Route.load(to) + stop.load() <= Route.cap(to) {
								base = Pain.pain_of(to)
								for at in 0..=to.len() {
									gain = drop - (Pain.pain_of(Route.insert_at(to, { at, stop })) - base)
									is_better =
										match $best {
											NoMove => True
											Move(b) => gain > b.gain
										}
									if gain >= 1 and is_better {
										$best = Move({ gain, t, at })
									}
								}
							}
						}
						match $best {
							NoMove => {}
							Move(b) => {
								with_out = $routes.set($r, without) ?? crash "Improve.relocated: in range"
								$routes = with_out.set(b.t, Route.insert_at(route_at(with_out, b.t), { at: b.at, stop })) ?? crash "Improve.relocated: in range"
								$moves = $moves.append({ kind: Relocate, saved: b.gain, detail: "moved ${Seattle.name_of(stop.nbhd)} to another truck", frame: $routes, touched: Replay.keys_of([stop]) })
								$improved = True
							}
						}
					}
					$s = $s + 1
				}
				$r = $r + 1
			}
			if $improved {
				$routes = $routes.drop_if(|r| r.is_empty())
			}
		}
		{ routes: $routes, moves: $moves }
	}

	## Exchange: trade one free stop between two routes, each into its best
	## place and merged with a stop of its neighborhood, while a trade saves
	## pain (at most 200 trades).
	exchanged : Searched -> Searched
	exchanged = |start| {
		var $routes = start.routes
		var $moves = start.moves
		var $rounds = 0
		while $rounds < 200 {
			$rounds = $rounds + 1
			pains = $routes.map(Pain.pain_of)
			var $best = NoMove
			for a in 0..<$routes.len() {
				ra = route_at($routes, a)
				for b in (a + 1)..<$routes.len() {
					rb = route_at($routes, b)
					base = pain_at(pains, a) + pain_at(pains, b)
					for i in 0..<ra.len() {
						sa = Route.stop_at(ra, i)
						for j in 0..<rb.len() {
							sb = Route.stop_at(rb, j)
							if
								!sa.is_pinned()
								and !sb.is_pinned()
								and sa.nbhd != sb.nbhd
								and Route.load(ra) - sa.load() + sb.load() <= Route.cap(ra)
								and Route.load(rb) - sb.load() + sa.load() <= Route.cap(rb)
							{
								new_a = Route.coalesce(Route.reinsert(ra, { at: i, stop: sb }))
								new_b = Route.coalesce(Route.reinsert(rb, { at: j, stop: sa }))
								gain = base - (Pain.pain_of(new_a) + Pain.pain_of(new_b))
								is_better =
									match $best {
										NoMove => True
										Move(m) => gain > m.gain
									}
								if gain >= 1 and is_better {
									$best = Move({ gain, a, b, new_a, new_b, touched: [sa, sb] })
								}
							}
						}
					}
				}
			}
			match $best {
				NoMove => {
					$rounds = 200
				}

				Move(m) => {
					$routes = ($routes.set(m.a, m.new_a) ?? crash "Improve.exchanged: in range").set(m.b, m.new_b) ?? crash "Improve.exchanged: in range"
					$moves = $moves.append({ kind: Swap, saved: m.gain, detail: "traded a stop between two trucks", frame: $routes, touched: Replay.keys_of(m.touched) })
				}
			}
		}
		{ routes: $routes, moves: $moves }
	}

	## Rebalance, the free tie-break: move a free stop where the routes' total
	## pain stays the same and their spread (the population standard
	## deviation of the routes' pains) shrinks the most, at most 400 times.
	rebalanced : Searched -> Searched
	rebalanced = |start| {
		var $routes = start.routes
		var $moves = start.moves
		var $rounds = 0
		while $rounds < 400 {
			$rounds = $rounds + 1
			pains = $routes.map(Pain.pain_of)
			alive = $routes.map(|r| !r.is_empty())
			spread0 = spread_of(pains.map_with_index(|p, i| { pain: p, is_alive: is_at(alive, i) }))
			var $best = NoMove
			for r in 0..<$routes.len() {
				from = route_at($routes, r)
				for s in 0..<from.len() {
					stop = Route.stop_at(from, s)
					if !stop.is_pinned() {
						without = from.drop_at(s)
						from_pain = Pain.pain_of(without)
						for t in 0..<$routes.len() {
							to = route_at($routes, t)
							if t != r and Route.load(to) + stop.load() <= Route.cap(to) {
								for at in 0..=to.len() {
									to_pain = Pain.pain_of(Route.insert_at(to, { at, stop }))
									total_change = from_pain - pain_at(pains, r) + (to_pain - pain_at(pains, t))
									if total_change == 0 {
										after = pains.map_with_index(
											|p, i|
												if i == r {
													{ pain: from_pain, is_alive: !without.is_empty() and is_at(alive, i) }
												} else if i == t {
													{ pain: to_pain, is_alive: is_at(alive, i) }
												} else {
													{ pain: p, is_alive: is_at(alive, i) }
												},
										)
										spread_change = spread_of(after) - spread0
										is_better =
											match $best {
												NoMove => True
												Move(m) => spread_change < m.spread_change
											}
										if spread_change < -0.000001 and is_better {
											$best = Move({ spread_change, r, s, t, at })
										}
									}
								}
							}
						}
					}
				}
			}
			match $best {
				NoMove => {
					$rounds = 400
				}

				Move(m) => {
					from = route_at($routes, m.r)
					stop = Route.stop_at(from, m.s)
					with_out = $routes.set(m.r, from.drop_at(m.s)) ?? crash "Improve.rebalanced: in range"
					$routes = with_out.set(m.t, Route.insert_at(route_at(with_out, m.t), { at: m.at, stop })) ?? crash "Improve.rebalanced: in range"
					$moves = $moves.append({ kind: Settle, saved: 0, detail: "tie-break: ${Seattle.name_of(stop.nbhd)} → another truck", frame: $routes, touched: Replay.keys_of([stop]) })
					$routes = $routes.drop_if(|route| route.is_empty())
				}
			}
		}
		{ routes: $routes, moves: $moves }
	}

	## The split pass: hand a contiguous arc of one to three of a free
	## stop's houses to a route that doesn't serve its neighborhood, at the
	## arc's best place there, while a split saves pain (at most 60 splits).
	split : Searched -> Searched
	split = |start| {
		var $routes = start.routes
		var $moves = start.moves
		var $rounds = 0
		while $rounds < 60 {
			$rounds = $rounds + 1
			pains = $routes.map(Pain.pain_of)
			var $best = NoMove
			for a in 0..<$routes.len() {
				ra = route_at($routes, a)
				for sa in 0..<ra.len() {
					stop = Route.stop_at(ra, sa)
					if !stop.is_pinned() and stop.load() >= 2 {
						arcs = arc_subsets(stop.nbhd, stop.houses)
						for b in 0..<$routes.len() {
							rb = route_at($routes, b)
							if b != a and !rb.any(|s| s.nbhd == stop.nbhd) {
								for arc in arcs {
									if Route.load(rb) + arc.count() <= Route.cap(rb) {
										rest = Route.free_stop(stop.nbhd, stop.houses.without(arc))
										pain_a = Pain.pain_of(ra.set(sa, rest) ?? crash "Improve.split: in range")
										take = Route.free_stop(stop.nbhd, arc)
										var $at_b = 0
										var $pain_b = Pain.pain_of(rb.prepend(take))
										for at in 1..=rb.len() {
											c = Pain.pain_of(Route.insert_at(rb, { at, stop: take }))
											if c < $pain_b {
												$pain_b = c
												$at_b = at
											}
										}
										change = pain_a - pain_at(pains, a) + ($pain_b - pain_at(pains, b))
										is_better =
											match $best {
												NoMove => True
												Move(m) => change < m.change
											}
										if change <= -1 and is_better {
											$best = Move({ change, a, sa, b, at: $at_b, take, rest })
										}
									}
								}
							}
						}
					}
				}
			}
			match $best {
				NoMove => {
					$rounds = 60
				}

				Move(m) => {
					with_rest = $routes.set(m.a, route_at($routes, m.a).set(m.sa, m.rest) ?? crash "Improve.split: in range") ?? crash "Improve.split: in range"
					$routes = with_rest.set(m.b, Route.insert_at(route_at(with_rest, m.b), { at: m.at, stop: m.take })) ?? crash "Improve.split: in range"
					name = Seattle.name_of(m.take.nbhd)
					both = m.take.load() + m.rest.load()
					$moves = $moves.append(
						{
							kind: Settle,
							saved: -m.change,
							detail: "split ${name}: ${m.take.load().to_str()} of ${both.to_str()} totes to another truck",
							frame: $routes,
							touched: Replay.keys_for(m.take.nbhd, m.take.houses),
						},
					)
				}
			}
		}
		{ routes: $routes, moves: $moves }
	}
}

route_at : List(List(Stop)), U64 -> List(Stop)
route_at = |routes, i| routes.get(i) ?? crash "Improve.route_at: a route of the plan"

pain_at : List(I64), U64 -> I64
pain_at = |pains, i| pains.get(i) ?? crash "Improve.pain_at: a route's pain"

is_at : List(Bool), U64 -> Bool
is_at = |flags, i| flags.get(i) ?? crash "Improve.is_at: a route's flag"

## The population standard deviation of the live routes' pains, summed in
## route order as solver.ts reduces them.
spread_of : List({ pain : I64, is_alive : Bool }) -> F64
spread_of = |routes| {
	times = routes.keep_if(|r| r.is_alive).map(|r| r.pain.to_f64())
	if times.is_empty() {
		0
	} else {
		n = times.len().to_f64()
		mean = times.fold(0, |s, t| s + t) / n
		(times.fold(0, |s, t| s + (t - mean) * (t - mean)) / n).sqrt()
	}
}

## Every contiguous arc of one to three of the houses, by ring angle round
## the ring, each set once, the singles first.
arc_subsets : U8, Houses -> List(Houses)
arc_subsets = |nbhd, houses| {
	n = houses.count()
	if n < 2 {
		[]
	} else {
		list = houses.to_list()
		angles = Seattle.house_angles(nbhd, list)
		ordered = stable_by_angle(list.map_with_index(|h, i| { house: h, angle: angles.get(i) ?? crash "Improve.arc_subsets: an angle a house" }))
		most = if n - 1 < 3 { n - 1 } else { 3 }
		var $out = []
		for k in 1..=most {
			for first in 0..<n {
				var $arc = Houses.empty
				for j in 0..<k {
					$arc = $arc.append(ordered.get((first + j) % n) ?? crash "Improve.arc_subsets: in range")
				}
				sorted = $arc.to_list().sort_with(|p, q| if p < q { Before } else if p > q { After } else { Same })
				is_new = !$out.any(|seen| seen.count() == k and seen.to_list().sort_with(|p, q| if p < q { Before } else if p > q { After } else { Same }) == sorted)
				if is_new {
					$out = $out.append($arc)
				}
			}
		}
		$out
	}
}

## Houses by angle, the earlier of equals first (an insertion sort's order).
stable_by_angle : List({ house : U8, angle : F64 }) -> List(U8)
stable_by_angle = |items|
	items
		.map_with_index(|e, i| { house: e.house, angle: e.angle, i })
		.sort_with(
			|p, q|
				if p.angle < q.angle {
					Before
				} else if p.angle > q.angle {
					After
				} else if p.i < q.i {
					Before
				} else {
					After
				},
		)
		.map(|e| e.house)
