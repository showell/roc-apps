# tco-bitop-loop
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/tco-bitop-loop.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     loop-both: 7
#     loop-a0: 7
#     loop-none: 255
#     loop-shru: 0
#     loop-shl: 256
#     loop-xor: 255
#     loop-or: 255
#     loop-shr: 0
#     loop-not: 255
#     loop-mod: 456
#     loop-sub: 247
#     loop-and3: 255

app [main!] { cdx: "./codex/main.roc" }

import cdx.Prelude

# TcoBitopLoop -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

loop_both : I64, I64 -> I64
loop_both = |acc, k| (if (k >= 8) { acc } else { loop_both(I64.bitwise_and(k, 255), (acc + 1)) })

loop_a0 : I64, I64 -> I64
loop_a0 = |acc, k| (if (k >= 8) { acc } else { loop_a0(I64.bitwise_and(k, 255), (k + 1)) })

loop_none : I64, I64 -> I64
loop_none = |acc, k| (if (k >= 8) { acc } else { loop_none(I64.bitwise_and(acc, 255), (k + 1)) })

loop_shru : I64, I64 -> I64
loop_shru = |acc, k| (if (k >= 8) { acc } else { loop_shru(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(acc), U64.pow(2, I64.to_u64_wrap(1)))), (k + 1)) })

loop_shl : I64, I64 -> I64
loop_shl = |acc, k| (if (k >= 8) { acc } else { loop_shl(U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(acc), U64.pow(2, I64.to_u64_wrap(1)))), (k + 1)) })

loop_xor : I64, I64 -> I64
loop_xor = |acc, k| (if (k >= 8) { acc } else { loop_xor(I64.bitwise_xor(acc, 1), (k + 1)) })

loop_or : I64, I64 -> I64
loop_or = |acc, k| (if (k >= 8) { acc } else { loop_or(I64.bitwise_or(acc, 1), (k + 1)) })

loop_shr : I64, I64 -> I64
loop_shr = |acc, k| (if (k >= 8) { acc } else { loop_shr(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(acc), U64.pow(2, I64.to_u64_wrap(1)))), (k + 1)) })

loop_not : I64, I64 -> I64
loop_not = |acc, k| (if (k >= 8) { acc } else { loop_not(I64.bitwise_not(acc), (k + 1)) })

loop_mod : I64, I64 -> I64
loop_mod = |acc, k| (if (k >= 8) { acc } else { loop_mod(Prelude.int_mod(acc, 1000), (k + 1)) })

loop_sub : I64, I64 -> I64
loop_sub = |acc, k| (if (k >= 8) { acc } else { loop_sub((acc - 1), (k + 1)) })

loop_and3 : I64, I64, I64 -> I64
loop_and3 = |acc, k, pad| (if (k >= 8) { acc } else { loop_and3(I64.bitwise_and(acc, 255), (k + 1), pad) })

# --- Entry ---

main! = |_args| {
	line!(Str.concat("loop-both: ", I64.to_str(loop_both(0, 0))))
	line!(Str.concat("loop-a0: ", I64.to_str(loop_a0(255, 0))))
	line!(Str.concat("loop-none: ", I64.to_str(loop_none(255, 0))))
	line!(Str.concat("loop-shru: ", I64.to_str(loop_shru(255, 0))))
	line!(Str.concat("loop-shl: ", I64.to_str(loop_shl(1, 0))))
	line!(Str.concat("loop-xor: ", I64.to_str(loop_xor(255, 0))))
	line!(Str.concat("loop-or: ", I64.to_str(loop_or(254, 0))))
	line!(Str.concat("loop-shr: ", I64.to_str(loop_shr(255, 0))))
	line!(Str.concat("loop-not: ", I64.to_str(loop_not(255, 0))))
	line!(Str.concat("loop-mod: ", I64.to_str(loop_mod(123456, 0))))
	line!(Str.concat("loop-sub: ", I64.to_str(loop_sub(255, 0))))
	line!(Str.concat("loop-and3: ", I64.to_str(loop_and3(255, 0, 7))))
	Ok({})
}
