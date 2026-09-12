# The browser's door onto the interpreter: bytes in, bytes out.
#
# A page hands over the listing and the keystrokes as UTF-8 and gets the
# terminal transcript back the same way. Nothing here is Roc-specific to
# the browser -- it is the same `Basic.run` the corpus ladder calls.
app [run] { pf: platform "../wasm/platform/main.roc" }

import Basic

run : List(U8), List(U8), I64 -> List(U8)
run = |src, keys, seed|
	Str.to_utf8(
		Basic.run(
			Str.from_utf8(src) ?? "",
			Basic.lines(Str.from_utf8(keys) ?? ""),
			I64.to_u64_wrap(seed),
		),
	)
