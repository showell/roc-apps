# method-template-contract-unicode
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/method-template-contract-unicode.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     café λ

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# MethodTemplateContractUnicode -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

accent_value_Integer : I64, a -> CceText
accent_value_Integer = |_x, _y| "café λ"

accent_value : I64, a -> CceText
accent_value = |_x, _y| "café λ"

# --- Entry ---

main! = |_args| {
	line!(CceText.printed("café λ"))
	Ok({})
}
