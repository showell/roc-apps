# forewords@engine-scene3d
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@engine-scene3d.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Engine/Scene3D OK

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# FwdScene3DTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed([39, 18, 29, 17, 18, 13, 81, 45, 24, 13, 18, 13, 6, 48, 2, 42, 60]))
	Ok({})
}
