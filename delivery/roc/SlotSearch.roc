## Local search once every route has its truck, held to each truck's own
## cap: corridor repair hands a neighborhood a truck merely drives through
## to that truck, a relocate or swap between trucks, the arc-rebalance that
## rescues an over-cap move by shifting one ring arc back, and last the one
## float-scored pass, which trades houses between trucks that split a
## neighborhood so each walks less of the ring. Each move is judged by
## pain after 2-opt (`Route.tidied_pain`), as the pipeline will leave it.

import Houses
import Pain
import Replay
import RoadGraph
import Route
import Seattle
import Stop

SlotSearch :: [].{

	## The eight trucks' routes, by slot, and the moves made so far.
	Slotted : { slot_routes : List(List(Stop)), moves : List(Replay.Move) }

	## How far corridor repair may split a neighborhood: only as many houses
	## as it trades back (`CapacityNeutral`, the conservative half of its
	## race), or any number the caps allow.
	Splitting : [CapacityNeutral, AnyShift]

	## Corridor repair: a neighborhood that truck `t` threads through but
	## another truck delivers, taken onto `t`: absorbed whole if it has room,
	## traded for one of `t`'s stops, or a slice of it carved off in trade
	## (at most 50 repairs).
	corridor_repaired : Slotted, Splitting -> Slotted
	corridor_repaired = |start, splitting| {
		var $slots = start.slot_routes
		var $moves = start.moves
		var $rounds = 0
		while $rounds < 50 {
			$rounds = $rounds + 1
			tidied = $slots.map(Route.tidied_pain)
			var $best = NoMove
			for t in 0..<$slots.len() {
				rt = slot_stops_at($slots, t)
				if !rt.is_empty() {
					delivered = rt.map(|s| s.nbhd)
					threaded = Pain.path_nodes(rt).fold(
						[],
						|seen, node| {
							is_new = !delivered.contains(node) and !seen.contains(node)
							if node != Seattle.fc and is_new {
								seen.append(node)
							} else {
								seen
							}
						},
					)
					for b in threaded {
						$best = corridor_repair_onto(
							$best,
							{
								slots: $slots,
								tidied,
								t,
								b,
								splitting,
							},
						)
					}
				}
			}
			match $best {
				NoMove => {
					$rounds = 50
				}

				Move(m) => {
					$slots = (
						$slots.set(
							m.t,
							m.t_stops,
						) ?? crash "SlotSearch.corridor_repaired: in range"
					).set(m.tp, m.tp_stops) ?? crash "SlotSearch.corridor_repaired: in range"
					$moves = $moves.append({
						kind: Consolidate,
						saved: m.gain,
						detail: "consolidated ${m.name} onto the truck passing through (${m.via})",
						frame_routes: $slots,
						touched: m.touched,
					})
				}
			}
		}
		{ slot_routes: $slots, moves: $moves }
	}

	## A free stop relocated to another truck, or two traded, while a move
	## saves tidied pain within the trucks' own caps (at most 200 moves).
	relocated_or_swapped : Slotted -> Slotted
	relocated_or_swapped = |start| {
		var $slots = start.slot_routes
		var $moves = start.moves
		var $rounds = 0
		while $rounds < 200 {
			$rounds = $rounds + 1
			tidied_pains = $slots.map(Route.tidied_pain)
			var $best = NoMove
			for a in 0..<$slots.len() {
				a_stops = slot_stops_at($slots, a)
				for si in 0..<a_stops.len() {
					stop = Route.stop_at(a_stops, si)
					if !stop.is_pinned() {
						for b in 0..<$slots.len() {
							b_stops = slot_stops_at($slots, b)
							fits = Route.load(b_stops) + stop.load() <= Seattle.cap_of_slot(b)
							if b != a and fits {
								new_a = a_stops.drop_at(si)
								new_b = Route.stops_with_cheapest_insert(b_stops, stop)
								pair = tidied_at(tidied_pains, a) + tidied_at(tidied_pains, b)
								gain = pair - (Route.tidied_pain(new_a) + Route.tidied_pain(new_b))
								if gain >= 1 and beats($best, gain) {
									$best = Move({
										gain,
										a,
										b,
										new_a,
										new_b,
										change: Moved,
										touched: Replay.stop_keys([stop]),
									})
								}
							}
						}
					}
				}
			}
			for a in 0..<$slots.len() {
				a_stops = slot_stops_at($slots, a)
				for b in (a + 1)..<$slots.len() {
					b_stops = slot_stops_at($slots, b)
					load_a = Route.load(a_stops)
					load_b = Route.load(b_stops)
					for i in 0..<a_stops.len() {
						sa = Route.stop_at(a_stops, i)
						for j in 0..<b_stops.len() {
							sb = Route.stop_at(b_stops, j)
							fits_a = load_a - sa.load() + sb.load() <= Seattle.cap_of_slot(a)
							fits_b = load_b - sb.load() + sa.load() <= Seattle.cap_of_slot(b)
							is_free = !sa.is_pinned() and !sb.is_pinned()
							if is_free and sa.nbhd != sb.nbhd and fits_a and fits_b {
								new_a = Route.coalesced_stops(
									Route.reinserted_stops(a_stops, { at: i, stop: sb }),
								)
								new_b = Route.coalesced_stops(
									Route.reinserted_stops(b_stops, { at: j, stop: sa }),
								)
								pair = tidied_at(tidied_pains, a) + tidied_at(tidied_pains, b)
								after = Route.tidied_pain(new_a) + Route.tidied_pain(new_b)
								gain = pair - after
								if gain >= 1 and beats($best, gain) {
									$best = Move({
										gain,
										a,
										b,
										new_a,
										new_b,
										change: Traded,
										touched: Replay.stop_keys([sa, sb]),
									})
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
					$slots = (
						$slots.set(
							m.a,
							m.new_a,
						) ?? crash "SlotSearch.relocated_or_swapped: in range"
					).set(m.b, m.new_b) ?? crash "SlotSearch.relocated_or_swapped: in range"
					move =
						match m.change {
							Traded => {
								kind: Swap,
								detail: "traded a stop between trucks ${(m.a + 1).to_str()} and ${(m.b + 1).to_str()}",
							}
							Moved => {
								kind: Relocate,
								detail: "relocated a stop to truck ${(m.b + 1).to_str()}",
							}
						}
					$moves = $moves.append({
						kind: move.kind,
						saved: m.gain,
						detail: move.detail,
						frame_routes: $slots,
						touched: m.touched,
					})
				}
			}
		}
		{ slot_routes: $slots, moves: $moves }
	}

	## Arc-rebalance: a relocate or a swap that leaves one truck over its
	## cap, rescued by shifting one ring arc of a free stop from the
	## overfull truck to the other (at most 200 moves).
	arc_rebalanced : Slotted -> Slotted
	arc_rebalanced = |start| {
		var $slots = start.slot_routes
		var $moves = start.moves
		var $rounds = 0
		while $rounds < 200 {
			$rounds = $rounds + 1
			tidied_pains = $slots.map(Route.tidied_pain)
			var $best = NoMove
			for a in 0..<$slots.len() {
				a_stops = slot_stops_at($slots, a)
				for si in 0..<a_stops.len() {
					stop = Route.stop_at(a_stops, si)
					if !stop.is_pinned() {
						for b in 0..<$slots.len() {
							if b != a {
								$best = rescue_move(
									$best,
									{
										tidied_pains,
										a,
										b,
										a_stops: a_stops.drop_at(si),
										b_stops: Route.stops_with_cheapest_insert(
											slot_stops_at($slots, b),
											stop,
										),
										touched: Replay.stop_keys([stop]),
									},
								)
							}
						}
					}
				}
			}
			for a in 0..<$slots.len() {
				a_stops = slot_stops_at($slots, a)
				for b in (a + 1)..<$slots.len() {
					b_stops = slot_stops_at($slots, b)
					for i in 0..<a_stops.len() {
						sa = Route.stop_at(a_stops, i)
						for j in 0..<b_stops.len() {
							sb = Route.stop_at(b_stops, j)
							if !sa.is_pinned() and !sb.is_pinned() and sa.nbhd != sb.nbhd {
								$best = rescue_move(
									$best,
									{
										tidied_pains,
										a,
										b,
										a_stops: Route.coalesced_stops(
											Route.reinserted_stops(a_stops, { at: i, stop: sb }),
										),
										b_stops: Route.coalesced_stops(
											Route.reinserted_stops(b_stops, { at: j, stop: sa }),
										),
										touched: Replay.stop_keys([sa, sb]),
									},
								)
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
					$slots = (
						$slots.set(
							m.a,
							m.a_stops,
						) ?? crash "SlotSearch.arc_rebalanced: in range"
					).set(m.b, m.b_stops) ?? crash "SlotSearch.arc_rebalanced: in range"
					$moves = $moves.append({
						kind: Relocate,
						saved: m.gain,
						detail: "arc-rebalance between trucks ${(m.a + 1).to_str()} and ${(m.b + 1).to_str()}",
						frame_routes: $slots,
						touched: m.touched,
					})
				}
			}
		}
		{ slot_routes: $slots, moves: $moves }
	}

	## Where two or more trucks split a neighborhood, trade houses between
	## them, one pair at a time, while a trade shortens their ring walks
	## (float minutes, by more than 1e-6). Pain can't see which house a truck
	## takes, so this tidy is pain-neutral.
	houses_tidied : List(List(Stop)) -> List(List(Stop))
	houses_tidied = |slot_routes| {
		var $order = []
		for route in slot_routes {
			for s in route {
				if !s.houses.is_empty() and !$order.contains(s.nbhd) {
					$order = $order.append(s.nbhd)
				}
			}
		}
		$order.fold(slot_routes, houses_tidied_in)
	}
}

## The best move so far, or none.
beats : [NoMove, Move({ gain : I64, .. })], I64 -> Bool
beats = |best, gain|
	match best {
		NoMove => True
		Move(m) => gain > m.gain
	}

larger : I64, I64 -> I64
larger = |a, b|
	if a > b {
		a
	} else {
		b
	}

smaller : I64, I64 -> I64
smaller = |a, b|
	if a < b {
		a
	} else {
		b
	}

slot_stops_at : List(List(Stop)), U64 -> List(Stop)
slot_stops_at = |slots, i| slots.get(i) ?? crash "SlotSearch.slot_stops_at: one of the eight slots"

tidied_at : List(I64), U64 -> I64
tidied_at = |pains, i| pains.get(i) ?? crash "SlotSearch.tidied_at: a slot's pain"

## The route without its one stop in `nbhd` (a coalesced route has one).
without_nbhd : List(Stop), U8 -> List(Stop)
without_nbhd = |stops, nbhd| {
	kept = stops.drop_if(|s| s.nbhd == nbhd)
	if kept.len() + 1 != stops.len() {
		crash "SlotSearch.without_nbhd: a route has exactly one stop in a neighborhood"
	}
	kept
}

## The best corridor repair so far, or none: the two trucks' new routes,
## and the caption's words.
CorridorMove : [
	NoMove,
	Move(
		{
			gain : I64,
			t : U64,
			tp : U64,
			t_stops : List(Stop),
			tp_stops : List(Stop),
			name : Str,
			via : Str,
			touched : List(Replay.HouseKey),
		},
	),
]

## The best arc-rebalance move so far, or none.
ArcMove : [
	NoMove,
	Move(
		{
			gain : I64,
			a : U64,
			b : U64,
			a_stops : List(Stop),
			b_stops : List(Stop),
			touched : List(Replay.HouseKey),
		},
	),
]

## The candidate arc-rebalance move `a_stops`/`b_stops` for trucks `a` and
## `b`, scored as it is when both fit, or rescued by an arc when one truck
## is over its cap and the other isn't; the better of it and `best`.
Candidate : {
	tidied_pains : List(I64),
	a : U64,
	b : U64,
	a_stops : List(Stop),
	b_stops : List(Stop),
	touched : List(Replay.HouseKey),
}

rescue_move : ArcMove, Candidate -> ArcMove
rescue_move = |best, c| {
	cap_a = Seattle.cap_of_slot(c.a)
	cap_b = Seattle.cap_of_slot(c.b)
	la = Route.load(c.a_stops)
	lb = Route.load(c.b_stops)
	if la <= cap_a and lb <= cap_b {
		score_move(best, c)
	} else {
		is_over_a = la > cap_a and lb <= cap_b
		is_over_b = lb > cap_b and la <= cap_a
		if !is_over_a and !is_over_b {
			best
		} else {
			over = if is_over_a {
				c.a_stops
			} else {
				c.b_stops
			}
			under = if is_over_a {
				c.b_stops
			} else {
				c.a_stops
			}
			cap_under = if is_over_a {
				cap_b
			} else {
				cap_a
			}
			need = Route.load(over) - (
				if is_over_a {
					cap_a
				} else {
					cap_b
				}
			)
			var $best = best
			for fi in 0..<over.len() {
				f = Route.stop_at(over, fi)
				if !f.is_pinned() {
					for arc_list in Seattle.arc_groups(f.nbhd, f.houses.to_list()) {
						arc = Houses.from_list(arc_list)
						fits = Route.load(under) + arc.count() <= cap_under
						if arc.count() >= need and arc.count() < f.load() and fits {
							keep = f.houses.without(arc)
							raw = over.map_with_index(
								|s, i| {
									stop: if i == fi {
										{
											nbhd: s.nbhd,
											houses: keep,
											pin: s.pin,
										}
									} else {
										s
									},
									i,
								},
							).keep_if(
								|e|
									if e.i == fi {
										!keep.is_empty()
									} else {
										!e.stop.houses.is_empty()
									},
							).map(|e| e.stop)
							new_over = Route.coalesced_stops(raw)
							new_under = Route.stops_with_cheapest_insert(
								under,
								Route.free_stop(f.nbhd, arc),
							)
							touched = c.touched.concat(Replay.house_keys(f.nbhd, arc))
							$best =
								if is_over_a {
									score_move(
										$best,
										{
											..c,
											a_stops: new_over,
											b_stops: new_under,
											touched,
										},
									)
								} else {
									score_move(
										$best,
										{
											..c,
											a_stops: new_under,
											b_stops: new_over,
											touched,
										},
									)
								}
						}
					}
				}
			}
			$best
		}
	}
}

score_move : ArcMove, Candidate -> ArcMove
score_move = |best, c| {
	is_over_a = Route.load(c.a_stops) > Seattle.cap_of_slot(c.a)
	if is_over_a or Route.load(c.b_stops) > Seattle.cap_of_slot(c.b) {
		best
	} else {
		pair = tidied_at(c.tidied_pains, c.a) + tidied_at(c.tidied_pains, c.b)
		gain = pair - (Route.tidied_pain(c.a_stops) + Route.tidied_pain(c.b_stops))
		if gain >= 1 and beats(best, gain) {
			Move({
				gain,
				a: c.a,
				b: c.b,
				a_stops: c.a_stops,
				b_stops: c.b_stops,
				touched: c.touched,
			})
		} else {
			best
		}
	}
}

## One truck's part of a split neighborhood: its slot, where its stop
## there sits, the gates it enters and leaves by, and its houses there.
Part : {
	slot : U64,
	at : U64,
	entry_angle : F64,
	exit_angle : F64,
	houses : Houses,
}

houses_tidied_in : List(List(Stop)), U8 -> List(List(Stop))
houses_tidied_in = |slot_routes, nbhd| {
	serving = List.from_iter(
		U64.until(0, slot_routes.len()),
	).keep_if(|i| slot_stops_at(slot_routes, i).any(|s| s.nbhd == nbhd and !s.houses.is_empty()))
	if serving.len() < 2 {
		slot_routes
	} else {
		start_parts = serving.keep_oks(|slot| slot_part(slot_routes, { slot, nbhd }))
		if start_parts.len() < 2 {
			slot_routes
		} else {
			var $parts = start_parts
			var $going = True
			while $going {
				var $best = NoTrade
				for x in 0..<$parts.len() {
					p = part_at($parts, x)
					for y in (x + 1)..<$parts.len() {
						q = part_at($parts, y)
						base = part_minutes(
							p,
							{ nbhd, houses: p.houses },
						) + part_minutes(q, { nbhd, houses: q.houses })
						for ai in 0..<p.houses.count() {
							for bi in 0..<q.houses.count() {
								ha = p.houses.house_at(ai)
								hb = q.houses.house_at(bi)
								gain = base - (
									part_minutes(
										p,
										{
											nbhd,
											houses: p.houses.with_house_at({ at: ai, house: hb }),
										},
									) + part_minutes(
										q,
										{
											nbhd,
											houses: q.houses.with_house_at({ at: bi, house: ha }),
										},
									)
								)
								is_better =
									match $best {
										NoTrade => True
										Trade(t) => gain > t.gain
									}
								if gain > 0.000001 and is_better {
									$best = Trade({ gain, x, y, ai, bi })
								}
							}
						}
					}
				}
				match $best {
					NoTrade => {
						$going = False
					}

					Trade(t) => {
						p = part_at($parts, t.x)
						q = part_at($parts, t.y)
						ha = p.houses.house_at(t.ai)
						hb = q.houses.house_at(t.bi)
						with_p = $parts.set(
							t.x,
							{ ..p, houses: p.houses.with_house_at({ at: t.ai, house: hb }) },
						) ?? crash "SlotSearch.houses_tidied_in: in range"
						$parts = with_p.set(
							t.y,
							{ ..q, houses: q.houses.with_house_at({ at: t.bi, house: ha }) },
						) ?? crash "SlotSearch.houses_tidied_in: in range"
					}
				}
			}
			$parts.fold(
				slot_routes,
				|slots, part| {
					route = slot_stops_at(slots, part.slot)
					stop = Route.stop_at(route, part.at)
					slots.set(
						part.slot,
						route.set(
							part.at,
							{ ..stop, houses: part.houses },
						) ?? crash "SlotSearch.houses_tidied_in: in range",
					) ?? crash "SlotSearch.houses_tidied_in: in range"
				},
			)
		}
	}
}

part_at : List(Part), U64 -> Part
part_at = |parts, i| parts.get(i) ?? crash "SlotSearch.part_at: a part of the split"

## A slot's part of `nbhd`: its first stop there and the gates of the visit
## that delivers it, or none when its path never delivers it.
slot_part : List(List(Stop)), { slot : U64, nbhd : U8 } -> Try(Part, [NoVisit])
slot_part = |slot_routes, { slot, nbhd }| {
	route = slot_stops_at(slot_routes, slot)
	at = route.find_first_index(|s| s.nbhd == nbhd) ?? crash "SlotSearch.slot_part: the slot serves it"
	nodes = Pain.path_nodes(route)
	match nodes.find_first_index(|n| n == nbhd) {
		Ok(i) if i >= 1 and i + 1 < nodes.len() => {
			before = nodes.get(i - 1) ?? crash "SlotSearch.slot_part: in range"
			after = nodes.get(i + 1) ?? crash "SlotSearch.slot_part: in range"
			Ok({
				slot,
				at,
				entry_angle: Seattle.gate_angle(nbhd, before),
				exit_angle: Seattle.gate_angle(nbhd, after),
				houses: Route.stop_at(route, at).houses,
			})
		}

		_ => Err(NoVisit)
	}
}

part_minutes : Part, { nbhd : U8, houses : Houses } -> F64
part_minutes = |part, { nbhd, houses }| RoadGraph.local_minutes(
	nbhd,
	{
		entry_angle: part.entry_angle,
		exit_angle: part.exit_angle,
		angles: Seattle.house_angles(nbhd, houses.to_list()),
	},
)

## Corridor repair's candidates for the neighborhood `b` that truck `t`
## threads through, scored against `best`: the better of each and it.
corridor_repair_onto : CorridorMove,
{
	slots : List(List(Stop)),
	tidied : List(I64),
	t : U64,
	b : U8,
	splitting : SlotSearch.Splitting,
} -> CorridorMove
corridor_repair_onto = |best, { slots, tidied, t, b, splitting }| {
	var $best = best
	rt = slot_stops_at(slots, t)
	match slots.find_first_index(|r| r.any(|s| s.nbhd == b)) {
		Err(NotFound) => {}
		Ok(tp) =>
			if tp != t {
				rtp = slot_stops_at(slots, tp)
				b_stop = rtp.find_first(|s| s.nbhd == b) ?? crash "SlotSearch.corridor_repair_onto: the slot serves it"
				if !b_stop.is_pinned() {
					base = tidied_at(tidied, t) + tidied_at(tidied, tp)
					without = rtp.drop_if(|s| s.nbhd == b)
					load_t = Route.load(rt).to_i64_wrap()
					load_tp = Route.load(rtp).to_i64_wrap()
					cap_t = Seattle.cap_of_slot(t).to_i64_wrap()
					cap_tp = Seattle.cap_of_slot(tp).to_i64_wrap()
					b_load = b_stop.load().to_i64_wrap()
					name_b = Seattle.name_of(b)
					# (a) Absorbed whole, if it fits.
					if load_t + b_load <= cap_t {
						t_stops = Route.stops_with_cheapest_insert(rt, b_stop)
						after = Route.tidied_pain(t_stops) + Route.tidied_pain(without)
						gain = base - after
						if gain >= 1 and beats($best, gain) {
							$best = Move({
								gain,
								t,
								tp,
								t_stops,
								tp_stops: without,
								name: name_b,
								via: "absorbed",
								touched: Replay.stop_keys([b_stop]),
							})
						}
					}
					# (b) Traded for one of t's stops.
					for trade in rt {
						trade_load = trade.load().to_i64_wrap()
						fits_t = load_t - trade_load + b_load <= cap_t
						fits = fits_t and load_tp - b_load + trade_load <= cap_tp
						if !trade.is_pinned() and fits {
							t_without = without_nbhd(rt, trade.nbhd)
							t_stops = Route.stops_with_cheapest_insert(t_without, b_stop)
							tp_stops = Route.stops_with_cheapest_insert(without, trade)
							after = Route.tidied_pain(t_stops) + Route.tidied_pain(tp_stops)
							gain = base - after
							if gain >= 1 and beats($best, gain) {
								$best = Move({
									gain,
									t,
									tp,
									t_stops,
									tp_stops,
									name: name_b,
									via: "trading ${Seattle.name_of(trade.nbhd)}",
									touched: Replay.stop_keys([b_stop, trade]),
								})
							}
						}
					}
					# (c) A slice carved off in trade for one of t's stops.
					for xi in 0..<rt.len() {
						x = Route.stop_at(rt, xi)
						x_load = x.load().to_i64_wrap()
						if !x.is_pinned() {
							k_min = larger(1, load_tp - cap_tp + x_load)
							k_max = smaller(b_load - 1, cap_t - load_t + x_load)
							{ lo, hi } =
								match splitting {
									CapacityNeutral => {
										lo: larger(k_min, x_load),
										hi: smaller(k_max, x_load),
									}
									AnyShift => { lo: k_min, hi: k_max }
								}
							var $k = lo
							while $k <= hi {
								ku = $k.to_u64_wrap()
								take = Route.free_stop(b, b_stop.houses.take_first(ku))
								rest = Route.free_stop(b, b_stop.houses.drop_first(ku))
								t_stops = Route.stops_with_cheapest_insert(rt.drop_at(xi), take)
								swapped = rtp.map(
									|s|
										if s.nbhd == b {
											rest
										} else {
											s
										},
								)
								tp_stops = Route.stops_with_cheapest_insert(swapped, x)
								after = Route.tidied_pain(t_stops) + Route.tidied_pain(tp_stops)
								gain = base - after
								if gain >= 1 and beats($best, gain) {
									left = b_stop.load() - ku
									traded = Seattle.name_of(x.nbhd)
									via = "split ${ku.to_str()}/${left.to_str()}, trading ${traded}"
									$best = Move({
										gain,
										t,
										tp,
										t_stops,
										tp_stops,
										name: name_b,
										via,
										touched: Replay.stop_keys([x, take]),
									})
								}
								$k = $k + 1
							}
						}
					}
				}
			}
	}
	$best
}
