# The 2048 platform. Written by games/gen.py from the export table. Do not edit.
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
			cell : Box(model), I64 -> I64,
			score : Box(model) -> I64,
			moves : Box(model) -> I64,
			done : Box(model) -> I64,
			max : Box(model) -> I64,
			empty : Box(model) -> I64,
			sum : Box(model) -> I64,
			can : Box(model), I64 -> I64,
			move : Box(model), I64 -> Box(model),
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
		"roc_cell": cell_for_host,
		"roc_score": score_for_host,
		"roc_moves": moves_for_host,
		"roc_done": done_for_host,
		"roc_max": max_for_host,
		"roc_empty": empty_for_host,
		"roc_sum": sum_for_host,
		"roc_can": can_for_host,
		"roc_move": move_for_host,
		"roc_ai": ai_for_host,
	}
	targets: {
		inputs_dir: "targets/",
		wasm32: {
			inputs: ["host.wasm", app],
			exports: ["newGame", "step", "view", "bufPtr", "g2_new", "g2_cell", "g2_score", "g2_moves", "g2_done", "g2_max", "g2_empty", "g2_sum", "g2_can", "g2_move", "g2_ai", "__heap_reset"],
		},
	}

init_for_host = program.init
step_for_host = program.step
view_for_host = program.view
drop_for_host = program.drop
same_for_host = program.same
new_for_host = program.new
cell_for_host = program.cell
score_for_host = program.score
moves_for_host = program.moves
done_for_host = program.done
max_for_host = program.max
empty_for_host = program.empty
sum_for_host = program.sum
can_for_host = program.can
move_for_host = program.move
ai_for_host = program.ai
