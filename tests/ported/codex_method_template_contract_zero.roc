# method-template-contract-zero
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/method-template-contract-zero.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     zero

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# MethodTemplateContractZero -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

dormant_value_Integer : I64, a -> a
dormant_value_Integer = |_x, y| y

dormant_value : I64, a -> a
dormant_value = |_x, y| y

# --- Entry ---

main! = |_args| {
	line!(CceText.printed("zero"))
	Ok({})
}
