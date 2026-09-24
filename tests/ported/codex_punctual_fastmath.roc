# punctual-fastmath
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/punctual-fastmath.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     int-log2 1: 0
#     int-log2 256: 8
#     int-log2 1023: 9
#     int-log2 0: -1

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.FastMath

# PunctualFastMath -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("int-log2 1: ", CceText.show_int(FastMath.int_log2(1)))))
	line!(CceText.printed(CceText.concat("int-log2 256: ", CceText.show_int(FastMath.int_log2(256)))))
	line!(CceText.printed(CceText.concat("int-log2 1023: ", CceText.show_int(FastMath.int_log2(1023)))))
	line!(CceText.printed(CceText.concat("int-log2 0: ", CceText.show_int(FastMath.int_log2(0)))))
	Ok({})
}
