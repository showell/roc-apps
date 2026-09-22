# forewords@engine-game-loop
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@engine-game-loop.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Engine/GameLoop OK

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# FwdGameLoopTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed([39, 18, 29, 17, 18, 13, 81, 55, 15, 26, 13, 49, 16, 16, 31, 2, 42, 60]))
	Ok({})
}
