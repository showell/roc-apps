# mod-bound-return
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/mod-bound-return.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     34
#     34
#     4

app [main!] { cdx: "./codex/main.roc" }

import cdx.Prelude
import cdx.Text

# ModBoundReturn -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

ret_direct : I64 -> I64
ret_direct = |n| Prelude.int_mod(n, 200)

ret_via_let : I64 -> I64
ret_via_let = |n| Prelude.int_mod(n, 100)

ret_tighter : I64 -> I64
ret_tighter = |n| Prelude.int_mod(n, 10)

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.show_int(ret_direct(1234))))
	line!(Text.printed(Text.show_int(ret_via_let(1234))))
	line!(Text.printed(Text.show_int(ret_tighter(1234))))
	Ok({})
}
