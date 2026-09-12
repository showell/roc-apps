# lir-call-cross
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lir-call-cross.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     5
#     -5
#     -3
#     3
#     6
#     10
#     5
#     13
#     312
#     231

app [main!] {}

# LirCallCross -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

hdiff : I64, I64 -> I64
hdiff = |a, b| (if (a >= b) { (a - b) } else { (0 - (b - a)) })

htri : I64, I64, I64 -> I64
htri = |a, b, c| (if (a > 0) { (((a * 100) + (b * 10)) + c) } else { ((b * 10) + c) })

callplain : I64, I64 -> I64
callplain = |x, y| hdiff(x, y)

callswap : I64, I64 -> I64
callswap = |x, y| hdiff(y, x)

callimm_l : I64 -> I64
callimm_l = |x| hdiff(7, x)

callimm_r : I64 -> I64
callimm_r = |x| hdiff(x, 7)

callres : I64, I64 -> I64
callres = |x, y| (hdiff(x, y) + 1)

callchain : I64, I64 -> I64
callchain = |x, y| hdiff(hdiff(x, y), hdiff(y, x))

callcond : I64, I64 -> I64
callcond = |x, y| (if (x > 0) { hdiff(x, y) } else { hdiff(y, x) })

callthree : I64, I64, I64 -> I64
callthree = |a, b, c| htri(c, a, b)

callthree2 : I64, I64, I64 -> I64
callthree2 = |a, b, c| htri(b, c, a)

# --- Entry ---

main! = |_args| {
	line!(I64.to_str(callplain(9, 4)))
	line!(I64.to_str(callswap(9, 4)))
	line!(I64.to_str(callimm_l(10)))
	line!(I64.to_str(callimm_r(10)))
	line!(I64.to_str(callres(9, 4)))
	line!(I64.to_str(callchain(9, 4)))
	line!(I64.to_str(callcond(9, 4)))
	line!(I64.to_str(callcond((-9), 4)))
	line!(I64.to_str(callthree(1, 2, 3)))
	line!(I64.to_str(callthree2(1, 2, 3)))
	Ok({})
}
