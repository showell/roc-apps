# forewords@ai-prompt-parser
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@ai-prompt-parser.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     AI/PromptParser OK

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# FwdPromptParserTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed([41, 43, 81, 57, 21, 16, 26, 31, 14, 57, 15, 21, 19, 13, 21, 2, 42, 60]))
	Ok({})
}
