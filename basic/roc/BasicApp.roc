# BASIC as a Roc app on the basic platform (../wasm/platform): the
# interpreter behind one boxed machine.
#
# Hand-written; the seam between the browser and the interpreter. A
# machine that wants a line says so (`status` answers 1) and the page
# resumes it with one. `view` answers a flag byte, the screen and then the transcript,
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
	# A flag byte first, 1 when the program drew pixels, so the page knows
	# which display to show rather than guessing from a length.
	flag = if m.drew { 1 } else { 0 }
	List.concat(List.concat([flag], Basic.screen(m)), Str.to_utf8(Basic.transcript(m)))
}

status : Box(Model) -> I64
status = |boxed| Basic.status(Box.unbox(boxed))

# Milliseconds a SLEEPing machine asked for; zero when it is not.
pause : Box(Model) -> I64
pause = |boxed| Basic.pause_ms(Box.unbox(boxed))

drop : Box(Model) -> {}
drop = |_boxed| {}

# **THE BATCH DOORS, FOR A RUNNER OUTSIDE THE PAGE.** The listing, the
# keystrokes one per line, the dialect (1 is ECMA-55) and a seed in; the
# transcript out. No machine is kept, and nothing pauses: a PRINT does not
# yield and a SLEEP takes no time.
batch : List(U8), List(U8), I64, I64 -> List(U8)
batch = |src, keys, ecma, seed| {
	text = Str.from_utf8(src) ?? ""
	inp = lines_of(keys, 0, 0, [])
	out = if ecma == 1 { Basic.run_ecma(text, inp, I64.to_u64_wrap(seed)) } else { Basic.run(text, inp, I64.to_u64_wrap(seed)) }
	Str.to_utf8(out)
}

# The keystrokes split on newlines. A final newline ends the last line
# rather than starting an empty one.
lines_of : List(U8), U64, U64, List(Str) -> List(Str)
lines_of = |b, from, i, acc|
	if i >= List.len(b) {
		if i > from { List.append(acc, piece(b, from, i)) } else { acc }
	} else if (List.get(b, i) ?? 0) == 10 {
		lines_of(b, i + 1, i + 1, List.append(acc, piece(b, from, i)))
	} else {
		lines_of(b, from, i + 1, acc)
	}

piece : List(U8), U64, U64 -> Str
piece = |b, from, i| Str.from_utf8(List.sublist(b, { start: from, len: i - from })) ?? ""

program = { start, resume, view, status, pause, drop, batch }
