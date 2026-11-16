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
	Slotted : { by_slot : List(List(Stop)), moves : List(Replay.Move) }

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
		var $slots = start.by_slot
		var $moves = start.moves
		var $rounds = 0
		while $rounds < 50 {
			$rounds = $rounds + 1
			tidied = $slots.map(Route.tidied_pain)
			var $best = NoMove
			for t in 0..<$slots.len() {
				rt = slot_at($slots, t)
				if !rt.is_empty() {
					delivered = rt.map(|s| s.nbhd)
					threaded = Pain.path_nodes(rt).fold(
						[],
						|seen, node|
							if node != Seattle.fc and !delivered.contains(node) and !seen.contains(node) {
								seen.append(node)
							} else {
								seen
							},
					)
					for b in threaded {
						match $slots.find_first_index(|r| r.any(|s| s.nbhd == b)) {
							Err(NotFound) => {}
							Ok(tp) =>
								if tp != t {
									rtp = slot_at($slots, tp)
									b_stop = rtp.find_first(|s| s.nbhd == b) ?? crash "SlotSearch.corridor_repaired: the slot serves it"
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
											nt = Route.cheapest_insert(rt, b_stop)
											gain = base - (Route.tidied_pain(nt) + Route.tidied_pain(without))
											if gain >= 1 and beats($best, gain) {
												$best = Move({ gain, t, tp, nt, ntp: without, name: name_b, via: "absorbed", touched: Replay.keys_of([b_stop]) })
											}
										}
										# (b) Traded for one of t's stops.
										for trade in rt {
											trade_load = trade.load().to_i64_wrap()
											if !trade.is_pinned() and load_t - trade_load + b_load <= cap_t and load_tp - b_load + trade_load <= cap_tp {
												t_without = without_nbhd(rt, trade.nbhd)
												nt = Route.cheapest_insert(t_without, b_stop)
												ntp = Route.cheapest_insert(without, trade)
												gain = base - (Route.tidied_pain(nt) + Route.tidied_pain(ntp))
												if gain >= 1 and beats($best, gain) {
													$best = Move({ gain, t, tp, nt, ntp, name: name_b, via: "trading ${Seattle.name_of(trade.nbhd)}", touched: Replay.keys_of([b_stop, trade]) })
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
														CapacityNeutral => { lo: larger(k_min, x_load), hi: smaller(k_max, x_load) }
														AnyShift => { lo: k_min, hi: k_max }
													}
												var $k = lo
												while $k <= hi {
													ku = $k.to_u64_wrap()
													take = Route.free_stop(b, b_stop.houses.take_first(ku))
													rest = Route.free_stop(b, b_stop.houses.drop_first(ku))
													nt = Route.cheapest_insert(rt.drop_at(xi), take)
													swapped = rtp.map(|s| if s.nbhd == b { rest } else { s })
													ntp = Route.cheapest_insert(swapped, x)
													gain = base - (Route.tidied_pain(nt) + Route.tidied_pain(ntp))
													if gain >= 1 and beats($best, gain) {
														via = "split ${ku.to_str()}/${(b_stop.load() - ku).to_str()}, trading ${Seattle.name_of(x.nbhd)}"
														$best = Move({ gain, t, tp, nt, ntp, name: name_b, via, touched: Replay.keys_of([x, take]) })
													}
													$k = $k + 1
												}
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
					$rounds = 50
				}

				Move(m) => {
					$slots = ($slots.set(m.t, m.nt) ?? crash "SlotSearch.corridor_repaired: in range").set(m.tp, m.ntp) ?? crash "SlotSearch.corridor_repaired: in range"
					$moves = $moves.append(
						{
							kind: Consolidate,
							saved: m.gain,
							detail: "consolidated ${m.name} onto the truck passing through (${m.via})",
							frame: $slots,
							touched: m.touched,
						},
					)
				}
			}
		}
		{ by_slot: $slots, moves: $moves }
	}

	## A free stop relocated to another truck, or two traded, while a move
	## saves tidied pain within the trucks' own caps (at most 200 moves).
	relocated_or_swapped : Slotted -> Slotted
	relocated_or_swapped = |start| {
		var $slots = start.by_slot
		var $moves = start.moves
		var $rounds = 0
		while $rounds < 200 {
			$rounds = $rounds + 1
			cur = $slots.map(Route.tidied_pain)
			var $best = NoMove
			for a in 0..<$slots.len() {
				ra = slot_at($slots, a)
				for si in 0..<ra.len() {
					stop = Route.stop_at(ra, si)
					if !stop.is_pinned() {
						for b in 0..<$slots.len() {
							rb = slot_at($slots, b)
							if b != a and Route.load(rb) + stop.load() <= Seattle.cap_of_slot(b) {
								new_a = ra.drop_at(si)
								new_b = Route.cheapest_insert(rb, stop)
								gain = tidied_at(cur, a) + tidied_at(cur, b) - (Route.tidied_pain(new_a) + Route.tidied_pain(new_b))
								if gain >= 1 and beats($best, gain) {
									$best = Move({ gain, a, b, new_a, new_b, change: Moved, touched: Replay.keys_of([stop]) })
								}
							}
						}
					}
				}
			}
			for a in 0..<$slots.len() {
				ra = slot_at($slots, a)
				for b in (a + 1)..<$slots.len() {
					rb = slot_at($slots, b)
					for i in 0..<ra.len() {
						sa = Route.stop_at(ra, i)
						for j in 0..<rb.len() {
							sb = Route.stop_at(rb, j)
							if
								!sa.is_pinned()
								and !sb.is_pinned()
								and sa.nbhd != sb.nbhd
								and Route.load(ra) - sa.load() + sb.load() <= Seattle.cap_of_slot(a)
								and Route.load(rb) - sb.load() + sa.load() <= Seattle.cap_of_slot(b)
							{
								new_a = Route.coalesce(Route.reinsert(ra, { at: i, stop: sb }))
								new_b = Route.coalesce(Route.reinsert(rb, { at: j, stop: sa }))
								gain = tidied_at(cur, a) + tidied_at(cur, b) - (Route.tidied_pain(new_a) + Route.tidied_pain(new_b))
								if gain >= 1 and beats($best, gain) {
									$best = Move({ gain, a, b, new_a, new_b, change: Traded, touched: Replay.keys_of([sa, sb]) })
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
					$slots = ($slots.set(m.a, m.new_a) ?? crash "SlotSearch.relocated_or_swapped: in range").set(m.b, m.new_b) ?? crash "SlotSearch.relocated_or_swapped: in range"
					move =
						match m.change {
							Traded => { kind: Swap, detail: "traded a stop between trucks ${(m.a + 1).to_str()} and ${(m.b + 1).to_str()}" }
							Moved => { kind: Relocate, detail: "relocated a stop to truck ${(m.b + 1).to_str()}" }
						}
					$moves = $moves.append({ kind: move.kind, saved: m.gain, detail: move.detail, frame: $slots, touched: m.touched })
				}
			}
		}
		{ by_slot: $slots, moves: $moves }
	}

	## Arc-rebalance: a relocate or a swap that leaves one truck over its
	## cap, rescued by shifting one ring arc of a free stop from the
	## overfull truck to the other (at most 200 moves).
	arc_rebalanced : Slotted -> Slotted
	arc_rebalanced = |start| {
		var $slots = start.by_slot
		var $moves = start.moves
		var $rounds = 0
		while $rounds < 200 {
			$rounds = $rounds + 1
			cur = $slots.map(Route.tidied_pain)
			var $best = NoMove
			for a in 0..<$slots.len() {
				ra = slot_at($slots, a)
				for si in 0..<ra.len() {
					stop = Route.stop_at(ra, si)
					if !stop.is_pinned() {
						for b in 0..<$slots.len() {
							if b != a {
								$best = rescued(
									$best,
									{ cur, a, b, ra: ra.drop_at(si), rb: Route.cheapest_insert(slot_at($slots, b), stop), touched: Replay.keys_of([stop]) },
								)
							}
						}
					}
				}
			}
			for a in 0..<$slots.len() {
				ra = slot_at($slots, a)
				for b in (a + 1)..<$slots.len() {
					rb = slot_at($slots, b)
					for i in 0..<ra.len() {
						sa = Route.stop_at(ra, i)
						for j in 0..<rb.len() {
							sb = Route.stop_at(rb, j)
							if !sa.is_pinned() and !sb.is_pinned() and sa.nbhd != sb.nbhd {
								$best = rescued(
									$best,
									{
										cur,
										a,
										b,
										ra: Route.coalesce(Route.reinsert(ra, { at: i, stop: sb })),
										rb: Route.coalesce(Route.reinsert(rb, { at: j, stop: sa })),
										touched: Replay.keys_of([sa, sb]),
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
					$slots = ($slots.set(m.a, m.ra) ?? crash "SlotSearch.arc_rebalanced: in range").set(m.b, m.rb) ?? crash "SlotSearch.arc_rebalanced: in range"
					$moves = $moves.append(
						{
							kind: Relocate,
							saved: m.gain,
							detail: "arc-rebalance between trucks ${(m.a + 1).to_str()} and ${(m.b + 1).to_str()}",
							frame: $slots,
							touched: m.touched,
						},
					)
				}
			}
		}
		{ by_slot: $slots, moves: $moves }
	}

	## Where two or more trucks split a neighborhood, trade houses between
	## them, one pair at a time, while a trade shortens their ring walks
	## (float minutes, by more than 1e-6). Pain can't see which house a truck
	## takes, so this tidy is pain-neutral.
	houses_tidied : List(List(Stop)) -> List(List(Stop))
	houses_tidied = |by_slot| {
		var $order = []
		for route in by_slot {
			for s in route {
				if !s.houses.is_empty() and !$order.contains(s.nbhd) {
					$order = $order.append(s.nbhd)
				}
			}
		}
		$order.fold(by_slot, houses_tidied_in)
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
larger = |a, b| if a > b { a } else { b }

smaller : I64, I64 -> I64
smaller = |a, b| if a < b { a } else { b }

slot_at : List(List(Stop)), U64 -> List(Stop)
slot_at = |slots, i| slots.get(i) ?? crash "SlotSearch.slot_at: one of the eight slots"

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

## The candidate arc-rebalance move `ra`/`rb` for trucks `a` and `b`,
## scored as it is when both fit, or rescued by an arc when one truck is
## over its cap and the other isn't; the better of it and `best`.
Candidate : { cur : List(I64), a : U64, b : U64, ra : List(Stop), rb : List(Stop), touched : List(Replay.HouseKey) }

rescued : [NoMove, Move({ gain : I64, a : U64, b : U64, ra : List(Stop), rb : List(Stop), touched : List(Replay.HouseKey) })], Candidate -> [NoMove, Move({ gain : I64, a : U64, b : U64, ra : List(Stop), rb : List(Stop), touched : List(Replay.HouseKey) })]
rescued = |best, c| {
	cap_a = Seattle.cap_of_slot(c.a)
	cap_b = Seattle.cap_of_slot(c.b)
	la = Route.load(c.ra)
	lb = Route.load(c.rb)
	if la <= cap_a and lb <= cap_b {
		scored(best, c)
	} else {
		is_over_a = la > cap_a and lb <= cap_b
		is_over_b = lb > cap_b and la <= cap_a
		if !is_over_a and !is_over_b {
			best
		} else {
			over = if is_over_a { c.ra } else { c.rb }
			under = if is_over_a { c.rb } else { c.ra }
			cap_under = if is_over_a { cap_b } else { cap_a }
			need = Route.load(over) - (if is_over_a { cap_a } else { cap_b })
			var $best = best
			for fi in 0..<over.len() {
				f = Route.stop_at(over, fi)
				if !f.is_pinned() {
					for arc_list in Seattle.arc_groups(f.nbhd, f.houses.to_list()) {
						arc = Houses.from_list(arc_list)
						if arc.count() >= need and arc.count() < f.load() and Route.load(under) + arc.count() <= cap_under {
							keep = f.houses.without(arc)
							raw = over.map_with_index(|s, i| { stop: if i == fi { { nbhd: s.nbhd, houses: keep, pin: s.pin } } else { s }, i }).keep_if(|e| if e.i == fi { !keep.is_empty() } else { !e.stop.houses.is_empty() }).map(|e| e.stop)
							new_over = Route.coalesce(raw)
							new_under = Route.cheapest_insert(under, Route.free_stop(f.nbhd, arc))
							touched = c.touched.concat(Replay.keys_for(f.nbhd, arc))
							$best =
								if is_over_a {
									scored($best, { ..c, ra: new_over, rb: new_under, touched })
								} else {
									scored($best, { ..c, ra: new_under, rb: new_over, touched })
								}
						}
					}
				}
			}
			$best
		}
	}
}

scored : [NoMove, Move({ gain : I64, a : U64, b : U64, ra : List(Stop), rb : List(Stop), touched : List(Replay.HouseKey) })], Candidate -> [NoMove, Move({ gain : I64, a : U64, b : U64, ra : List(Stop), rb : List(Stop), touched : List(Replay.HouseKey) })]
scored = |best, c|
	if Route.load(c.ra) > Seattle.cap_of_slot(c.a) or Route.load(c.rb) > Seattle.cap_of_slot(c.b) {
		best
	} else {
		gain = tidied_at(c.cur, c.a) + tidied_at(c.cur, c.b) - (Route.tidied_pain(c.ra) + Route.tidied_pain(c.rb))
		if gain >= 1 and beats(best, gain) {
			Move({ gain, a: c.a, b: c.b, ra: c.ra, rb: c.rb, touched: c.touched })
		} else {
			best
		}
	}

## One truck's part of a split neighborhood: its slot, where its stop
## there sits, the gates it enters and leaves by, and its houses there.
Part : { slot : U64, at : U64, entry : F64, exit : F64, houses : Houses }

houses_tidied_in : List(List(Stop)), U8 -> List(List(Stop))
houses_tidied_in = |by_slot, nbhd| {
	serving = List.from_iter(U64.until(0, by_slot.len())).keep_if(|i| slot_at(by_slot, i).any(|s| s.nbhd == nbhd and !s.houses.is_empty()))
	if serving.len() < 2 {
		by_slot
	} else {
		start_parts = serving.keep_oks(|slot| part_of(by_slot, slot, nbhd))
		if start_parts.len() < 2 {
			by_slot
		} else {
			var $parts = start_parts
			var $going = True
			while $going {
				var $best = NoTrade
				for x in 0..<$parts.len() {
					p = part_at($parts, x)
					for y in (x + 1)..<$parts.len() {
						q = part_at($parts, y)
						base = part_minutes(nbhd, p, p.houses) + part_minutes(nbhd, q, q.houses)
						for ai in 0..<p.houses.count() {
							for bi in 0..<q.houses.count() {
								ha = p.houses.house_at(ai)
								hb = q.houses.house_at(bi)
								gain = base - (part_minutes(nbhd, p, p.houses.with_house_at(ai, hb)) + part_minutes(nbhd, q, q.houses.with_house_at(bi, ha)))
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
						with_p = $parts.set(t.x, { ..p, houses: p.houses.with_house_at(t.ai, hb) }) ?? crash "SlotSearch.houses_tidied_in: in range"
						$parts = with_p.set(t.y, { ..q, houses: q.houses.with_house_at(t.bi, ha) }) ?? crash "SlotSearch.houses_tidied_in: in range"
					}
				}
			}
			$parts.fold(
				by_slot,
				|slots, part| {
					route = slot_at(slots, part.slot)
					stop = Route.stop_at(route, part.at)
					slots.set(part.slot, route.set(part.at, { ..stop, houses: part.houses }) ?? crash "SlotSearch.houses_tidied_in: in range") ?? crash "SlotSearch.houses_tidied_in: in range"
				},
			)
		}
	}
}

part_at : List(Part), U64 -> Part
part_at = |parts, i| parts.get(i) ?? crash "SlotSearch.part_at: a part of the split"

## A slot's part of `nbhd`: its first stop there and the gates of the visit
## that delivers it, or none when its path never delivers it.
part_of : List(List(Stop)), U64, U8 -> Try(Part, [NoVisit])
part_of = |by_slot, slot, nbhd| {
	route = slot_at(by_slot, slot)
	at = route.find_first_index(|s| s.nbhd == nbhd) ?? crash "SlotSearch.part_of: the slot serves it"
	nodes = Pain.path_nodes(route)
	match nodes.find_first_index(|n| n == nbhd) {
		Ok(i) if i >= 1 and i + 1 < nodes.len() => {
			before = nodes.get(i - 1) ?? crash "SlotSearch.part_of: in range"
			after = nodes.get(i + 1) ?? crash "SlotSearch.part_of: in range"
			Ok({ slot, at, entry: Seattle.gate_angle(nbhd, before), exit: Seattle.gate_angle(nbhd, after), houses: Route.stop_at(route, at).houses })
		}

		_ => Err(NoVisit)
	}
}

part_minutes : U8, Part, Houses -> F64
part_minutes = |nbhd, part, houses| RoadGraph.local_minutes(nbhd, { entry: part.entry, exit: part.exit, angles: Seattle.house_angles(nbhd, houses.to_list()) })
