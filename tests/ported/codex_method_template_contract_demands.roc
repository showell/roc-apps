# method-template-contract-demands
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/method-template-contract-demands.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     True
#     False
#     left
#     5
#     6
#     7

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# MethodTemplateContractDemands -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

demand_left_Integer : I64, a -> a
demand_left_Integer = |_x, y| y

demand_right_Integer : I64, a -> I64
demand_right_Integer = |x, _y| (x + 1)

demand_left : I64, a -> a
demand_left = |_x, y| y

demand_right : I64, a -> I64
demand_right = |x, _y| (x + 1)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed((if demand_left(1, True) { "True" } else { "False" })))
	line!(CceText.printed((if demand_left(2, False) { "True" } else { "False" })))
	line!(CceText.printed(demand_left(3, "left")))
	line!(CceText.printed(CceText.show_int(demand_right(4, True))))
	line!(CceText.printed(CceText.show_int(demand_right(5, "right"))))
	line!(CceText.printed(CceText.show_int(demand_right(6, 99))))
	Ok({})
}
