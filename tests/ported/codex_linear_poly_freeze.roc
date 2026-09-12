# linear-poly-freeze
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/linear-poly-freeze.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     21 seven

app [main!] { cdx: "./codex/main.roc" }

import cdx.Linear

# LinearPolyFreeze -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Str.concat(Str.concat(I64.to_str(Linear.freeze(21)), " "), Linear.freeze("seven")))
	Ok({})
}
