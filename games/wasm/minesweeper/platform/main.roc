# The minesweeper platform. Written by games/gen.py from the export table. Do not edit.
# Two doors onto one app: the page's (newGame, step, view) over one model,
# and the grader's, Damian's export contract by handle (host.zig).
platform ""
	requires {
		[Model : model] for program : {
			init : I64 -> Box(model),
			step : Box(model), I64 -> Box(model),
			view : Box(model) -> List(U32),
			drop : Box(model) -> {},
			same : Box(model), Box(model) -> I64,
			new : I64 -> Box(model),
			mine : Box(model), I64 -> I64,
			shown : Box(model), I64 -> I64,
			adj : Box(model), I64 -> I64,
			count : Box(model) -> I64,
			hits : Box(model) -> I64,
			moves : Box(model) -> I64,
			done : Box(model) -> I64,
			won : Box(model) -> I64,
			safe : Box(model) -> I64,
			open : Box(model), I64 -> Box(model),
			ai : Box(model) -> I64,
		}
	}
	exposes []
	packages {}
	provides {
		"roc_init": init_for_host,
		"roc_step": step_for_host,
		"roc_view": view_for_host,
		"roc_drop": drop_for_host,
		"roc_same": same_for_host,
		"roc_new": new_for_host,
		"roc_mine": mine_for_host,
		"roc_shown": shown_for_host,
		"roc_adj": adj_for_host,
		"roc_count": count_for_host,
		"roc_hits": hits_for_host,
		"roc_moves": moves_for_host,
		"roc_done": done_for_host,
		"roc_won": won_for_host,
		"roc_safe": safe_for_host,
		"roc_open": open_for_host,
		"roc_ai": ai_for_host,
	}
	targets: {
		inputs_dir: "targets/",
		wasm32: {
			inputs: ["host.wasm", app],
			exports: ["newGame", "step", "view", "bufPtr", "ms_new", "ms_mine", "ms_shown", "ms_adj", "ms_count", "ms_hits", "ms_moves", "ms_done", "ms_won", "ms_safe", "ms_open", "ms_ai", "__heap_reset"],
		},
	}

init_for_host = program.init
step_for_host = program.step
view_for_host = program.view
drop_for_host = program.drop
same_for_host = program.same
new_for_host = program.new
mine_for_host = program.mine
shown_for_host = program.shown
adj_for_host = program.adj
count_for_host = program.count
hits_for_host = program.hits
moves_for_host = program.moves
done_for_host = program.done
won_for_host = program.won
safe_for_host = program.safe
open_for_host = program.open
ai_for_host = program.ai
