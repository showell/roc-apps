# Minesweeper as a Roc app on the games platform (../wasm/minesweeper/platform):
# the emitted engine behind one boxed state. Hand-written; the seam.
#
# A message is a cell: 0..80 reveals it; 81 lets the engine's AI pick, and
# it only opens a square it can prove safe. `view` answers 81 words, one
# per cell, packed mine | shown << 1 | adjacent << 2, then the counters:
# revealed, mines hit, moves, done, won, safe cells. The mine grid goes to
# the page because a lost game shows where the mines were; the page draws
# a hidden cell hidden.
app [Model, program] { pf: platform "../wasm/minesweeper/platform/main.roc" }

import Minesweeper
import MinesweeperWasm

Model : Minesweeper.MinesweeperState

init : I64 -> Box(Model)
init = |seed| Box.box(MinesweeperWasm.ms_wasm_new(seed))

step : Box(Model), I64 -> Box(Model)
step = |boxed, msg| {
	st = Box.unbox(boxed)
	if msg >= 0 and msg <= 80 {
		Box.box(MinesweeperWasm.ms_wasm_reveal(st, msg))
	} else if msg == 81 {
		i = MinesweeperWasm.ms_wasm_ai(st)
		Box.box(if i < 0 { st } else { MinesweeperWasm.ms_wasm_reveal(st, i) })
	} else {
		Box.box(st)
	}
}

cells : List(I64)
cells = List.map([0, 1, 2, 3, 4, 5, 6, 7, 8], |r| List.map([0, 1, 2, 3, 4, 5, 6, 7, 8], |c| r * 9 + c)) |> List.join

view : Box(Model) -> List(U32)
view = |boxed| {
	st = Box.unbox(boxed)
	packed = List.map(cells, |i|
		I64.to_u32_wrap(MinesweeperWasm.ms_wasm_mine(st, i) + MinesweeperWasm.ms_wasm_revealed(st, i) * 2 + MinesweeperWasm.ms_wasm_adjacent(st, i) * 4))
	List.concat(packed, List.map([
		MinesweeperWasm.ms_wasm_count(st),
		MinesweeperWasm.ms_wasm_hits(st),
		MinesweeperWasm.ms_wasm_moves(st),
		MinesweeperWasm.ms_wasm_done(st),
		MinesweeperWasm.ms_wasm_won(st),
		MinesweeperWasm.ms_wasm_safe(st),
	], |v| I64.to_u32_wrap(v)))
}

# The grader's door, one per export.
mine : Box(Model), I64 -> I64
mine = |boxed, i| MinesweeperWasm.ms_wasm_mine(Box.unbox(boxed), i)
shown : Box(Model), I64 -> I64
shown = |boxed, i| MinesweeperWasm.ms_wasm_revealed(Box.unbox(boxed), i)
adj : Box(Model), I64 -> I64
adj = |boxed, i| MinesweeperWasm.ms_wasm_adjacent(Box.unbox(boxed), i)
count : Box(Model) -> I64
count = |boxed| MinesweeperWasm.ms_wasm_count(Box.unbox(boxed))
hits : Box(Model) -> I64
hits = |boxed| MinesweeperWasm.ms_wasm_hits(Box.unbox(boxed))
moves : Box(Model) -> I64
moves = |boxed| MinesweeperWasm.ms_wasm_moves(Box.unbox(boxed))
done : Box(Model) -> I64
done = |boxed| MinesweeperWasm.ms_wasm_done(Box.unbox(boxed))
won : Box(Model) -> I64
won = |boxed| MinesweeperWasm.ms_wasm_won(Box.unbox(boxed))
safe : Box(Model) -> I64
safe = |boxed| MinesweeperWasm.ms_wasm_safe(Box.unbox(boxed))
open : Box(Model), I64 -> Box(Model)
open = |boxed, i| Box.box(MinesweeperWasm.ms_wasm_reveal(Box.unbox(boxed), i))
ai : Box(Model) -> I64
ai = |boxed| MinesweeperWasm.ms_wasm_ai(Box.unbox(boxed))

drop : Box(Model) -> {}
drop = |boxed| {
	_st = Box.unbox(boxed)
	{}
}

program = { init, step, view, mine, shown, adj, count, hits, moves, done, won, safe, open, ai, drop }
