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

app [main!] {}

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
	line!(Str.concat("regs-only: ", I64.to_str(regs_only(1, 2, 3, 4, 5, 6, 7, 8))))
	line!(Str.concat("saved: ", I64.to_str(saved(1, 2, 3, 4, 5, 6, 7, 8))))
	line!(Str.concat("saved-perm: ", I64.to_str(saved(8, 7, 6, 5, 4, 3, 2, 1))))
	line!(Str.concat("spilled: ", I64.to_str(spilled(1, 2, 3, 4, 5, 6, 7, 8))))
	line!(Str.concat("spilled-perm: ", I64.to_str(spilled(8, 7, 6, 5, 4, 3, 2, 1))))
	line!(Str.concat("unused-first: ", I64.to_str(unused_first(99, 6, 4))))
	line!(Str.concat("swapped: ", I64.to_str(swapped(9, 4))))
	line!(Str.concat("via-call: ", I64.to_str(via_call(10))))
	Ok({})
}
