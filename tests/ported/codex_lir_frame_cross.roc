# lir-frame-cross
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lir-frame-cross.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     regs-only: 6
#     saved: -52
#     saved-perm: 52
#     spilled: 20
#     spilled-perm: 28
#     unused-first: 18
#     swapped: -5
#     via-call: -19

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# LirFrameCross -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

regs_only : I64, I64, I64, I64, I64, I64, I64, I64 -> I64
regs_only = |a, b, c, d, e, f, g, h| (((((((a + b) - c) + d) - e) + f) - g) + h)

saved : I64, I64, I64, I64, I64, I64, I64, I64 -> I64
saved = |a, b, c, d, e, f, g, h| (((a * b) - (c * d)) + (((e * f) - (g * h)) + (((a + c) - (e + g)) + ((b + d) - (f + h)))))

spilled : I64, I64, I64, I64, I64, I64, I64, I64 -> I64
spilled = |a, b, c, d, e, f, g, h| ((a * b) - ((c * d) + ((e * f) - ((g * h) + ((a * c) - ((b * d) + ((e * g) - ((f * h) + ((a * d) - ((b * c) + ((e * h) - ((f * g) + (((a - b) + (c - d)) + ((e - f) + (g - h)))))))))))))))

unused_first : I64, I64, I64 -> I64
unused_first = |_a, b, c| ((b * c) - b)

swapped : I64, I64 -> I64
swapped = |a, b| (b - a)

via_call : I64 -> I64
via_call = |n| (saved(n, 2, 3, 4, 5, 6, 7, 8) - swapped(n, 4))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("regs-only: ", Text.show_int(regs_only(1, 2, 3, 4, 5, 6, 7, 8)))))
	line!(Text.printed(Text.concat("saved: ", Text.show_int(saved(1, 2, 3, 4, 5, 6, 7, 8)))))
	line!(Text.printed(Text.concat("saved-perm: ", Text.show_int(saved(8, 7, 6, 5, 4, 3, 2, 1)))))
	line!(Text.printed(Text.concat("spilled: ", Text.show_int(spilled(1, 2, 3, 4, 5, 6, 7, 8)))))
	line!(Text.printed(Text.concat("spilled-perm: ", Text.show_int(spilled(8, 7, 6, 5, 4, 3, 2, 1)))))
	line!(Text.printed(Text.concat("unused-first: ", Text.show_int(unused_first(99, 6, 4)))))
	line!(Text.printed(Text.concat("swapped: ", Text.show_int(swapped(9, 4)))))
	line!(Text.printed(Text.concat("via-call: ", Text.show_int(via_call(10)))))
	Ok({})
}
