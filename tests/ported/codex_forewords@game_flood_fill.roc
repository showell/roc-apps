# forewords@game-flood-fill
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@game-flood-fill.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Game/FloodFill OK

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# FwdFloodFillTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed([55, 15, 26, 13, 81, 54, 23, 16, 16, 22, 54, 17, 23, 23, 2, 42, 60]))
	Ok({})
}
