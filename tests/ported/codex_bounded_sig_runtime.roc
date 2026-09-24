# bounded-sig-runtime
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/bounded-sig-runtime.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     6
#     9

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# BoundedSigRuntime -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

inc_byte : I64 -> I64
inc_byte = |n| (n + 1)

clamp_ret : I64 -> I64
clamp_ret = |n| n

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.show_int(inc_byte(5))))
	line!(CceText.printed(CceText.show_int(clamp_ret(9))))
	Ok({})
}
