# Klondike as a Roc app on the games platform (../wasm/klondike/platform):
# the emitted engine behind one boxed model. Hand-written; the seam.
#
# THE SELECTION LIVES HERE, NOT IN THE PAGE. A Klondike move is a source, a
# start inside it and a destination, and the player names it with two
# clicks; the page sends each click as a message and this decides whether
# it lifts, drops, re-lifts or clears, the way apps/landing/web/games/
# arcade.js's descriptor does, so the page draws and nothing else.
#
# Messages: 100*c + i clicks card i of column c (i = 99 clicks the column
# itself, empty or its base); 700 the stock; 701 the waste; 710 + f a
# foundation; 720 asks the engine's AI for one step; 721 clears the
# selection; 722 and 723 redeal the same seed turning one or three; 724
# deals the next seed.
#
# The model also carries a finished run, for the grader's kd_run family:
# a handle is either kind, and the queries read the field they mean.
app [Model, program] { pf: platform "../wasm/klondike/platform/main.roc" }

import Klondike
import KlondikeWasm

Model : { st : Klondike.KlondikeState, sel : I64, start : I64, seed : I64, result : Klondike.KlondikeResult }

game : Klondike.KlondikeState, I64 -> Model
game = |st, seed| { st: st, sel: -1, start: 0, seed: seed, result: { founded: 0, moves: 0, won: False } }

init : I64 -> Box(Model)
init = |seed| Box.box(game(KlondikeWasm.kd_wasm_new(seed, 1), seed))

new : I64, I64 -> Box(Model)
new = |seed, turn| Box.box(game(KlondikeWasm.kd_wasm_new(seed, turn), seed))

same : Box(Model), Box(Model) -> I64
same = |a, b| if Box.unbox(a) == Box.unbox(b) { 1 } else { 0 }

# ---- the page's door --------------------------------------------------------

# The start of the largest run a column will give up as one piece: face up,
# descending, alternating, reaching the end (arcade.js kdRunStart).
run_start : Klondike.KlondikeState, I64, I64 -> I64
run_start = |st, c, n| run_start_from(st, c, n, n - 1, KlondikeWasm.kd_wasm_down(st, c))

run_start_from : Klondike.KlondikeState, I64, I64, I64, I64 -> I64
run_start_from = |st, c, n, s, d|
	if s > d and KlondikeWasm.kd_wasm_run_len(st, c, s - 1) == n - (s - 1) { run_start_from(st, c, n, s - 1, d) } else { s }

# What a click names as a source, if it can be lifted.
lift : Model, I64 -> Model
lift = |m, msg|
	if msg == 701 {
		if KlondikeWasm.kd_wasm_waste_size(m.st) > 0 { { ..m, sel: 7, start: 0 } } else { { ..m, sel: -1 } }
	} else if msg >= 710 and msg <= 713 {
		f = msg - 710
		if KlondikeWasm.kd_wasm_found(m.st, f) >= 0 { { ..m, sel: 8 + f, start: 0 } } else { { ..m, sel: -1 } }
	} else if msg >= 0 and msg < 700 {
		c = I64.div_trunc_by(msg, 100)
		idx = I64.rem_by(msg, 100)
		n = KlondikeWasm.kd_wasm_col_size(m.st, c)
		if n == 0 { { ..m, sel: -1 } } else {
			from = run_start(m.st, c, n)
			start = if idx == 99 { from } else { idx }
			if start < from or start >= n { { ..m, sel: -1 } }
			else if KlondikeWasm.kd_wasm_card(m.st, c, start) < 0 { { ..m, sel: -1 } }
			else { { ..m, sel: c, start: start } }
		}
	} else { { ..m, sel: -1 } }

# What a click names as a destination: a column, a foundation, or nowhere.
target : I64 -> I64
target = |msg|
	if msg >= 0 and msg < 700 { I64.div_trunc_by(msg, 100) }
	else if msg >= 710 and msg <= 713 { 7 + (msg - 710) }
	else { -1 }

moved : Model, Klondike.KlondikeState -> Model
moved = |m, st| { ..m, st: st, sel: -1, start: 0 }

