# The BASIC platform for the browser: a suspended machine.
#
# **A BASIC PROGRAM STOPS IN THE MIDDLE OF ITSELF.** `INPUT` with nothing
# to read prints its prompt and suspends, and the page resumes it with a
# line, so what crosses the seam is a machine rather than a transcript.
# That is what makes a terminal a terminal, and it is what `GET` will need
# when a listing wants one keypress at a time.
#
# The machine is a VALUE, so the host keeps every state it has been in and
# `back` is a pop. Time travel costs one pointer per line typed.
#
# The screen is memory. ECMA-55 has neither PEEK nor POKE -- it is a
# teletype language whose only output is PRINT -- but every microcomputer
# BASIC had them, and on a Commodore a program draws by writing bytes to
# 1024. `view` answers 1,000 screen codes, then 1,000 colour cells, then
# the transcript.
platform ""
	requires {
		[Model : model] for program : {
			start : List(U8), I64 -> Box(model),
			resume : Box(model), List(U8) -> Box(model),
			view : Box(model) -> List(U8),
			status : Box(model) -> I64,
			pause : Box(model) -> I64,
			drop : Box(model) -> {},
			batch : List(U8), List(U8), I64, I64 -> List(U8),
		}
	}
	exposes []
	packages {}
	provides {
		"roc_start": start_for_host,
		"roc_resume": resume_for_host,
		"roc_view": view_for_host,
		"roc_status": status_for_host,
		"roc_pause": pause_for_host,
		"roc_drop": drop_for_host,
		"roc_batch": batch_for_host,
	}
	targets: {
		inputs_dir: "targets/",
		wasm32: {
			inputs: ["host.wasm", app],
			exports: ["srcPtr", "keysPtr", "capacity", "screenBytes", "newRun", "send", "wake", "back", "depth", "runStatus", "pauseMs", "view", "outPtr", "outLen", "runBatch"],
		},
	}

start_for_host = program.start
resume_for_host = program.resume
view_for_host = program.view
status_for_host = program.status
pause_for_host = program.pause
drop_for_host = program.drop
batch_for_host = program.batch
