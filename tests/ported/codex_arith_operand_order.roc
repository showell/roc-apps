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

import cdx.CceText

# ArithOperandOrder -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Byte := { val : I64 }.{
	is_eq : Byte, Byte -> Bool
	is_eq = |a, b| eq_Byte(a, b)
}

bump_right : Byte -> I64
bump_right = |b| Byte.{ val: (b.val + 1) }.val

bump_left : Byte -> I64
bump_left = |b| Byte.{ val: (1 + b.val) }.val

eq_Byte : Byte, Byte -> Bool
eq_Byte = |ex, ey| (ex.val == ey.val)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.show_int(bump_right(Byte.{ val: 42 }))))
	line!(CceText.printed(CceText.show_int(bump_left(Byte.{ val: 42 }))))
	Ok({})
}