step : Box(Model), I64 -> Box(Model)
step = |boxed, msg| {
	m = Box.unbox(boxed)
	Box.box(
		if msg == 700 {
			if KlondikeWasm.kd_wasm_can_draw(m.st) == 1 { moved(m, KlondikeWasm.kd_wasm_draw(m.st)) }
			else if KlondikeWasm.kd_wasm_can_recycle(m.st) == 1 { moved(m, KlondikeWasm.kd_wasm_recycle(m.st)) }
			else { m }
		} else if msg == 720 {
			code = KlondikeWasm.kd_wasm_ai(m.st)
			if code == -2 { moved(m, KlondikeWasm.kd_wasm_draw(m.st)) }
			else if code == -3 { moved(m, KlondikeWasm.kd_wasm_recycle(m.st)) }
			else if code < 0 { m }
			else { moved(m, KlondikeWasm.kd_wasm_move(m.st, KlondikeWasm.kd_wasm_move_from(code), KlondikeWasm.kd_wasm_move_start(code), KlondikeWasm.kd_wasm_move_to(code))) }
		} else if msg == 721 {
			{ ..m, sel: -1 }
		} else if msg == 722 or msg == 723 {
			game(KlondikeWasm.kd_wasm_new(m.seed, if msg == 722 { 1 } else { 3 }), m.seed)
		} else if msg == 724 {
			game(KlondikeWasm.kd_wasm_new(m.seed + 1, 1), m.seed + 1)
		} else if m.sel < 0 {
			lift(m, msg)
		} else {
			to = target(msg)
			if m.sel < 7 and to == m.sel {
				# inside the column you hold: shorten what you carry, or put it down
				idx = I64.rem_by(msg, 100)
				n = KlondikeWasm.kd_wasm_col_size(m.st, m.sel)
				from = run_start(m.st, m.sel, n)
				if idx != 99 and idx >= from and idx < n and idx != m.start { { ..m, start: idx } } else { { ..m, sel: -1 } }
			} else if to >= 0 and KlondikeWasm.kd_wasm_can_move(m.st, m.sel, m.start, to) == 1 {
				moved(m, KlondikeWasm.kd_wasm_move(m.st, m.sel, m.start, to))
			} else {
				# a destination that will not take it becomes the new source
				lifted = lift(m, msg)
				if lifted.sel < 0 { { ..m, sel: -1 } } else { lifted }
			}
		}
	)
}

# view: 11 words of counters and the selection, 4 foundation tops, then per
# column its size, its face-down count, its movable-run start, whether it
# takes the selection (20 slots of cards, -1 face down, -2 past the end),
# then whether each foundation takes the selection.
slots : List(I64)
slots = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]

view : Box(Model) -> List(U32)
view = |boxed| {
	m = Box.unbox(boxed)
	st = m.st
	takes = |d| if m.sel >= 0 and KlondikeWasm.kd_wasm_can_move(st, m.sel, m.start, d) == 1 { 1 } else { 0 }
	head = [
		KlondikeWasm.kd_wasm_stock_size(st), KlondikeWasm.kd_wasm_waste_size(st), KlondikeWasm.kd_wasm_waste_top(st),
		KlondikeWasm.kd_wasm_can_draw(st), KlondikeWasm.kd_wasm_can_recycle(st), KlondikeWasm.kd_wasm_founded(st),
		KlondikeWasm.kd_wasm_moves(st), KlondikeWasm.kd_wasm_won(st), m.sel, m.start, KlondikeWasm.kd_wasm_draw_count(st),
	]
	founds = List.map([0, 1, 2, 3], |f| KlondikeWasm.kd_wasm_found_card(st, f))
	cols = List.join(List.map([0, 1, 2, 3, 4, 5, 6], |c| {
		n = KlondikeWasm.kd_wasm_col_size(st, c)
		List.concat(
			[n, KlondikeWasm.kd_wasm_down(st, c), if n == 0 { 0 } else { run_start(st, c, n) }, takes(c)],
			List.map(slots, |i| if i < n { KlondikeWasm.kd_wasm_card(st, c, i) } else { -2 }),
		)
	}))
	ftakes = List.map([7, 8, 9, 10], |d| takes(d))
	List.map(List.join([head, founds, cols, ftakes]), |v| I64.to_u32_wrap(v))
}

# ---- the grader's door ------------------------------------------------------

