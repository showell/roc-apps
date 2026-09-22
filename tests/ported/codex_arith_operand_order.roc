# arith-operand-order
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/arith-operand-order.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     43
#     43

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# ArithOperandOrder -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Byte : { val : I64 }

bump_right : Byte -> I64
bump_right = |b| { val: (b.val + 1) }.val

bump_left : Byte -> I64
bump_left = |b| { val: (1 + b.val) }.val

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.show_int(bump_right({ val: 42 }))))
	line!(Text.printed(Text.show_int(bump_left({ val: 42 }))))
	Ok({})
}
