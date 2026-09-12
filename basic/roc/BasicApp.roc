# The browser's door onto the interpreter: bytes in, bytes out.
#
# A page hands over the listing and the keystrokes as UTF-8 and gets back
# the SCREEN and then the transcript, in one buffer: 1,000 screen codes
# from address 1024, then 1,000 colour cells from 55296, then the text.
# Two things come back from one call because a BASIC run is one function
# and running it twice to see both halves would be a lie about cost.
app [run] { pf: platform "../wasm/platform/main.roc" }

import Basic

screen_bytes : U64
screen_bytes = 2000

run : List(U8), List(U8), I64 -> List(U8)
run = |src, keys, seed| {
	m = Basic.loop(
		Basic.new(
			Basic.load(Str.from_utf8(src) ?? ""),
			Basic.lines(Str.from_utf8(keys) ?? ""),
			I64.to_u64_wrap(seed),
		),
	)
	List.concat(Basic.screen(m), Str.to_utf8(Basic.transcript(m)))
}
