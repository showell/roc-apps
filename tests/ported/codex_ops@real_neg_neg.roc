# ops@real-neg-neg
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@real-neg-neg.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     neg-neg      25
#     neg-neg-call 50

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# RealNegNeg -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

neg_neg : F64 -> F64
neg_neg = |x| (-(-x))

neg_neg_call : F64 -> F64
neg_neg_call = |x| (-(-(x * 2.0)))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("neg-neg      ", Text.show_int(F64.to_i64_wrap((neg_neg(2.5) * 10.0))))))
	line!(Text.printed(Text.concat("neg-neg-call ", Text.show_int(F64.to_i64_wrap((neg_neg_call(2.5) * 10.0))))))
	Ok({})
}
