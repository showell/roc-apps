# int-literal-underscore
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/int-literal-underscore.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     grouped: 1000000000000000000
#     padded: 42

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# IntLiteralUnderscore -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

billion_squared : I64
billion_squared = 1000000000000000000

padded : I64
padded = 42

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("grouped: ", CceText.show_int(billion_squared))))
	line!(CceText.printed(CceText.concat("padded: ", CceText.show_int(padded))))
	Ok({})
}
