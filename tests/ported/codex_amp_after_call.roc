# amp-after-call
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/amp-after-call.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     n=7

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# AmpAfterCall -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

label : I64 -> List(U8)
label = |x| List.concat([18, 77], Text.show_int(x))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(label(7)))
	Ok({})
}
