# forewords@signal-music-theory
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@signal-music-theory.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Signal/MusicTheory OK

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# FwdMusicTheoryTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed([45, 17, 29, 18, 15, 23, 81, 52, 25, 19, 17, 24, 40, 20, 13, 16, 21, 30, 2, 42, 60]))
	Ok({})
}
