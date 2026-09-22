# forewords@math-matrix4
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@math-matrix4.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Math/Matrix4 OK

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# FwdMatrix4Test -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed([52, 15, 14, 20, 81, 52, 15, 14, 21, 17, 36, 7, 2, 42, 60]))
	Ok({})
}
