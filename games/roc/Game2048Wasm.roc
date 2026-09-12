# Game2048Wasm -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Game2048
import Rng

Game2048Wasm :: [].{

	g2_wasm_new : I64 -> Game2048.G2048State
	g2_wasm_new = |seed| Game2048.g2048_new(Rng.rng_new(seed))

	g2_wasm_cell : Game2048.G2048State, I64 -> I64
	g2_wasm_cell = |st, i| (if (i < 0) { (-1) } else { (if (i >= 16) { (-1) } else { (List.get(st.grid, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) }) })

	g2_wasm_score : Game2048.G2048State -> I64
	g2_wasm_score = |st| st.score

	g2_wasm_moves : Game2048.G2048State -> I64
	g2_wasm_moves = |st| st.moves

	g2_wasm_done : Game2048.G2048State -> I64
	g2_wasm_done = |st| (if st.game_over { 1 } else { 0 })

	g2_wasm_max : Game2048.G2048State -> I64
	g2_wasm_max = |st| Game2048.g2048_max_tile(st.grid)

	g2_wasm_empty : Game2048.G2048State -> I64
	g2_wasm_empty = |st| Game2048.g2048_empty_count(st.grid)

	g2_wasm_sum : Game2048.G2048State -> I64
	g2_wasm_sum = |st| Game2048.g2048_sum_grid(st.grid)

	g2_wasm_can : Game2048.G2048State, I64 -> I64
	g2_wasm_can = |st, dir| (if (dir < 0) { 0 } else { (if (dir > 3) { 0 } else { (if st.game_over { 0 } else { ({
		after = Game2048.g2048_apply_dir(Game2048.g2048_copy_grid(st.grid), dir)
		(if Game2048.g2048_grids_equal(st.grid, after) { 0 } else { 1 })
	}) }) }) })

	g2_wasm_move : Game2048.G2048State, I64 -> Game2048.G2048State
	g2_wasm_move = |st, dir| (if (dir < 0) { st } else { (if (dir > 3) { st } else { (if st.game_over { st } else { Game2048.g2048_move({ grid: Game2048.g2048_copy_grid(st.grid), score: st.score, moves: st.moves, game_over: st.game_over, rng: st.rng }, dir) }) }) })

	g2_wasm_ai : Game2048.G2048State -> I64
	g2_wasm_ai = |st| (if st.game_over { (-1) } else { Game2048.g2048_ai_dir(st) })
}
