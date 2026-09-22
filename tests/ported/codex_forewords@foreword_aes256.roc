# forewords@foreword-aes256
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@foreword-aes256.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Foreword/Aes256 OK

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# FwdAes256Test -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed([54, 16, 21, 13, 27, 16, 21, 22, 81, 41, 13, 19, 5, 8, 9, 2, 42, 60]))
	Ok({})
}
