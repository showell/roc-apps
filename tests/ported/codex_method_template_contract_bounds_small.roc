# method-template-contract-bounds-small
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/method-template-contract-bounds-small.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     True

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# MethodTemplateContractBoundSmall -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bound_value_Integer : I64, a -> a
bound_value_Integer = |_x, y| y

bound_value : I64, a -> a
bound_value = |_x, y| y

# --- Entry ---

main! = |_args| {
	line!(CceText.printed((if bound_value(1, True) { "True" } else { "False" })))
	Ok({})
}
