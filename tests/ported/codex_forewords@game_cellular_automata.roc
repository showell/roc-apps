# forewords@game-cellular-automata
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@game-cellular-automata.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Game/CellularAutomata OK

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# FwdCellularAutomataTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed([55, 15, 26, 13, 81, 50, 13, 23, 23, 25, 23, 15, 21, 41, 25, 14, 16, 26, 15, 14, 15, 2, 42, 60]))
	Ok({})
}
