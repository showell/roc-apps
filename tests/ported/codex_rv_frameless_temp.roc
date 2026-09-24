# rv-frameless-temp
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/rv-frameless-temp.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     32
#     6
#     134
#     42
#     3599

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# RvFramelessTemp -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

mix_shl : I64, I64 -> I64
mix_shl = |n, acc| (if (n == 0) { acc } else { mix_shl((n - 1), I64.bitwise_xor(acc, I64.shl_wrap(I64.bitwise_and(n, 7), I64.to_u8_wrap(I64.bitwise_and(I64.shr_zf_wrap(I64.bitwise_xor(n, 1), I64.to_u8_wrap(2)), 3))))) })

mix_and : I64, I64 -> I64
mix_and = |n, acc| (if (n == 0) { acc } else { mix_and((n - 1), (acc + I64.bitwise_and(I64.bitwise_or(n, 992), I64.bitwise_and(I64.shr_zf_wrap(I64.bitwise_xor(n, 1), I64.to_u8_wrap(2)), 255)))) })

mix_add : I64, I64 -> I64
mix_add = |n, acc| (if (n == 0) { acc } else { mix_add((n - 1), (acc + (I64.bitwise_and(n, 15) * I64.bitwise_and(I64.shr_zf_wrap(I64.bitwise_xor(n, 1), I64.to_u8_wrap(2)), 7)))) })

mix_sub : I64, I64 -> I64
mix_sub = |n, acc| (if (n == 0) { acc } else { mix_sub((n - 1), (acc + (I64.bitwise_and(n, 63) - I64.bitwise_and(I64.shr_zf_wrap(I64.bitwise_xor(n, 3), I64.to_u8_wrap(1)), 15)))) })

mix_shru : I64, I64 -> I64
mix_shru = |n, acc| (if (n == 0) { acc } else { mix_shru((n - 1), I64.bitwise_xor(acc, I64.shr_zf_wrap(I64.bitwise_or(n, 4080), I64.to_u8_wrap(I64.bitwise_and(I64.shr_zf_wrap(I64.bitwise_xor(n, 1), I64.to_u8_wrap(2)), 3))))) })

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.show_int(mix_shl(12, 0))))
	line!(CceText.printed(CceText.show_int(mix_and(12, 0))))
	line!(CceText.printed(CceText.show_int(mix_add(12, 0))))
	line!(CceText.printed(CceText.show_int(mix_sub(12, 0))))
	line!(CceText.printed(CceText.show_int(mix_shru(12, 0))))
	Ok({})
}