rank : I64 -> I64
rank = |c| KlondikeWasm.kd_wasm_rank(c)
suit : I64 -> I64
suit = |c| KlondikeWasm.kd_wasm_suit(c)
coln : Box(Model), I64 -> I64
coln = |b, c| KlondikeWasm.kd_wasm_col_size(Box.unbox(b).st, c)
card : Box(Model), I64, I64 -> I64
card = |b, c, i| KlondikeWasm.kd_wasm_card(Box.unbox(b).st, c, i)
down : Box(Model), I64 -> I64
down = |b, c| KlondikeWasm.kd_wasm_down(Box.unbox(b).st, c)
found : Box(Model), I64 -> I64
found = |b, f| KlondikeWasm.kd_wasm_found(Box.unbox(b).st, f)
foundcard : Box(Model), I64 -> I64
foundcard = |b, f| KlondikeWasm.kd_wasm_found_card(Box.unbox(b).st, f)
stockn : Box(Model) -> I64
stockn = |b| KlondikeWasm.kd_wasm_stock_size(Box.unbox(b).st)
wasten : Box(Model) -> I64
wasten = |b| KlondikeWasm.kd_wasm_waste_size(Box.unbox(b).st)
wastetop : Box(Model) -> I64
wastetop = |b| KlondikeWasm.kd_wasm_waste_top(Box.unbox(b).st)
founded : Box(Model) -> I64
founded = |b| KlondikeWasm.kd_wasm_founded(Box.unbox(b).st)
moves : Box(Model) -> I64
moves = |b| KlondikeWasm.kd_wasm_moves(Box.unbox(b).st)
drawn : Box(Model) -> I64
drawn = |b| KlondikeWasm.kd_wasm_draw_count(Box.unbox(b).st)
won : Box(Model) -> I64
won = |b| KlondikeWasm.kd_wasm_won(Box.unbox(b).st)
runlen : Box(Model), I64, I64 -> I64
runlen = |b, c, i| KlondikeWasm.kd_wasm_run_len(Box.unbox(b).st, c, i)
can : Box(Model), I64, I64, I64 -> I64
can = |b, f, s, t| KlondikeWasm.kd_wasm_can_move(Box.unbox(b).st, f, s, t)
move : Box(Model), I64, I64, I64 -> Box(Model)
move = |b, f, s, t| {
	m = Box.unbox(b)
	Box.box({ ..m, st: KlondikeWasm.kd_wasm_move(m.st, f, s, t) })
}
candraw : Box(Model) -> I64
candraw = |b| KlondikeWasm.kd_wasm_can_draw(Box.unbox(b).st)
draw : Box(Model) -> Box(Model)
draw = |b| {
	m = Box.unbox(b)
	Box.box({ ..m, st: KlondikeWasm.kd_wasm_draw(m.st) })
}
canrecyc : Box(Model) -> I64
canrecyc = |b| KlondikeWasm.kd_wasm_can_recycle(Box.unbox(b).st)
recycle : Box(Model) -> Box(Model)
recycle = |b| {
	m = Box.unbox(b)
	Box.box({ ..m, st: KlondikeWasm.kd_wasm_recycle(m.st) })
}
ai : Box(Model) -> I64
ai = |b| KlondikeWasm.kd_wasm_ai(Box.unbox(b).st)
mfrom : I64 -> I64
mfrom = |c| KlondikeWasm.kd_wasm_move_from(c)
mstart : I64 -> I64
mstart = |c| KlondikeWasm.kd_wasm_move_start(c)
mto : I64 -> I64
mto = |c| KlondikeWasm.kd_wasm_move_to(c)
run : I64, I64 -> Box(Model)
run = |seed, turn| Box.box({ ..game(KlondikeWasm.kd_wasm_new(seed, turn), seed), result: KlondikeWasm.kd_wasm_run(seed, turn) })
rfound : Box(Model) -> I64
rfound = |b| KlondikeWasm.kd_wasm_run_founded(Box.unbox(b).result)
rmoves : Box(Model) -> I64
rmoves = |b| KlondikeWasm.kd_wasm_run_moves(Box.unbox(b).result)
rwon : Box(Model) -> I64
rwon = |b| KlondikeWasm.kd_wasm_run_won(Box.unbox(b).result)

drop : Box(Model) -> {}
drop = |boxed| {
	_m = Box.unbox(boxed)
	{}
}

program = { init, step, view, new, same, rank, suit, coln, card, down, found, foundcard, stockn, wasten, wastetop, founded, moves, drawn, won, runlen, can, move, candraw, draw, canrecyc, recycle, ai, mfrom, mstart, mto, run, rfound, rmoves, rwon, drop }
