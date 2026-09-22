# forewords@engine-time-of-day
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@engine-time-of-day.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Engine/TimeOfDay OK

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# FwdTimeOfDayTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed([39, 18, 29, 17, 18, 13, 81, 40, 17, 26, 13, 42, 28, 48, 15, 30, 2, 42, 60]))
	Ok({})
}
