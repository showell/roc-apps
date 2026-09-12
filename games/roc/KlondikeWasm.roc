# KlondikeWasm -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Klondike

KlondikeWasm :: [].{

	kd_wasm_copy_list : List(I64), I64, List(I64) -> List(I64)
	kd_wasm_copy_list = |src, i, acc| (if (i >= U64.to_i64_wrap(List.len(src))) { acc } else { kd_wasm_copy_list(src, (i + 1), List.append(acc, (List.get(src, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	kd_wasm_copy_of : List(I64) -> List(I64)
	kd_wasm_copy_of = |src| kd_wasm_copy_list(src, 0, [])

	kd_copy_state : Klondike.KlondikeState -> Klondike.KlondikeState
	kd_copy_state = |st| { col0: kd_wasm_copy_of(st.col0), col1: kd_wasm_copy_of(st.col1), col2: kd_wasm_copy_of(st.col2), col3: kd_wasm_copy_of(st.col3), col4: kd_wasm_copy_of(st.col4), col5: kd_wasm_copy_of(st.col5), col6: kd_wasm_copy_of(st.col6), downs: kd_wasm_copy_of(st.downs), founds: kd_wasm_copy_of(st.founds), stock: kd_wasm_copy_of(st.stock), waste: kd_wasm_copy_of(st.waste), draw: st.draw, sterile: st.sterile, moves: st.moves }

	kd_wasm_rank : I64 -> I64
	kd_wasm_rank = |c| (if (c < 0) { (-1) } else { (if (c >= 52) { (-1) } else { Klondike.kd_rank(c) }) })

	kd_wasm_suit : I64 -> I64
	kd_wasm_suit = |c| (if (c < 0) { (-1) } else { (if (c >= 52) { (-1) } else { Klondike.kd_suit(c) }) })

	kd_wasm_new : I64, I64 -> Klondike.KlondikeState
	kd_wasm_new = |seed, draw| Klondike.klondike_new(seed, (if (draw < 1) { 1 } else { (if (draw > 3) { 3 } else { draw }) }))

	kd_wasm_col_size : Klondike.KlondikeState, I64 -> I64
	kd_wasm_col_size = |st, c| (if (c < 0) { (-1) } else { (if (c >= 7) { (-1) } else { U64.to_i64_wrap(List.len(Klondike.kd_get_col(st, c))) }) })

	kd_wasm_card : Klondike.KlondikeState, I64, I64 -> I64
	kd_wasm_card = |st, c, i| (if (c < 0) { (-1) } else { (if (c >= 7) { (-1) } else { Klondike.kd_visible_card(st, c, i) }) })

	kd_wasm_down : Klondike.KlondikeState, I64 -> I64
	kd_wasm_down = |st, c| (if (c < 0) { (-1) } else { (if (c >= 7) { (-1) } else { Klondike.kd_down_at(st, c) }) })

	kd_wasm_found : Klondike.KlondikeState, I64 -> I64
	kd_wasm_found = |st, s| (if (s < 0) { (-1) } else { (if (s >= 4) { (-1) } else { Klondike.kd_found_at(st, s) }) })

	kd_wasm_found_card : Klondike.KlondikeState, I64 -> I64
	kd_wasm_found_card = |st, s| (if (s < 0) { (-1) } else { (if (s >= 4) { (-1) } else { Klondike.kd_found_card(st, s) }) })

	kd_wasm_stock_size : Klondike.KlondikeState -> I64
	kd_wasm_stock_size = |st| U64.to_i64_wrap(List.len(st.stock))

	kd_wasm_waste_size : Klondike.KlondikeState -> I64
	kd_wasm_waste_size = |st| U64.to_i64_wrap(List.len(st.waste))

	kd_wasm_waste_top : Klondike.KlondikeState -> I64
	kd_wasm_waste_top = |st| Klondike.kd_waste_top(st)

	kd_wasm_founded : Klondike.KlondikeState -> I64
	kd_wasm_founded = |st| Klondike.kd_founded(st, 0, 0)

	kd_wasm_moves : Klondike.KlondikeState -> I64
	kd_wasm_moves = |st| st.moves

	kd_wasm_draw_count : Klondike.KlondikeState -> I64
	kd_wasm_draw_count = |st| st.draw

	kd_wasm_won : Klondike.KlondikeState -> I64
	kd_wasm_won = |st| (if Klondike.kd_won(st) { 1 } else { 0 })

	kd_wasm_run_len : Klondike.KlondikeState, I64, I64 -> I64
	kd_wasm_run_len = |st, c, i| (if (c < 0) { (-1) } else { (if (c >= 7) { (-1) } else { ({
		col = Klondike.kd_get_col(st, c)
		(if (i < 0) { (-1) } else { (if (i >= U64.to_i64_wrap(List.len(col))) { 0 } else { (if (i < Klondike.kd_down_at(st, c)) { 0 } else { Klondike.kd_run_len(col, i) }) }) })
	}) }) })

	kd_wasm_can_move : Klondike.KlondikeState, I64, I64, I64 -> I64
	kd_wasm_can_move = |st, from, start, to| (if Klondike.kd_can_move(st, from, start, to) { 1 } else { 0 })

	kd_wasm_move : Klondike.KlondikeState, I64, I64, I64 -> Klondike.KlondikeState
	kd_wasm_move = |st, from, start, to| (if (Klondike.kd_can_move(st, from, start, to) == False) { st } else { Klondike.kd_apply_move(kd_copy_state(st), from, start, to) })

	kd_wasm_can_draw : Klondike.KlondikeState -> I64
	kd_wasm_can_draw = |st| (if Klondike.kd_can_draw(st) { 1 } else { 0 })

	kd_wasm_draw : Klondike.KlondikeState -> Klondike.KlondikeState
	kd_wasm_draw = |st| (if (Klondike.kd_can_draw(st) == False) { st } else { Klondike.kd_draw(kd_copy_state(st)) })

	kd_wasm_can_recycle : Klondike.KlondikeState -> I64
	kd_wasm_can_recycle = |st| (if Klondike.kd_can_recycle(st) { 1 } else { 0 })

	kd_wasm_recycle : Klondike.KlondikeState -> Klondike.KlondikeState
	kd_wasm_recycle = |st| (if (Klondike.kd_can_recycle(st) == False) { st } else { Klondike.kd_recycle(kd_copy_state(st)) })

	kd_wasm_ai : Klondike.KlondikeState -> I64
	kd_wasm_ai = |st| Klondike.kd_ai(st)

	kd_wasm_move_from : I64 -> I64
	kd_wasm_move_from = |code| (if (code < 0) { (-1) } else { ({
		m = Klondike.kd_decode(code)
		m.from
	}) })

	kd_wasm_move_start : I64 -> I64
	kd_wasm_move_start = |code| (if (code < 0) { (-1) } else { ({
		m = Klondike.kd_decode(code)
		m.start
	}) })

	kd_wasm_move_to : I64 -> I64
	kd_wasm_move_to = |code| (if (code < 0) { (-1) } else { ({
		m = Klondike.kd_decode(code)
		m.to
	}) })

	kd_wasm_run : I64, I64 -> Klondike.KlondikeResult
	kd_wasm_run = |seed, draw| Klondike.klondike_run(seed, (if (draw < 1) { 1 } else { (if (draw > 3) { 3 } else { draw }) }))

	kd_wasm_run_founded : Klondike.KlondikeResult -> I64
	kd_wasm_run_founded = |r| r.founded

	kd_wasm_run_moves : Klondike.KlondikeResult -> I64
	kd_wasm_run_moves = |r| r.moves

	kd_wasm_run_won : Klondike.KlondikeResult -> I64
	kd_wasm_run_won = |r| (if r.won { 1 } else { 0 })
}
