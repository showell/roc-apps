# forewords@ai-neural-net
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@ai-neural-net.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     AI/NeuralNet OK

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# FwdNeuralNetTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed([41, 43, 81, 44, 13, 25, 21, 15, 23, 44, 13, 14, 2, 42, 60]))
	Ok({})
}
