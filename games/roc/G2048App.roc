# 2048 as a Roc app on the games platform (../wasm/platform): the emitted
# engine (Game2048, Game2048Wasm, Rng) behind one boxed state.
#
# Hand-written; the seam between the browser and the generated Roc. The
# page turns an event into a MESSAGE, one small integer, and `step` is the
# only door: 0..3 slide up, right, down, left (Damian's numbering), 4 lets
# the engine's AI pick. `view` answers the board as words: the sixteen
# tiles, then score, moves, done, best tile, empty cells and the grid sum.
# The rest of the record are the shell's own queries, one per export, for
# Damian's grader (apps/games/g2-verify.mjs) to drive by handle.
app [Model, program] { pf: platform "../wasm/2048/platform/main.roc" }

import Game2048
import Game2048Wasm

Model : Game2048.G2048State

init : I64 -> Box(Model)
init = |seed| Box.box(Game2048Wasm.g2_wasm_new(seed))

new : I64 -> Box(Model)
new = init

# A refused transition answers the state it was given; the host asks.
same : Box(Model), Box(Model) -> I64
same = |a, b| if Box.unbox(a) == Box.unbox(b) { 1 } else { 0 }

step : Box(Model), I64 -> Box(Model)
step = |boxed, msg| {
	st = Box.unbox(boxed)
	if msg >= 0 and msg <= 3 {
		Box.box(Game2048Wasm.g2_wasm_move(st, msg))
	} else if msg == 4 {
		d = Game2048Wasm.g2_wasm_ai(st)
		Box.box(if d < 0 { st } else { Game2048Wasm.g2_wasm_move(st, d) })
	} else {
		Box.box(st)
	}
}

view : Box(Model) -> List(U32)
view = |boxed| {
	st = Box.unbox(boxed)
	cells = List.map([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], |i| I64.to_u32_wrap(Game2048Wasm.g2_wasm_cell(st, i)))
	List.concat(cells, List.map([
		Game2048Wasm.g2_wasm_score(st),
		Game2048Wasm.g2_wasm_moves(st),
		Game2048Wasm.g2_wasm_done(st),
		Game2048Wasm.g2_wasm_max(st),
		Game2048Wasm.g2_wasm_empty(st),
		Game2048Wasm.g2_wasm_sum(st),
	], |v| I64.to_u32_wrap(v)))
}

# The grader's move is the shell's alone: a direction, or nothing. The
# page's messages (an AI move is 4) are not its business.
move : Box(Model), I64 -> Box(Model)
move = |boxed, d| Box.box(Game2048Wasm.g2_wasm_move(Box.unbox(boxed), d))

cell : Box(Model), I64 -> I64
cell = |boxed, i| Game2048Wasm.g2_wasm_cell(Box.unbox(boxed), i)
score : Box(Model) -> I64
score = |boxed| Game2048Wasm.g2_wasm_score(Box.unbox(boxed))
moves : Box(Model) -> I64
moves = |boxed| Game2048Wasm.g2_wasm_moves(Box.unbox(boxed))
done : Box(Model) -> I64
done = |boxed| Game2048Wasm.g2_wasm_done(Box.unbox(boxed))
max : Box(Model) -> I64
max = |boxed| Game2048Wasm.g2_wasm_max(Box.unbox(boxed))
empty : Box(Model) -> I64
empty = |boxed| Game2048Wasm.g2_wasm_empty(Box.unbox(boxed))
sum : Box(Model) -> I64
sum = |boxed| Game2048Wasm.g2_wasm_sum(Box.unbox(boxed))
can : Box(Model), I64 -> I64
can = |boxed, d| Game2048Wasm.g2_wasm_can(Box.unbox(boxed), d)
ai : Box(Model) -> I64
ai = |boxed| Game2048Wasm.g2_wasm_ai(Box.unbox(boxed))

# The host hands a model back to be freed: taking the box and answering
# nothing is what frees it.
drop : Box(Model) -> {}
drop = |boxed| {
	_st = Box.unbox(boxed)
	{}
}

program = { init, step, view, new, move, cell, score, moves, done, max, empty, sum, can, ai, drop, same }
