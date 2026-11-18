# BASIC as a Roc app on the basic platform (../wasm/platform): the
# interpreter behind one boxed machine.
#
# Hand-written; the seam between the browser and the interpreter. A
# machine that wants a line says so (`status` answers 1) and the page
# resumes it with one. `view` answers a flag byte, the screen and then the transcript,
# in that order, because a Commodore's screen IS memory and the page reads
# it straight out.
app [Model, program] { pf: platform "../wasm/platform/main.roc" }

import Machine

Model : Machine.Run

start : List(U8), I64 -> Box(Model)
start = |src, seed| Box.box(Machine.start(Str.from_utf8(src) ?? "", seed.to_u64_wrap()))

resume : Box(Model), List(U8) -> Box(Model)
resume = |boxed, line| Box.box(Machine.resume(boxed.unbox(), Str.from_utf8(line) ?? ""))

view : Box(Model) -> List(U8)
view = |boxed| {
	r = boxed.unbox()
	# A flag byte first, 1 when the program drew pixels, so the page knows
	# which display to show rather than guessing from a length.
	flag = if Machine.devices_of(r.m).drew {
		1
	} else {
		0
	}
	[flag].concat(Machine.screen(r.m)).concat(Machine.transcript(r.m).to_utf8())
}

status : Box(Model) -> I64
status = |boxed| Machine.status(boxed.unbox().m)

# Milliseconds a SLEEPing machine asked for; zero when it is not.
pause : Box(Model) -> I64
pause = |boxed| Machine.pause_ms(boxed.unbox().m)

drop : Box(Model) -> {}
drop = |_boxed| {}

program = {
	start,
	resume,
	view,
	status,
	pause,
	drop,
}
