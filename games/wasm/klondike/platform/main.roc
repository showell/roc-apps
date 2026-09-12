# The klondike platform. Written by games/gen.py from the export table. Do not edit.
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
			new : I64, I64 -> Box(model),
			rank : I64 -> I64,
			suit : I64 -> I64,
			coln : Box(model), I64 -> I64,
			card : Box(model), I64, I64 -> I64,
			down : Box(model), I64 -> I64,
			found : Box(model), I64 -> I64,
			foundcard : Box(model), I64 -> I64,
			stockn : Box(model) -> I64,
			wasten : Box(model) -> I64,
			wastetop : Box(model) -> I64,
			founded : Box(model) -> I64,
			moves : Box(model) -> I64,
			drawn : Box(model) -> I64,
			won : Box(model) -> I64,
			runlen : Box(model), I64, I64 -> I64,
			can : Box(model), I64, I64, I64 -> I64,
			move : Box(model), I64, I64, I64 -> Box(model),
			candraw : Box(model) -> I64,
			draw : Box(model) -> Box(model),
			canrecyc : Box(model) -> I64,
			recycle : Box(model) -> Box(model),
			ai : Box(model) -> I64,
			mfrom : I64 -> I64,
			mstart : I64 -> I64,
			mto : I64 -> I64,
			run : I64, I64 -> Box(model),
			rfound : Box(model) -> I64,
			rmoves : Box(model) -> I64,
			rwon : Box(model) -> I64,
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
		"roc_rank": rank_for_host,
		"roc_suit": suit_for_host,
		"roc_coln": coln_for_host,
		"roc_card": card_for_host,
		"roc_down": down_for_host,
		"roc_found": found_for_host,
		"roc_foundcard": foundcard_for_host,
		"roc_stockn": stockn_for_host,
		"roc_wasten": wasten_for_host,
		"roc_wastetop": wastetop_for_host,
		"roc_founded": founded_for_host,
		"roc_moves": moves_for_host,
		"roc_drawn": drawn_for_host,
		"roc_won": won_for_host,
		"roc_runlen": runlen_for_host,
		"roc_can": can_for_host,
		"roc_move": move_for_host,
		"roc_candraw": candraw_for_host,
		"roc_draw": draw_for_host,
		"roc_canrecyc": canrecyc_for_host,
		"roc_recycle": recycle_for_host,
		"roc_ai": ai_for_host,
		"roc_mfrom": mfrom_for_host,
		"roc_mstart": mstart_for_host,
		"roc_mto": mto_for_host,
		"roc_run": run_for_host,
		"roc_rfound": rfound_for_host,
		"roc_rmoves": rmoves_for_host,
		"roc_rwon": rwon_for_host,
	}
	targets: {
		inputs_dir: "targets/",
		wasm32: {
			inputs: ["host.wasm", app],
			exports: ["newGame", "step", "view", "bufPtr", "kd_new", "kd_rank", "kd_suit", "kd_coln", "kd_card", "kd_down", "kd_found", "kd_foundcard", "kd_stockn", "kd_wasten", "kd_wastetop", "kd_founded", "kd_moves", "kd_drawn", "kd_won", "kd_runlen", "kd_can", "kd_move", "kd_candraw", "kd_draw", "kd_canrecyc", "kd_recycle", "kd_ai", "kd_mfrom", "kd_mstart", "kd_mto", "kd_run", "kd_rfound", "kd_rmoves", "kd_rwon", "__heap_reset"],
		},
	}

init_for_host = program.init
step_for_host = program.step
view_for_host = program.view
drop_for_host = program.drop
same_for_host = program.same
new_for_host = program.new
rank_for_host = program.rank
suit_for_host = program.suit
coln_for_host = program.coln
card_for_host = program.card
down_for_host = program.down
found_for_host = program.found
foundcard_for_host = program.foundcard
stockn_for_host = program.stockn
wasten_for_host = program.wasten
wastetop_for_host = program.wastetop
founded_for_host = program.founded
moves_for_host = program.moves
drawn_for_host = program.drawn
won_for_host = program.won
runlen_for_host = program.runlen
can_for_host = program.can
move_for_host = program.move
candraw_for_host = program.candraw
draw_for_host = program.draw
canrecyc_for_host = program.canrecyc
recycle_for_host = program.recycle
ai_for_host = program.ai
mfrom_for_host = program.mfrom
mstart_for_host = program.mstart
mto_for_host = program.mto
run_for_host = program.run
rfound_for_host = program.rfound
rmoves_for_host = program.rmoves
rwon_for_host = program.rwon
