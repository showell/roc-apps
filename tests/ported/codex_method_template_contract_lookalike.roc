# method-template-contract-lookalike
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/method-template-contract-lookalike.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     False

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# MethodTemplateContractLookalike -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
PretendContractDict(a, b) : { pretend_value_impl : (a, b -> b) }

pretend_value_Integer : I64, Bool -> Bool
pretend_value_Integer = |_x, y| (y == False)

pretendContract_dict_Integer : PretendContractDict(I64, Bool)
pretendContract_dict_Integer = { pretend_value_impl: pretend_value_Integer }

# --- Entry ---

main! = |_args| {
	({
		d = pretendContract_dict_Integer
		line!(CceText.printed((if (d.pretend_value_impl)(1, True) { "True" } else { "False" })))
	})
	Ok({})
}
