# Klondike -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Rng

Klondike :: [].{
	KlondikeState : { col0 : List(I64), col1 : List(I64), col2 : List(I64), col3 : List(I64), col4 : List(I64), col5 : List(I64), col6 : List(I64), downs : List(I64), founds : List(I64), stock : List(I64), waste : List(I64), draw : I64, sterile : I64, moves : I64 }
	KlondikeResult : { founded : I64, moves : I64, won : Bool }
	KlondikeMove : { from : I64, start : I64, to : I64 }

	kd_rank : I64 -> I64
	kd_rank = |c| ({
		r = Rng.rng_mod(c, 13)
		(if (r == 12) { 0 } else { (r + 1) })
	})

	kd_suit : I64 -> I64
	kd_suit = |c| I64.div_trunc_by(c, 13)

	kd_red : I64 -> Bool
	kd_red = |c| ({
		s = kd_suit(c)
		(if (s == 1) { True } else { (if (s == 2) { True } else { False }) })
	})

	kd_alternates : I64, I64 -> Bool
	kd_alternates = |a, b| (if kd_red(a) { (if kd_red(b) { False } else { True }) } else { (if kd_red(b) { True } else { False }) })

	kd_take_loop : List(I64), I64, I64, I64, List(I64) -> List(I64)
	kd_take_loop = |src, start, count, i, acc| (if (i >= count) { acc } else { kd_take_loop(src, start, count, (i + 1), List.append(acc, (List.get(src, I64.to_u64_wrap((start + i))) ?? crash("list-at out of range")))) })

	kd_slice : List(I64), I64, I64 -> List(I64)
	kd_slice = |src, start, count| kd_take_loop(src, start, count, 0, [])

	kd_copy_of : List(I64) -> List(I64)
	kd_copy_of = |src| kd_take_loop(src, 0, U64.to_i64_wrap(List.len(src)), 0, [])

	kd_drop_from_end : List(I64), I64 -> List(I64)
	kd_drop_from_end = |src, count| ({
		n = U64.to_i64_wrap(List.len(src))
		kd_take_loop(src, 0, (n - count), 0, [])
	})

	kd_append : List(I64), List(I64), I64, I64 -> List(I64)
	kd_append = |base, extra, i, n| (if (i >= n) { base } else { kd_append(List.append(base, (List.get(extra, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), extra, (i + 1), n) })

	kd_fill : I64, I64, I64, List(I64) -> List(I64)
	kd_fill = |v, i, n, acc| (if (i >= n) { acc } else { kd_fill(v, (i + 1), n, List.append(acc, v)) })

	kd_count_up : I64, I64, List(I64) -> List(I64)
	kd_count_up = |i, n, acc| (if (i >= n) { acc } else { kd_count_up((i + 1), n, List.append(acc, i)) })

	kd_reverse_loop : List(I64), I64, List(I64) -> List(I64)
	kd_reverse_loop = |src, i, acc| (if (i < 0) { acc } else { kd_reverse_loop(src, (i - 1), List.append(acc, (List.get(src, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	kd_reverse : List(I64) -> List(I64)
	kd_reverse = |src| kd_reverse_loop(src, (U64.to_i64_wrap(List.len(src)) - 1), [])

	klondike_deck_new : I64 -> List(I64)
	klondike_deck_new = |seed| ({
		deck = kd_count_up(0, 52, [])
		kd_shuffle(deck, seed, 51)
	})

	kd_shuffle : List(I64), I64, I64 -> List(I64)
	kd_shuffle = |deck, seed, i| (if (i <= 0) { deck } else { ({
		rng = Rng.rng_new(((seed * 7) + i))
		j = Rng.rng_mod(Rng.rng_value(Rng.rng_next(rng)), (i + 1))
		vi = (List.get(deck, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		vj = (List.get(deck, I64.to_u64_wrap(j)) ?? crash("list-at out of range"))
		d2 = (List.set(deck, I64.to_u64_wrap(i), vj) ?? crash("list-set-at past the end"))
		d3 = (List.set(d2, I64.to_u64_wrap(j), vi) ?? crash("list-set-at past the end"))
		kd_shuffle(d3, seed, (i - 1))
	}) })

	kd_get_col : Klondike.KlondikeState, I64 -> List(I64)
	kd_get_col = |st, c| (if (c == 0) { st.col0 } else { (if (c == 1) { st.col1 } else { (if (c == 2) { st.col2 } else { (if (c == 3) { st.col3 } else { (if (c == 4) { st.col4 } else { (if (c == 5) { st.col5 } else { st.col6 }) }) }) }) }) })

	kd_set_col : Klondike.KlondikeState, I64, List(I64) -> Klondike.KlondikeState
	kd_set_col = |st, c, col| (if (c == 0) { { col0: col, col1: st.col1, col2: st.col2, col3: st.col3, col4: st.col4, col5: st.col5, col6: st.col6, downs: st.downs, founds: st.founds, stock: st.stock, waste: st.waste, draw: st.draw, sterile: st.sterile, moves: st.moves } } else { (if (c == 1) { { col0: st.col0, col1: col, col2: st.col2, col3: st.col3, col4: st.col4, col5: st.col5, col6: st.col6, downs: st.downs, founds: st.founds, stock: st.stock, waste: st.waste, draw: st.draw, sterile: st.sterile, moves: st.moves } } else { (if (c == 2) { { col0: st.col0, col1: st.col1, col2: col, col3: st.col3, col4: st.col4, col5: st.col5, col6: st.col6, downs: st.downs, founds: st.founds, stock: st.stock, waste: st.waste, draw: st.draw, sterile: st.sterile, moves: st.moves } } else { (if (c == 3) { { col0: st.col0, col1: st.col1, col2: st.col2, col3: col, col4: st.col4, col5: st.col5, col6: st.col6, downs: st.downs, founds: st.founds, stock: st.stock, waste: st.waste, draw: st.draw, sterile: st.sterile, moves: st.moves } } else { (if (c == 4) { { col0: st.col0, col1: st.col1, col2: st.col2, col3: st.col3, col4: col, col5: st.col5, col6: st.col6, downs: st.downs, founds: st.founds, stock: st.stock, waste: st.waste, draw: st.draw, sterile: st.sterile, moves: st.moves } } else { (if (c == 5) { { col0: st.col0, col1: st.col1, col2: st.col2, col3: st.col3, col4: st.col4, col5: col, col6: st.col6, downs: st.downs, founds: st.founds, stock: st.stock, waste: st.waste, draw: st.draw, sterile: st.sterile, moves: st.moves } } else { { col0: st.col0, col1: st.col1, col2: st.col2, col3: st.col3, col4: st.col4, col5: st.col5, col6: col, downs: st.downs, founds: st.founds, stock: st.stock, waste: st.waste, draw: st.draw, sterile: st.sterile, moves: st.moves } }) }) }) }) }) })

	kd_set_rest : Klondike.KlondikeState, List(I64), List(I64), List(I64), List(I64), I64, I64 -> Klondike.KlondikeState
	kd_set_rest = |st, downs, founds, stock, waste, sterile, moves| { col0: st.col0, col1: st.col1, col2: st.col2, col3: st.col3, col4: st.col4, col5: st.col5, col6: st.col6, downs: downs, founds: founds, stock: stock, waste: waste, draw: st.draw, sterile: sterile, moves: moves }

	kd_down_at : Klondike.KlondikeState, I64 -> I64
	kd_down_at = |st, c| (List.get(st.downs, I64.to_u64_wrap(c)) ?? crash("list-at out of range"))

	kd_found_at : Klondike.KlondikeState, I64 -> I64
	kd_found_at = |st, s| (List.get(st.founds, I64.to_u64_wrap(s)) ?? crash("list-at out of range"))

	klondike_new : I64, I64 -> Klondike.KlondikeState
	klondike_new = |seed, draw| ({
		d = (if (draw < 1) { 1 } else { (if (draw > 3) { 3 } else { draw }) })
		kd_deal(klondike_deck_new(seed), d)
	})

	kd_deal : List(I64), I64 -> Klondike.KlondikeState
	kd_deal = |deck, d| ({
		c0 = kd_slice(deck, 0, 1)
		c1 = kd_slice(deck, 1, 2)
		c2 = kd_slice(deck, 3, 3)
		c3 = kd_slice(deck, 6, 4)
		c4 = kd_slice(deck, 10, 5)
		c5 = kd_slice(deck, 15, 6)
		c6 = kd_slice(deck, 21, 7)
		stock = kd_slice(deck, 28, 24)
		{ col0: c0, col1: c1, col2: c2, col3: c3, col4: c4, col5: c5, col6: c6, downs: kd_count_up(0, 7, []), founds: kd_fill((-1), 0, 4, []), stock: stock, waste: [], draw: d, sterile: 0, moves: 0 }
	})

	kd_visible_card : Klondike.KlondikeState, I64, I64 -> I64
	kd_visible_card = |st, c, i| ({
		col = kd_get_col(st, c)
		(if (i < 0) { (-1) } else { (if (i >= U64.to_i64_wrap(List.len(col))) { (-1) } else { (if (i < kd_down_at(st, c)) { (-1) } else { (List.get(col, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) }) }) })
	})

	kd_waste_top : Klondike.KlondikeState -> I64
	kd_waste_top = |st| ({
		n = U64.to_i64_wrap(List.len(st.waste))
		(if (n == 0) { (-1) } else { (List.get(st.waste, I64.to_u64_wrap((n - 1))) ?? crash("list-at out of range")) })
	})

	kd_founded : Klondike.KlondikeState, I64, I64 -> I64
	kd_founded = |st, s, acc| (if (s >= 4) { acc } else { kd_founded(st, (s + 1), ((acc + kd_found_at(st, s)) + 1)) })

	kd_won : Klondike.KlondikeState -> Bool
	kd_won = |st| (if (kd_founded(st, 0, 0) == 52) { True } else { False })

	kd_run_len : List(I64), I64 -> I64
	kd_run_len = |col, from_idx| ({
		n = U64.to_i64_wrap(List.len(col))
		(if (from_idx >= n) { 0 } else { kd_run_walk(col, from_idx, (from_idx + 1), 1) })
	})

	kd_run_walk : List(I64), I64, I64, I64 -> I64
	kd_run_walk = |col, prev, i, len| ({
		n = U64.to_i64_wrap(List.len(col))
		(if (i >= n) { len } else { ({
			c_prev = (List.get(col, I64.to_u64_wrap(prev)) ?? crash("list-at out of range"))
			c_curr = (List.get(col, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
			(if (kd_rank(c_curr) != (kd_rank(c_prev) - 1)) { len } else { (if (kd_alternates(c_prev, c_curr) == False) { len } else { kd_run_walk(col, i, (i + 1), (len + 1)) }) })
		}) })
	})

	kd_move_head : Klondike.KlondikeState, I64, I64 -> I64
	kd_move_head = |st, from, start| (if (from == 7) { kd_waste_top(st) } else { (if (from >= 8) { kd_found_card(st, (from - 8)) } else { kd_visible_card(st, from, start) }) })

	kd_found_card : Klondike.KlondikeState, I64 -> I64
	kd_found_card = |st, s| ({
		r = kd_found_at(st, s)
		(if (r < 0) { (-1) } else { (if (r == 0) { ((s * 13) + 12) } else { (((s * 13) + r) - 1) }) })
	})

	kd_count_moved : Klondike.KlondikeState, I64, I64 -> I64
	kd_count_moved = |st, from, start| (if (from >= 7) { 1 } else { (U64.to_i64_wrap(List.len(kd_get_col(st, from))) - start) })

	kd_tableau_takes : Klondike.KlondikeState, I64, I64 -> Bool
	kd_tableau_takes = |st, to, card| ({
		col = kd_get_col(st, to)
		n = U64.to_i64_wrap(List.len(col))
		(if (n == 0) { (if (kd_rank(card) == 12) { True } else { False }) } else { ({
			top = (List.get(col, I64.to_u64_wrap((n - 1))) ?? crash("list-at out of range"))
			(if (kd_rank(card) != (kd_rank(top) - 1)) { False } else { kd_alternates(top, card) })
		}) })
	})

	kd_foundation_takes : Klondike.KlondikeState, I64, I64 -> Bool
	kd_foundation_takes = |st, s, card| (if (kd_suit(card) != s) { False } else { ({
		r = kd_found_at(st, s)
		(if (kd_rank(card) == (r + 1)) { True } else { False })
	}) })

	kd_can_move : Klondike.KlondikeState, I64, I64, I64 -> Bool
	kd_can_move = |st, from, start, to| (if (from < 0) { False } else { (if (from > 11) { False } else { (if (to < 0) { False } else { (if (to > 10) { False } else { ({
		head = kd_move_head(st, from, start)
		(if (head < 0) { False } else { (if (from < 7) { (if (to < 7) { (if (from == to) { False } else { kd_can_from_tableau(st, from, start, to, head) }) } else { kd_can_from_tableau(st, from, start, to, head) }) } else { kd_can_single(st, from, to, head) }) })
	}) }) }) }) })

	kd_can_from_tableau : Klondike.KlondikeState, I64, I64, I64, I64 -> Bool
	kd_can_from_tableau = |st, from, start, to, head| ({
		col = kd_get_col(st, from)
		n = U64.to_i64_wrap(List.len(col))
		(if (start < kd_down_at(st, from)) { False } else { (if (kd_run_len(col, start) != (n - start)) { False } else { (if (to >= 7) { (if ((n - start) != 1) { False } else { kd_foundation_takes(st, (to - 7), head) }) } else { kd_tableau_takes(st, to, head) }) }) })
	})

	kd_can_single : Klondike.KlondikeState, I64, I64, I64 -> Bool
	kd_can_single = |st, from, to, head| (if (to >= 7) { (if (from >= 8) { False } else { kd_foundation_takes(st, (to - 7), head) }) } else { kd_tableau_takes(st, to, head) })

	kd_apply_move : Klondike.KlondikeState, I64, I64, I64 -> Klondike.KlondikeState
	kd_apply_move = |st, from, start, to| ({
		_head = kd_move_head(st, from, start)
		count = kd_count_moved(st, from, start)
		moved = kd_lifted(st, from, start, count)
		st2 = kd_remove_from(st, from, start, count)
		st3 = kd_place_on(st2, to, moved, count)
		gained = (if (to >= 7) { 1 } else { 0 })
		kd_after_move(st3, from, gained)
	})

	kd_lifted : Klondike.KlondikeState, I64, I64, I64 -> List(I64)
	kd_lifted = |st, from, start, count| (if (from == 7) { kd_fill(kd_waste_top(st), 0, 1, []) } else { (if (from >= 8) { kd_fill(kd_found_card(st, (from - 8)), 0, 1, []) } else { kd_slice(kd_get_col(st, from), start, count) }) })

	kd_remove_from : Klondike.KlondikeState, I64, I64, I64 -> Klondike.KlondikeState
	kd_remove_from = |st, from, _start, count| (if (from == 7) { kd_set_rest(st, st.downs, st.founds, st.stock, kd_drop_from_end(st.waste, 1), st.sterile, st.moves) } else { (if (from >= 8) { kd_take_off_foundation(st, (from - 8)) } else { kd_set_col(st, from, kd_drop_from_end(kd_get_col(st, from), count)) }) })

	kd_take_off_foundation : Klondike.KlondikeState, I64 -> Klondike.KlondikeState
	kd_take_off_foundation = |st, s| ({
		f2 = (List.set(kd_copy_of(st.founds), I64.to_u64_wrap(s), (kd_found_at(st, s) - 1)) ?? crash("list-set-at past the end"))
		kd_set_rest(st, st.downs, f2, st.stock, st.waste, st.sterile, st.moves)
	})

	kd_place_on : Klondike.KlondikeState, I64, List(I64), I64 -> Klondike.KlondikeState
	kd_place_on = |st, to, moved, count| (if (to >= 7) { kd_put_on_foundation(st, (to - 7), (List.get(moved, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))) } else { kd_set_col(st, to, kd_append(kd_get_col(st, to), moved, 0, count)) })

	kd_put_on_foundation : Klondike.KlondikeState, I64, I64 -> Klondike.KlondikeState
	kd_put_on_foundation = |st, s, card| ({
		f2 = (List.set(kd_copy_of(st.founds), I64.to_u64_wrap(s), kd_rank(card)) ?? crash("list-set-at past the end"))
		kd_set_rest(st, st.downs, f2, st.stock, st.waste, st.sterile, st.moves)
	})

	kd_after_move : Klondike.KlondikeState, I64, I64 -> Klondike.KlondikeState
	kd_after_move = |st, from, gained| ({
		flipped = (if (from < 7) { kd_flip_needed(st, from) } else { False })
		d2 = (if flipped { kd_flip(st, from) } else { st.downs })
		fresh = (if (gained > 0) { 0 } else { (if flipped { 0 } else { (st.sterile + 1) }) })
		kd_set_rest(st, d2, st.founds, st.stock, st.waste, fresh, (st.moves + 1))
	})

	kd_flip_needed : Klondike.KlondikeState, I64 -> Bool
	kd_flip_needed = |st, c| ({
		n = U64.to_i64_wrap(List.len(kd_get_col(st, c)))
		(if (n == 0) { False } else { (if (kd_down_at(st, c) >= n) { True } else { False }) })
	})

	kd_flip : Klondike.KlondikeState, I64 -> List(I64)
	kd_flip = |st, c| ({
		n = U64.to_i64_wrap(List.len(kd_get_col(st, c)))
		(List.set(kd_copy_of(st.downs), I64.to_u64_wrap(c), (n - 1)) ?? crash("list-set-at past the end"))
	})

	kd_can_draw : Klondike.KlondikeState -> Bool
	kd_can_draw = |st| (if (U64.to_i64_wrap(List.len(st.stock)) > 0) { True } else { False })

	kd_draw : Klondike.KlondikeState -> Klondike.KlondikeState
	kd_draw = |st| (if (kd_can_draw(st) == False) { st } else { kd_draw_loop(st, 0, st.draw) })

	kd_draw_loop : Klondike.KlondikeState, I64, I64 -> Klondike.KlondikeState
	kd_draw_loop = |st, i, n| (if (i >= n) { kd_set_rest(st, st.downs, st.founds, st.stock, st.waste, (st.sterile + 1), (st.moves + 1)) } else { ({
		sn = U64.to_i64_wrap(List.len(st.stock))
		(if (sn == 0) { kd_set_rest(st, st.downs, st.founds, st.stock, st.waste, (st.sterile + 1), (st.moves + 1)) } else { ({
			card = (List.get(st.stock, I64.to_u64_wrap((sn - 1))) ?? crash("list-at out of range"))
			st2 = kd_set_rest(st, st.downs, st.founds, kd_drop_from_end(st.stock, 1), List.append(kd_copy_of(st.waste), card), st.sterile, st.moves)
			kd_draw_loop(st2, (i + 1), n)
		}) })
	}) })

	kd_can_recycle : Klondike.KlondikeState -> Bool
	kd_can_recycle = |st| (if (U64.to_i64_wrap(List.len(st.stock)) > 0) { False } else { (if (U64.to_i64_wrap(List.len(st.waste)) == 0) { False } else { True }) })

	kd_recycle : Klondike.KlondikeState -> Klondike.KlondikeState
	kd_recycle = |st| (if (kd_can_recycle(st) == False) { st } else { kd_set_rest(st, st.downs, st.founds, kd_reverse(st.waste), [], (st.sterile + 1), (st.moves + 1)) })

	kd_safe_to_found : Klondike.KlondikeState, I64 -> Bool
	kd_safe_to_found = |st, card| ({
		r = kd_rank(card)
		(if (r <= 1) { True } else { (if kd_red(card) { kd_both_at_least(st, 0, 3, (r - 1)) } else { kd_both_at_least(st, 1, 2, (r - 1)) }) })
	})

	kd_both_at_least : Klondike.KlondikeState, I64, I64, I64 -> Bool
	kd_both_at_least = |st, a, b, r| (if (kd_found_at(st, a) < r) { False } else { (if (kd_found_at(st, b) < r) { False } else { True }) })

	kd_encode : I64, I64, I64 -> I64
	kd_encode = |from, start, to| (((from * 10000) + (start * 100)) + to)

	kd_decode : I64 -> Klondike.KlondikeMove
	kd_decode = |code| ({
		from = I64.div_trunc_by(code, 10000)
		rem = Rng.rng_mod(code, 10000)
		start = I64.div_trunc_by(rem, 100)
		to = Rng.rng_mod(rem, 100)
		{ from: from, start: start, to: to }
	})

	kd_suggest : Klondike.KlondikeState -> I64
	kd_suggest = |st| ({
		a = kd_find_foundation(st, 0)
		(if (a >= 0) { a } else { ({
			b = kd_find_flip(st, 0)
			(if (b >= 0) { b } else { ({
				c = kd_find_from_waste(st, 0)
				(if (c >= 0) { c } else { kd_find_foundation_any(st, 0) })
			}) })
		}) })
	})

	kd_find_foundation_any : Klondike.KlondikeState, I64 -> I64
	kd_find_foundation_any = |st, i| (if (i >= 8) { (-1) } else { ({
		from = (if (i == 0) { 7 } else { (i - 1) })
		start = kd_top_index(st, from)
		head = kd_move_head(st, from, start)
		(if (head < 0) { kd_find_foundation_any(st, (i + 1)) } else { ({
			s = kd_suit(head)
			(if kd_can_move(st, from, start, (s + 7)) { kd_encode(from, start, (s + 7)) } else { kd_find_foundation_any(st, (i + 1)) })
		}) })
	}) })

	kd_find_foundation : Klondike.KlondikeState, I64 -> I64
	kd_find_foundation = |st, i| (if (i >= 8) { (-1) } else { ({
		from = (if (i == 0) { 7 } else { (i - 1) })
		start = kd_top_index(st, from)
		head = kd_move_head(st, from, start)
		(if (head < 0) { kd_find_foundation(st, (i + 1)) } else { (if (kd_safe_to_found(st, head) == False) { kd_find_foundation(st, (i + 1)) } else { ({
			s = kd_suit(head)
			(if kd_can_move(st, from, start, (s + 7)) { kd_encode(from, start, (s + 7)) } else { kd_find_foundation(st, (i + 1)) })
		}) }) })
	}) })

	kd_top_index : Klondike.KlondikeState, I64 -> I64
	kd_top_index = |st, from| (if (from >= 7) { 0 } else { (U64.to_i64_wrap(List.len(kd_get_col(st, from))) - 1) })

	kd_find_flip : Klondike.KlondikeState, I64 -> I64
	kd_find_flip = |st, c| (if (c >= 7) { (-1) } else { ({
		d = kd_down_at(st, c)
		(if (d == 0) { kd_find_flip(st, (c + 1)) } else { ({
			n = U64.to_i64_wrap(List.len(kd_get_col(st, c)))
			(if (n <= d) { kd_find_flip(st, (c + 1)) } else { ({
				m = kd_find_target(st, c, d, 0)
				(if (m >= 0) { m } else { kd_find_flip(st, (c + 1)) })
			}) })
		}) })
	}) })

	kd_find_target : Klondike.KlondikeState, I64, I64, I64 -> I64
	kd_find_target = |st, from, start, to| (if (to >= 7) { (-1) } else { (if kd_can_move(st, from, start, to) { kd_encode(from, start, to) } else { kd_find_target(st, from, start, (to + 1)) }) })

	kd_find_from_waste : Klondike.KlondikeState, I64 -> I64
	kd_find_from_waste = |st, to| (if (to >= 7) { (-1) } else { (if kd_can_move(st, 7, 0, to) { kd_encode(7, 0, to) } else { kd_find_from_waste(st, (to + 1)) }) })

	kd_ai : Klondike.KlondikeState -> I64
	kd_ai = |st| (if kd_won(st) { (-1) } else { (if (st.sterile > 120) { (-1) } else { ({
		m = kd_suggest(st)
		(if (m >= 0) { m } else { (if kd_can_draw(st) { (-2) } else { (if kd_can_recycle(st) { (-3) } else { (-1) }) }) })
	}) }) })

	klondike_run : I64, I64 -> Klondike.KlondikeResult
	klondike_run = |seed, draw| ({
		st = klondike_new(seed, draw)
		kd_play_loop(st, 0)
	})

	kd_play_loop : Klondike.KlondikeState, I64 -> Klondike.KlondikeResult
	kd_play_loop = |st, steps| (if (steps >= 600) { kd_result(st) } else { ({
		m = kd_ai(st)
		(if (m == (-1)) { kd_result(st) } else { (if (m == (-2)) { kd_play_loop(kd_draw(st), (steps + 1)) } else { (if (m == (-3)) { kd_play_loop(kd_recycle(st), (steps + 1)) } else { ({
			mv = kd_decode(m)
			kd_play_loop(kd_apply_move(st, mv.from, mv.start, mv.to), (steps + 1))
		}) }) }) })
	}) })

	kd_result : Klondike.KlondikeState -> Klondike.KlondikeResult
	kd_result = |st| { founded: kd_founded(st, 0, 0), moves: st.moves, won: kd_won(st) }
}
