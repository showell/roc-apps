# BASIC as a Roc app on the basic platform (../wasm/platform): the
# interpreter behind one boxed machine.
#
# Hand-written; the seam between the browser and the interpreter. A
# machine that wants a line says so (`status` answers 1) and the page
# resumes it with one. `view` answers the screen and then the transcript,
# in that order, because a Commodore's screen IS memory and the page reads
# it straight out.
app [Model, program] { pf: platform "../wasm/platform/main.roc" }

import Basic

Model : Basic.M

start : List(U8), I64 -> Box(Model)
start = |src, seed| Box.box(Basic.start(Str.from_utf8(src) ?? "", I64.to_u64_wrap(seed)))

resume : Box(Model), List(U8) -> Box(Model)
resume = |boxed, line| Box.box(Basic.resume(Box.unbox(boxed), Str.from_utf8(line) ?? ""))

view : Box(Model) -> List(U8)
view = |boxed| {
	m = Box.unbox(boxed)
	List.concat(Basic.screen(m), Str.to_utf8(Basic.transcript(m)))
}

status : Box(Model) -> I64
status = |boxed| Basic.status(Box.unbox(boxed))

# Milliseconds a SLEEPing machine asked for; zero when it is not.
pause : Box(Model) -> I64
pause = |boxed| Basic.pause_ms(Box.unbox(boxed))

drop : Box(Model) -> {}
drop = |_boxed| {}

program = { start, resume, view, status, pause, drop }
