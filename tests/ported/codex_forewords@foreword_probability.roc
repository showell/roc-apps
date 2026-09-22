# forewords@foreword-probability
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@foreword-probability.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Foreword/Probability OK

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# FwdProbabilityTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed([54, 16, 21, 13, 27, 16, 21, 22, 81, 57, 21, 16, 32, 15, 32, 17, 23, 17, 14, 30, 2, 42, 60]))
	Ok({})
}
