# Game2048 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import Rng

Game2048 :: [].{
	G2048State := { grid : List(I64), score : I64, moves : I64, game_over : Bool, rng : Rng.Rng }.{
		is_eq : Game2048.G2048State, Game2048.G2048State -> Bool
		is_eq = |a, b| eq_G2048State(a, b)
	}
	G2048Result := { max_tile : I64, score : I64, moves : I64 }.{
		is_eq : Game2048.G2048Result, Game2048.G2048Result -> Bool
		is_eq = |a, b| eq_G2048Result(a, b)
	}

	g2048_new : Rng.Rng -> Game2048.G2048State
	g2048_new = |rng| ({
		grid : List(I64)
		grid = g2048_fill(0, [])
		r1 = Rng.rng_next(rng)
		g2048_add_tile_v1 : List(I64)
		g2048_add_tile_v1 = g2048_add_tile(grid, r1)
		g1 : List(I64)
		g1 = g2048_add_tile_v1
		r2 = Rng.rng_next(r1)
		g2048_add_tile_v2 : List(I64)
		g2048_add_tile_v2 = g2048_add_tile(g1, r2)
		g2 : List(I64)
		g2 = g2048_add_tile_v2
		Game2048.G2048State.{ grid: g2, score: 0, moves: 0, game_over: False, rng: r2 }
	})

	g2048_fill : I64, List(I64) -> List(I64)
	g2048_fill = |i, acc| (if (i >= 16) { acc } else { g2048_fill((i + 1), List.append(acc, 0)) })

	g2048_add_tile : List(I64), Rng.Rng -> List(I64)
	g2048_add_tile = |grid, rng| ({
		idx : I64
		idx = g2048_random_empty(grid, rng)
		(if (idx < 0) { grid } else { ({
			r2 = Rng.rng_next(rng)
			val : I64
			val = (if (Rng.rng_mod(Rng.rng_value(r2), 4) == 0) { 4 } else { 2 })
			(List.set(grid, I64.to_u64_wrap(idx), val) ?? crash("list-set-at past the end"))
		}) })
	})

	g2048_random_empty : List(I64), Rng.Rng -> I64
	g2048_random_empty = |grid, rng| ({
		count : I64
		count = g2048_count_empty(grid, 0, 0)
		(if (count == 0) { (-1) } else { ({
			r = Rng.rng_next(rng)
			pick : I64
			pick = Rng.rng_range(r, 0, (count - 1))
			g2048_nth_empty(grid, 0, pick, 0)
		}) })
	})

	g2048_count_empty : List(I64), I64, I64 -> I64
	g2048_count_empty = |grid, i, acc| (if (i >= 16) { acc } else { (if ((List.get(grid, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == 0) { g2048_count_empty(grid, (i + 1), (acc + 1)) } else { g2048_count_empty(grid, (i + 1), acc) }) })

	g2048_nth_empty : List(I64), I64, I64, I64 -> I64
	g2048_nth_empty = |grid, i, target, seen| (if (i >= 16) { (-1) } else { (if ((List.get(grid, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != 0) { g2048_nth_empty(grid, (i + 1), target, seen) } else { (if (seen == target) { i } else { g2048_nth_empty(grid, (i + 1), target, (seen + 1)) }) }) })

	g2048_slide_row_left : List(I64) -> List(I64)
	g2048_slide_row_left = |row| ({
		compacted : List(I64)
		compacted = g2048_compact(row, 0, [])
		merged : List(I64)
		merged = g2048_merge(compacted)
		g2048_pad(merged)
	})

	g2048_compact : List(I64), I64, List(I64) -> List(I64)
	g2048_compact = |row, i, acc| (if (i >= 4) { acc } else { (if ((List.get(row, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != 0) { g2048_compact(row, (i + 1), List.append(acc, (List.get(row, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) } else { g2048_compact(row, (i + 1), acc) }) })

	g2048_merge : List(I64) -> List(I64)
	g2048_merge = |row| g2048_merge_loop(row, 0, [])

	g2048_merge_loop : List(I64), I64, List(I64) -> List(I64)
	g2048_merge_loop = |row, i, acc| (if (i >= U64.to_i64_wrap(List.len(row))) { acc } else { (if ((i + 1) < U64.to_i64_wrap(List.len(row))) { (if ((List.get(row, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == (List.get(row, I64.to_u64_wrap((i + 1))) ?? crash("list-at out of range"))) { g2048_merge_loop(row, (i + 2), List.append(acc, ((List.get(row, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * 2))) } else { g2048_merge_loop(row, (i + 1), List.append(acc, (List.get(row, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) }) } else { g2048_merge_loop(row, (i + 1), List.append(acc, (List.get(row, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) }) })

	g2048_pad : List(I64) -> List(I64)
	g2048_pad = |row| g2048_pad_loop(row)

	g2048_pad_loop : List(I64) -> List(I64)
	g2048_pad_loop = |row| (if (U64.to_i64_wrap(List.len(row)) >= 4) { row } else { g2048_pad_loop(List.append(row, 0)) })

	g2048_reverse_row : List(I64) -> List(I64)
	g2048_reverse_row = |row| [(List.get(row, I64.to_u64_wrap(3)) ?? crash("list-at out of range")), (List.get(row, I64.to_u64_wrap(2)) ?? crash("list-at out of range")), (List.get(row, I64.to_u64_wrap(1)) ?? crash("list-at out of range")), (List.get(row, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))]

	g2048_slide_row_right : List(I64) -> List(I64)
	g2048_slide_row_right = |row| g2048_reverse_row(g2048_slide_row_left(g2048_reverse_row(row)))

	g2048_get_row : List(I64), I64 -> List(I64)
	g2048_get_row = |grid, row| [(List.get(grid, I64.to_u64_wrap((row * 4))) ?? crash("list-at out of range")), (List.get(grid, I64.to_u64_wrap(((row * 4) + 1))) ?? crash("list-at out of range")), (List.get(grid, I64.to_u64_wrap(((row * 4) + 2))) ?? crash("list-at out of range")), (List.get(grid, I64.to_u64_wrap(((row * 4) + 3))) ?? crash("list-at out of range"))]

	g2048_set_row : List(I64), I64, List(I64) -> List(I64)
	g2048_set_row = |grid, row, r| ({
		grid_v1 : List(I64)
		grid_v1 = (List.set(grid, I64.to_u64_wrap((row * 4)), (List.get(r, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))) ?? crash("list-set-at past the end"))
		g1 : List(I64)
		g1 = grid_v1
		grid_v2 : List(I64)
		grid_v2 = (List.set(g1, I64.to_u64_wrap(((row * 4) + 1)), (List.get(r, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))) ?? crash("list-set-at past the end"))
		g2 : List(I64)
		g2 = grid_v2
		grid_v3 : List(I64)
		grid_v3 = (List.set(g2, I64.to_u64_wrap(((row * 4) + 2)), (List.get(r, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))) ?? crash("list-set-at past the end"))
		g3 : List(I64)
		g3 = grid_v3
		(List.set(g3, I64.to_u64_wrap(((row * 4) + 3)), (List.get(r, I64.to_u64_wrap(3)) ?? crash("list-at out of range"))) ?? crash("list-set-at past the end"))
	})

	g2048_get_col : List(I64), I64 -> List(I64)
	g2048_get_col = |grid, col| [(List.get(grid, I64.to_u64_wrap(col)) ?? crash("list-at out of range")), (List.get(grid, I64.to_u64_wrap((4 + col))) ?? crash("list-at out of range")), (List.get(grid, I64.to_u64_wrap((8 + col))) ?? crash("list-at out of range")), (List.get(grid, I64.to_u64_wrap((12 + col))) ?? crash("list-at out of range"))]

	g2048_set_col : List(I64), I64, List(I64) -> List(I64)
	g2048_set_col = |grid, col, c| ({
		grid_v1 : List(I64)
		grid_v1 = (List.set(grid, I64.to_u64_wrap(col), (List.get(c, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))) ?? crash("list-set-at past the end"))
		g1 : List(I64)
		g1 = grid_v1
		grid_v2 : List(I64)
		grid_v2 = (List.set(g1, I64.to_u64_wrap((4 + col)), (List.get(c, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))) ?? crash("list-set-at past the end"))
		g2 : List(I64)
		g2 = grid_v2
		grid_v3 : List(I64)
		grid_v3 = (List.set(g2, I64.to_u64_wrap((8 + col)), (List.get(c, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))) ?? crash("list-set-at past the end"))
		g3 : List(I64)
		g3 = grid_v3
		(List.set(g3, I64.to_u64_wrap((12 + col)), (List.get(c, I64.to_u64_wrap(3)) ?? crash("list-at out of range"))) ?? crash("list-set-at past the end"))
	})

	g2048_copy_grid : List(I64) -> List(I64)
	g2048_copy_grid = |grid| g2048_copy_loop(grid, 0, [])

	g2048_copy_loop : List(I64), I64, List(I64) -> List(I64)
	g2048_copy_loop = |grid, i, acc| (if (i >= 16) { acc } else { g2048_copy_loop(grid, (i + 1), List.append(acc, (List.get(grid, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	g2048_slide_left : List(I64) -> List(I64)
	g2048_slide_left = |grid| ({
		c : List(I64)
		c = g2048_copy_grid(grid)
		g2048_set_row_v1 : List(I64)
		g2048_set_row_v1 = g2048_set_row(c, 0, g2048_slide_row_left(g2048_get_row(c, 0)))
		g1 : List(I64)
		g1 = g2048_set_row_v1
		g2048_set_row_v2 : List(I64)
		g2048_set_row_v2 = g2048_set_row(g1, 1, g2048_slide_row_left(g2048_get_row(g1, 1)))
		g2 : List(I64)
		g2 = g2048_set_row_v2
		g2048_set_row_v3 : List(I64)
		g2048_set_row_v3 = g2048_set_row(g2, 2, g2048_slide_row_left(g2048_get_row(g2, 2)))
		g3 : List(I64)
		g3 = g2048_set_row_v3
		g2048_set_row(g3, 3, g2048_slide_row_left(g2048_get_row(g3, 3)))
	})

	g2048_slide_right : List(I64) -> List(I64)
	g2048_slide_right = |grid| ({
		c : List(I64)
		c = g2048_copy_grid(grid)
		g2048_set_row_v1 : List(I64)
		g2048_set_row_v1 = g2048_set_row(c, 0, g2048_slide_row_right(g2048_get_row(c, 0)))
		g1 : List(I64)
		g1 = g2048_set_row_v1
		g2048_set_row_v2 : List(I64)
		g2048_set_row_v2 = g2048_set_row(g1, 1, g2048_slide_row_right(g2048_get_row(g1, 1)))
		g2 : List(I64)
		g2 = g2048_set_row_v2
		g2048_set_row_v3 : List(I64)
		g2048_set_row_v3 = g2048_set_row(g2, 2, g2048_slide_row_right(g2048_get_row(g2, 2)))
		g3 : List(I64)
		g3 = g2048_set_row_v3
		g2048_set_row(g3, 3, g2048_slide_row_right(g2048_get_row(g3, 3)))
	})

	g2048_slide_up : List(I64) -> List(I64)
	g2048_slide_up = |grid| ({
		c : List(I64)
		c = g2048_copy_grid(grid)
		g2048_set_col_v1 : List(I64)
		g2048_set_col_v1 = g2048_set_col(c, 0, g2048_slide_row_left(g2048_get_col(c, 0)))
		g1 : List(I64)
		g1 = g2048_set_col_v1
		g2048_set_col_v2 : List(I64)
		g2048_set_col_v2 = g2048_set_col(g1, 1, g2048_slide_row_left(g2048_get_col(g1, 1)))
		g2 : List(I64)
		g2 = g2048_set_col_v2
		g2048_set_col_v3 : List(I64)
		g2048_set_col_v3 = g2048_set_col(g2, 2, g2048_slide_row_left(g2048_get_col(g2, 2)))
		g3 : List(I64)
		g3 = g2048_set_col_v3
		g2048_set_col(g3, 3, g2048_slide_row_left(g2048_get_col(g3, 3)))
	})

	g2048_slide_down : List(I64) -> List(I64)
	g2048_slide_down = |grid| ({
		c : List(I64)
		c = g2048_copy_grid(grid)
		g2048_set_col_v1 : List(I64)
		g2048_set_col_v1 = g2048_set_col(c, 0, g2048_slide_row_right(g2048_get_col(c, 0)))
		g1 : List(I64)
		g1 = g2048_set_col_v1
		g2048_set_col_v2 : List(I64)
		g2048_set_col_v2 = g2048_set_col(g1, 1, g2048_slide_row_right(g2048_get_col(g1, 1)))
		g2 : List(I64)
		g2 = g2048_set_col_v2
		g2048_set_col_v3 : List(I64)
		g2048_set_col_v3 = g2048_set_col(g2, 2, g2048_slide_row_right(g2048_get_col(g2, 2)))
		g3 : List(I64)
		g3 = g2048_set_col_v3
		g2048_set_col(g3, 3, g2048_slide_row_right(g2048_get_col(g3, 3)))
	})

	g2048_apply_dir : List(I64), I64 -> List(I64)
	g2048_apply_dir = |grid, dir| (if (dir == 0) { g2048_slide_left(grid) } else { (if (dir == 1) { g2048_slide_right(grid) } else { (if (dir == 2) { g2048_slide_up(grid) } else { g2048_slide_down(grid) }) }) })

	g2048_grids_equal : List(I64), List(I64) -> Bool
	g2048_grids_equal = |a, b| g2048_eq_loop(a, b, 0)

	g2048_eq_loop : List(I64), List(I64), I64 -> Bool
	g2048_eq_loop = |a, b, i| (if (i >= 16) { True } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) != (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { False } else { g2048_eq_loop(a, b, (i + 1)) }) })

	g2048_max_tile : List(I64) -> I64
	g2048_max_tile = |grid| g2048_max_loop(grid, 0, 0)

	g2048_max_loop : List(I64), I64, I64 -> I64
	g2048_max_loop = |grid, i, best| (if (i >= 16) { best } else { ({
		v : I64
		v = (List.get(grid, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (v > best) { g2048_max_loop(grid, (i + 1), v) } else { g2048_max_loop(grid, (i + 1), best) })
	}) })

	g2048_empty_count : List(I64) -> I64
	g2048_empty_count = |grid| g2048_count_empty(grid, 0, 0)

	g2048_sum_grid : List(I64) -> I64
	g2048_sum_grid = |grid| g2048_sum_loop(grid, 0, 0)

	g2048_sum_loop : List(I64), I64, I64 -> I64
	g2048_sum_loop = |grid, i, acc| (if (i >= 16) { acc } else { g2048_sum_loop(grid, (i + 1), (acc + (List.get(grid, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	g2048_ai_dir : Game2048.G2048State -> I64
	g2048_ai_dir = |st| ({
		s0 : I64
		s0 = g2048_eval_dir(st.grid, 0)
		s1 : I64
		s1 = g2048_eval_dir(st.grid, 1)
		s2 : I64
		s2 = g2048_eval_dir(st.grid, 2)
		s3 : I64
		s3 = g2048_eval_dir(st.grid, 3)
		g2048_best_dir(s0, s1, s2, s3)
	})

	g2048_eval_dir : List(I64), I64 -> I64
	g2048_eval_dir = |grid, dir| ({
		after : List(I64)
		after = g2048_apply_dir(grid, dir)
		(if g2048_grids_equal(grid, after) { (-1) } else { ((g2048_empty_count(after) * 16) + g2048_max_tile(after)) })
	})

	g2048_best_dir : I64, I64, I64, I64 -> I64
	g2048_best_dir = |s0, s1, s2, s3| ({
		best01 : I64
		best01 = (if (s0 >= s1) { 0 } else { 1 })
		best23 : I64
		best23 = (if (s2 >= s3) { 2 } else { 3 })
		v01 : I64
		v01 = (if (best01 == 0) { s0 } else { s1 })
		v23 : I64
		v23 = (if (best23 == 2) { s2 } else { s3 })
		(if (v01 >= v23) { best01 } else { best23 })
	})

	g2048_can_move : List(I64) -> Bool
	g2048_can_move = |grid| ({
		after_l : List(I64)
		after_l = g2048_slide_left(grid)
		(if (g2048_grids_equal(grid, after_l) == False) { True } else { ({
			after_r : List(I64)
			after_r = g2048_slide_right(grid)
			(if (g2048_grids_equal(grid, after_r) == False) { True } else { ({
				after_u : List(I64)
				after_u = g2048_slide_up(grid)
				(if (g2048_grids_equal(grid, after_u) == False) { True } else { ({
					after_d : List(I64)
					after_d = g2048_slide_down(grid)
					(g2048_grids_equal(grid, after_d) == False)
				}) })
			}) })
		}) })
	})

	g2048_move : Game2048.G2048State, I64 -> Game2048.G2048State
	g2048_move = |st, dir| (if (dir < 0) { Game2048.G2048State.{ grid: st.grid, score: st.score, moves: st.moves, game_over: True, rng: st.rng } } else { ({
		after : List(I64)
		after = g2048_apply_dir(st.grid, dir)
		copyout_v2 = (if g2048_grids_equal(st.grid, after) { (st, after) } else { ({
			r = Rng.rng_next(st.rng)
			g2048_add_tile_v1 : List(I64)
			g2048_add_tile_v1 = g2048_add_tile(after, r)
			new_grid : List(I64)
			new_grid = g2048_add_tile_v1
			new_score : I64
			new_score = (st.score + g2048_dir_gain(st.grid, dir))
			can : Bool
			can = g2048_can_move(new_grid)
			(Game2048.G2048State.{ grid: new_grid, score: new_score, moves: (st.moves + 1), game_over: (can == False), rng: r }, new_grid)
		}) })
		_after_v3 = copyout_v2.1
		copyout_v2.0
	}) })

	g2048_dir_gain : List(I64), I64 -> I64
	g2048_dir_gain = |grid, dir| g2048_gain_lines(grid, (dir >= 2), 0, 0)

	g2048_gain_lines : List(I64), Bool, I64, I64 -> I64
	g2048_gain_lines = |grid, cols, k, acc| (if (k >= 4) { acc } else { g2048_gain_lines(grid, cols, (k + 1), (acc + g2048_line_gain(g2048_compact(g2048_line(grid, cols, k), 0, []), 0, 0))) })

	g2048_line : List(I64), Bool, I64 -> List(I64)
	g2048_line = |grid, cols, k| (if cols { [(List.get(grid, I64.to_u64_wrap(k)) ?? crash("list-at out of range")), (List.get(grid, I64.to_u64_wrap((4 + k))) ?? crash("list-at out of range")), (List.get(grid, I64.to_u64_wrap((8 + k))) ?? crash("list-at out of range")), (List.get(grid, I64.to_u64_wrap((12 + k))) ?? crash("list-at out of range"))] } else { [(List.get(grid, I64.to_u64_wrap((k * 4))) ?? crash("list-at out of range")), (List.get(grid, I64.to_u64_wrap(((k * 4) + 1))) ?? crash("list-at out of range")), (List.get(grid, I64.to_u64_wrap(((k * 4) + 2))) ?? crash("list-at out of range")), (List.get(grid, I64.to_u64_wrap(((k * 4) + 3))) ?? crash("list-at out of range"))] })

	g2048_line_gain : List(I64), I64, I64 -> I64
	g2048_line_gain = |row, i, acc| (if ((i + 1) >= U64.to_i64_wrap(List.len(row))) { acc } else { (if ((List.get(row, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == (List.get(row, I64.to_u64_wrap((i + 1))) ?? crash("list-at out of range"))) { g2048_line_gain(row, (i + 2), (acc + ((List.get(row, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * 2))) } else { g2048_line_gain(row, (i + 1), acc) }) })

	run_2048_game : Game2048.G2048Result
	run_2048_game = ({
		rng = Rng.rng_new(11)
		st = g2048_new(rng)
		g2048_loop(st)
	})

	g2048_loop : Game2048.G2048State -> Game2048.G2048Result
	g2048_loop = |st| (if st.game_over { Game2048.G2048Result.{ max_tile: g2048_max_tile(st.grid), score: st.score, moves: st.moves } } else { (if (st.moves > 2000) { Game2048.G2048Result.{ max_tile: g2048_max_tile(st.grid), score: st.score, moves: st.moves } } else { ({
		dir : I64
		dir = g2048_ai_dir(st)
		next = g2048_move(st, dir)
		g2048_loop(next)
	}) }) })

	format_2048_result : Game2048.G2048Result -> CceText
	format_2048_result = |r| CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("2048: max-tile=", CceText.show_int(r.max_tile)), " score="), CceText.show_int(r.score)), " moves="), CceText.show_int(r.moves))

	eq_G2048State : Game2048.G2048State, Game2048.G2048State -> Bool
	eq_G2048State = |ex, ey| (((((ex.grid == ey.grid) and (ex.score == ey.score)) and (ex.moves == ey.moves)) and (ex.game_over == ey.game_over)) and Rng.eq_Rng(ex.rng, ey.rng))

	eq_G2048Result : Game2048.G2048Result, Game2048.G2048Result -> Bool
	eq_G2048Result = |ex, ey| (((ex.max_tile == ey.max_tile) and (ex.score == ey.score)) and (ex.moves == ey.moves))
}
