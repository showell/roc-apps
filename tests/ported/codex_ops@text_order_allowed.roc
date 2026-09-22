# ops@text-order-allowed
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@text-order-allowed.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     eq-same-content = 1
#     eq-diff-content = 0
#     neq-diff        = 1
#     cmp-a-b         = -1
#     cmp-a-a         = 0
#     cmp-d-b         = -1

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# TextOrderAllowed -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

b2i : Bool -> I64
b2i = |b| (if b { 1 } else { 0 })

mk : I64 -> List(U8)
mk = |n| Text.char_to_text(n)

sign : I64 -> I64
sign = |n| (if (n < 0) { (0 - 1) } else { (if (n > 0) { 1 } else { 0 }) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([13, 37, 73, 19, 15, 26, 13, 73, 24, 16, 18, 14, 13, 18, 14, 2, 77, 2], Text.show_int(b2i((mk(15) == mk(15)))))))
	line!(Text.printed(List.concat([13, 37, 73, 22, 17, 28, 28, 73, 24, 16, 18, 14, 13, 18, 14, 2, 77, 2], Text.show_int(b2i((mk(15) == mk(32)))))))
	line!(Text.printed(List.concat([18, 13, 37, 73, 22, 17, 28, 28, 2, 2, 2, 2, 2, 2, 2, 2, 77, 2], Text.show_int(b2i((mk(15) != mk(32)))))))
	line!(Text.printed(List.concat([24, 26, 31, 73, 15, 73, 32, 2, 2, 2, 2, 2, 2, 2, 2, 2, 77, 2], Text.show_int(sign(Text.compare([15], [32]))))))
	line!(Text.printed(List.concat([24, 26, 31, 73, 15, 73, 15, 2, 2, 2, 2, 2, 2, 2, 2, 2, 77, 2], Text.show_int(sign(Text.compare([15], [15]))))))
	line!(Text.printed(List.concat([24, 26, 31, 73, 22, 73, 32, 2, 2, 2, 2, 2, 2, 2, 2, 2, 77, 2], Text.show_int(sign(Text.compare([22], [32]))))))
	Ok({})
}
