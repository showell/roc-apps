# punctual-smoke
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/punctual-smoke.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     42
#     42
#     42
#     42

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# PunctualSmoke -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

fast_add : I64, I64 -> I64
fast_add = |a, b| (a + b)

bounded_mul : I64, I64 -> I64
bounded_mul = |a, b| (a * b)

bounded_sub : I64, I64 -> I64
bounded_sub = |a, b| (a - b)

scale_then_add : I64, I64 -> I64
scale_then_add = |a, b| fast_add(bounded_mul(a, 2), b)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.show_int(fast_add(10, 32))))
	line!(CceText.printed(CceText.show_int(bounded_mul(6, 7))))
	line!(CceText.printed(CceText.show_int(bounded_sub(100, 58))))
	line!(CceText.printed(CceText.show_int(scale_then_add(20, 2))))
	Ok({})
}
