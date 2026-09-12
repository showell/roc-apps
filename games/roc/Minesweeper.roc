# Minesweeper -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Rng

Minesweeper :: [].{
	MinesweeperState : { mine_grid : List(I64), revealed : List(I64), adjacent : List(I64), cells_revealed : I64, mines_hit : I64, safe_cells : I64, game_over : Bool, won : Bool, moves : I64, rng : Rng.Rng }
	MinesweeperResult : { won : Bool, cells_revealed : I64, mines_hit : I64, moves : I64 }

	ms_size : I64
	ms_size = 81

	ms_mine_count : I64
	ms_mine_count = 10

	ms_safe_count : I64
	ms_safe_count = 71

	ms_new : Rng.Rng -> Minesweeper.MinesweeperState
	ms_new = |rng| ({
		mine_grid = ms_place_mines(rng, ms_mine_count, ms_fill(0, []))
		adj = ms_build_adjacent(mine_grid, 0, [])
		{ mine_grid: mine_grid, revealed: ms_fill(0, []), adjacent: adj, cells_revealed: 0, mines_hit: 0, safe_cells: ms_safe_count, game_over: False, won: False, moves: 0, rng: rng }
	})

	ms_fill : I64, List(I64) -> List(I64)
	ms_fill = |i, acc| (if (i >= 81) { acc } else { ms_fill((i + 1), List.append(acc, 0)) })

	ms_place_mines : Rng.Rng, I64, List(I64) -> List(I64)
	ms_place_mines = |rng, remaining, grid| (if (remaining <= 0) { grid } else { ({
		r = Rng.rng_next(rng)
		idx = Rng.rng_range(r, 0, 80)
		(if ((List.get(grid, I64.to_u64_wrap(idx)) ?? crash("list-at out of range")) == 1) { ms_place_mines(r, remaining, grid) } else { ms_place_mines(r, (remaining - 1), (List.set(grid, I64.to_u64_wrap(idx), 1) ?? crash("list-set-at past the end"))) })
	}) })

	ms_build_adjacent : List(I64), I64, List(I64) -> List(I64)
	ms_build_adjacent = |mines, i, acc| (if (i >= 81) { acc } else { ({
		row = I64.div_trunc_by(i, 9)
		col = (i - (row * 9))
		count = ms_count_adjacent(mines, row, col)
		ms_build_adjacent(mines, (i + 1), List.append(acc, count))
	}) })

	ms_count_adjacent : List(I64), I64, I64 -> I64
	ms_count_adjacent = |mines, row, col| ({
		n0 = ms_mine_at(mines, (row - 1), (col - 1))
		n1 = ms_mine_at(mines, (row - 1), col)
		n2 = ms_mine_at(mines, (row - 1), (col + 1))
		n3 = ms_mine_at(mines, row, (col - 1))
		n4 = ms_mine_at(mines, row, (col + 1))
		n5 = ms_mine_at(mines, (row + 1), (col - 1))
		n6 = ms_mine_at(mines, (row + 1), col)
		n7 = ms_mine_at(mines, (row + 1), (col + 1))
		(((((((n0 + n1) + n2) + n3) + n4) + n5) + n6) + n7)
	})

	ms_mine_at : List(I64), I64, I64 -> I64
	ms_mine_at = |mines, row, col| (if (row < 0) { 0 } else { (if (row >= 9) { 0 } else { (if (col < 0) { 0 } else { (if (col >= 9) { 0 } else { (List.get(mines, I64.to_u64_wrap(((row * 9) + col))) ?? crash("list-at out of range")) }) }) }) })

	ms_reveal : Minesweeper.MinesweeperState, I64 -> Minesweeper.MinesweeperState
	ms_reveal = |st, idx| (if st.game_over { st } else { (if (idx < 0) { st } else { (if (idx >= 81) { st } else { (if ((List.get(st.revealed, I64.to_u64_wrap(idx)) ?? crash("list-at out of range")) != 0) { st } else { (if ((List.get(st.mine_grid, I64.to_u64_wrap(idx)) ?? crash("list-at out of range")) == 1) { ({
		new_rev = (List.set(st.revealed, I64.to_u64_wrap(idx), 1) ?? crash("list-set-at past the end"))
		new_hits = (st.mines_hit + 1)
		{ mine_grid: st.mine_grid, revealed: new_rev, adjacent: st.adjacent, cells_revealed: st.cells_revealed, mines_hit: new_hits, safe_cells: st.safe_cells, game_over: True, won: False, moves: (st.moves + 1), rng: st.rng }
	}) } else { ({
		new_rev = (List.set(st.revealed, I64.to_u64_wrap(idx), 1) ?? crash("list-set-at past the end"))
		new_count = (st.cells_revealed + 1)
		adj_count = (List.get(st.adjacent, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))
		won = (new_count >= ms_safe_count)
		st2 = { mine_grid: st.mine_grid, revealed: new_rev, adjacent: st.adjacent, cells_revealed: new_count, mines_hit: st.mines_hit, safe_cells: st.safe_cells, game_over: won, won: won, moves: (st.moves + 1), rng: st.rng }
		(if (adj_count == 0) { ms_flood_fill(st2, idx) } else { st2 })
	}) }) }) }) }) })

	ms_flood_fill : Minesweeper.MinesweeperState, I64 -> Minesweeper.MinesweeperState
	ms_flood_fill = |st, idx| ({
		row = I64.div_trunc_by(idx, 9)
		col = (idx - (row * 9))
		st1 = ms_reveal_neighbor(st, row, col, (-1), (-1))
		st2 = ms_reveal_neighbor(st1, row, col, (-1), 0)
		st3 = ms_reveal_neighbor(st2, row, col, (-1), 1)
		st4 = ms_reveal_neighbor(st3, row, col, 0, (-1))
		st5 = ms_reveal_neighbor(st4, row, col, 0, 1)
		st6 = ms_reveal_neighbor(st5, row, col, 1, (-1))
		st7 = ms_reveal_neighbor(st6, row, col, 1, 0)
		ms_reveal_neighbor(st7, row, col, 1, 1)
	})

	ms_reveal_neighbor : Minesweeper.MinesweeperState, I64, I64, I64, I64 -> Minesweeper.MinesweeperState
	ms_reveal_neighbor = |st, row, col, dr, dc| ({
		r2 = (row + dr)
		c2 = (col + dc)
		(if (r2 < 0) { st } else { (if (r2 >= 9) { st } else { (if (c2 < 0) { st } else { (if (c2 >= 9) { st } else { ms_reveal(st, ((r2 * 9) + c2)) }) }) }) })
	})

	ms_ai_pick : Minesweeper.MinesweeperState -> I64
	ms_ai_pick = |st| ({
		safe = ms_find_safe(st.mine_grid, st.adjacent, st.revealed, 0)
		(if (safe >= 0) { safe } else { ms_find_hidden(st.mine_grid, st.revealed, 0) })
	})

	ms_find_safe : List(I64), List(I64), List(I64), I64 -> I64
	ms_find_safe = |mines, adj, revealed, i| (if (i >= 81) { (-1) } else { (if ((List.get(revealed, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != 0) { ms_find_safe(mines, adj, revealed, (i + 1)) } else { (if ((List.get(mines, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == 1) { ms_find_safe(mines, adj, revealed, (i + 1)) } else { (if ((List.get(adj, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == 0) { i } else { ms_find_safe(mines, adj, revealed, (i + 1)) }) }) }) })

	ms_find_hidden : List(I64), List(I64), I64 -> I64
	ms_find_hidden = |mines, revealed, i| (if (i >= 81) { (-1) } else { (if ((List.get(revealed, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != 0) { ms_find_hidden(mines, revealed, (i + 1)) } else { (if ((List.get(mines, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == 1) { ms_find_hidden(mines, revealed, (i + 1)) } else { i }) }) })

	ms_all_revealed : Minesweeper.MinesweeperState -> Bool
	ms_all_revealed = |st| (st.cells_revealed >= ms_safe_count)

	run_minesweeper_game : Minesweeper.MinesweeperResult
	run_minesweeper_game = ({
		rng = Rng.rng_new(33)
		st = ms_new(rng)
		ms_loop(st)
	})

	ms_loop : Minesweeper.MinesweeperState -> Minesweeper.MinesweeperResult
	ms_loop = |st| (if st.game_over { { won: st.won, cells_revealed: st.cells_revealed, mines_hit: st.mines_hit, moves: st.moves } } else { (if (st.moves > 90) { { won: False, cells_revealed: st.cells_revealed, mines_hit: st.mines_hit, moves: st.moves } } else { ({
		idx = ms_ai_pick(st)
		(if (idx < 0) { { won: st.won, cells_revealed: st.cells_revealed, mines_hit: st.mines_hit, moves: st.moves } } else { ({
			next = ms_reveal(st, idx)
			ms_loop(next)
		}) })
	}) }) })

	format_minesweeper_result : Minesweeper.MinesweeperResult -> Str
	format_minesweeper_result = |r| ({
		outcome = (if r.won { "Solved" } else { "Hit mine" })
		Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("Minesweeper: ", outcome), " revealed="), I64.to_str(r.cells_revealed)), " mines-hit="), I64.to_str(r.mines_hit)), " moves="), I64.to_str(r.moves))
	})
}
