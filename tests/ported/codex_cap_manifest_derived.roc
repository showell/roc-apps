# cap-manifest-derived
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/cap-manifest-derived.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     capability manifest derived from opening effects

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# CapManifestDerived -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed([24, 15, 31, 15, 32, 17, 23, 17, 14, 30, 2, 26, 15, 18, 17, 28, 13, 19, 14, 2, 22, 13, 21, 17, 33, 13, 22, 2, 28, 21, 16, 26, 2, 16, 31, 13, 18, 17, 18, 29, 2, 13, 28, 28, 13, 24, 14, 19]))
	Ok({})
}
