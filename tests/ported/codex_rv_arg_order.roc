# rv-arg-order
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/rv-arg-order.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     lit-lit: 5
#     call-lit: 5
#     lit-call: -5
#     bin-call: 3
#     bin2-call: 13

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# RvArgOrder -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

f_two : I64, I64 -> I64
f_two = |a, b| (a - b)

seven : I64
seven = 7

f_bin : I64 -> I64
f_bin = |x| (x - seven)

f_bin2 : I64 -> I64
f_bin2 = |x| ((x * 2) - seven)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("lit-lit: ", CceText.show_int(f_two(7, 2)))))
	line!(CceText.printed(CceText.concat("call-lit: ", CceText.show_int(f_two(seven, 2)))))
	line!(CceText.printed(CceText.concat("lit-call: ", CceText.show_int(f_two(2, seven)))))
	line!(CceText.printed(CceText.concat("bin-call: ", CceText.show_int(f_bin(10)))))
	line!(CceText.printed(CceText.concat("bin2-call: ", CceText.show_int(f_bin2(10)))))
	Ok({})
}
