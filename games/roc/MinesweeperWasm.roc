# MinesweeperWasm -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Minesweeper
import Rng

MinesweeperWasm :: [].{

	ms_copy_grid : List(I64), I64, List(I64) -> List(I64)
	ms_copy_grid = |src, i, acc| (if (i >= 81) { acc } else { ms_copy_grid(src, (i + 1), List.append(acc, (List.get(src, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	ms_copy_state : Minesweeper.MinesweeperState -> Minesweeper.MinesweeperState
	ms_copy_state = |st| { mine_grid: st.mine_grid, revealed: ms_copy_grid(st.revealed, 0, []), adjacent: st.adjacent, cells_revealed: st.cells_revealed, mines_hit: st.mines_hit, safe_cells: st.safe_cells, game_over: st.game_over, won: st.won, moves: st.moves, rng: st.rng }

	ms_wasm_new : I64 -> Minesweeper.MinesweeperState
	ms_wasm_new = |seed| Minesweeper.ms_new(Rng.rng_new(seed))

	ms_wasm_mine : Minesweeper.MinesweeperState, I64 -> I64
	ms_wasm_mine = |st, i| (if (i < 0) { (-1) } else { (if (i >= 81) { (-1) } else { (List.get(st.mine_grid, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) }) })

	ms_wasm_revealed : Minesweeper.MinesweeperState, I64 -> I64
	ms_wasm_revealed = |st, i| (if (i < 0) { (-1) } else { (if (i >= 81) { (-1) } else { (List.get(st.revealed, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) }) })

	ms_wasm_adjacent : Minesweeper.MinesweeperState, I64 -> I64
	ms_wasm_adjacent = |st, i| (if (i < 0) { (-1) } else { (if (i >= 81) { (-1) } else { (List.get(st.adjacent, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) }) })

	ms_wasm_count : Minesweeper.MinesweeperState -> I64
	ms_wasm_count = |st| st.cells_revealed

	ms_wasm_hits : Minesweeper.MinesweeperState -> I64
	ms_wasm_hits = |st| st.mines_hit

	ms_wasm_moves : Minesweeper.MinesweeperState -> I64
	ms_wasm_moves = |st| st.moves

	ms_wasm_done : Minesweeper.MinesweeperState -> I64
	ms_wasm_done = |st| (if st.game_over { 1 } else { 0 })

	ms_wasm_won : Minesweeper.MinesweeperState -> I64
	ms_wasm_won = |st| (if st.won { 1 } else { 0 })

	ms_wasm_safe : Minesweeper.MinesweeperState -> I64
	ms_wasm_safe = |st| st.safe_cells

	ms_wasm_reveal : Minesweeper.MinesweeperState, I64 -> Minesweeper.MinesweeperState
	ms_wasm_reveal = |st, i| (if st.game_over { st } else { (if (i < 0) { st } else { (if (i >= 81) { st } else { (if ((List.get(st.revealed, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != 0) { st } else { Minesweeper.ms_reveal(ms_copy_state(st), i) }) }) }) })

	ms_wasm_ai : Minesweeper.MinesweeperState -> I64
	ms_wasm_ai = |st| (if st.game_over { (-1) } else { Minesweeper.ms_ai_pick(st) })
}
