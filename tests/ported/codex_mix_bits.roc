# mix-bits
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/mix-bits.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     ones/256:        131
#     balanced:        True
#     alternations:    130
#     not a stripe:    True
#     control alt:     255
#     control striped: True
#     range2 ones/256: 121
#     range2 spread:   True

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Random

# MixBitsTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

mb_old : I64, I64 -> I64
mb_old = |seed, idx| I64.bitwise_xor((seed * 2654435761), (idx * 40503))

mb_ones : I64, I64, I64, I64 -> I64
mb_ones = |seed, i, n, acc| (if (i >= n) { acc } else { mb_ones(seed, (i + 1), n, (acc + I64.bitwise_and(Random.mix_bits(seed, i), 1))) })

mb_alt : I64, I64, I64, I64 -> I64
mb_alt = |seed, i, n, acc| (if (i >= n) { acc } else { ({
	a = I64.bitwise_and(Random.mix_bits(seed, i), 1)
	b = I64.bitwise_and(Random.mix_bits(seed, (i - 1)), 1)
	mb_alt(seed, (i + 1), n, (acc + (if (a == b) { 0 } else { 1 })))
}) })

mb_old_alt : I64, I64, I64, I64 -> I64
mb_old_alt = |seed, i, n, acc| (if (i >= n) { acc } else { ({
	a = I64.bitwise_and(mb_old(seed, i), 1)
	b = I64.bitwise_and(mb_old(seed, (i - 1)), 1)
	mb_old_alt(seed, (i + 1), n, (acc + (if (a == b) { 0 } else { 1 })))
}) })

mb_range2 : I64, I64, I64 -> I64
mb_range2 = |i, n, acc| (if (i >= n) { acc } else { mb_range2((i + 1), n, (acc + Random.rand_in_range(i, 7, 0, 1))) })

# --- Entry ---

main! = |_args| {
	ones = mb_ones(20260725, 0, 256, 0)
	alt = mb_alt(20260725, 1, 256, 0)
	oldalt = mb_old_alt(20260725, 1, 256, 0)
	r2 = mb_range2(0, 256, 0)
	line!(CceText.printed(CceText.concat("ones/256:        ", CceText.show_int(ones))))
	line!(CceText.printed(CceText.concat("balanced:        ", (if ((ones > 96) and (ones < 160)) { "True" } else { "False" }))))
	line!(CceText.printed(CceText.concat("alternations:    ", CceText.show_int(alt))))
	line!(CceText.printed(CceText.concat("not a stripe:    ", (if (alt < 200) { "True" } else { "False" }))))
	line!(CceText.printed(CceText.concat("control alt:     ", CceText.show_int(oldalt))))
	line!(CceText.printed(CceText.concat("control striped: ", (if (oldalt == 255) { "True" } else { "False" }))))
	line!(CceText.printed(CceText.concat("range2 ones/256: ", CceText.show_int(r2))))
	line!(CceText.printed(CceText.concat("range2 spread:   ", (if ((r2 > 96) and (r2 < 160)) { "True" } else { "False" }))))
	Ok({})
}
