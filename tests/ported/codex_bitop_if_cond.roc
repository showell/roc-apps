# bitop-if-cond
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/bitop-if-cond.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     count-ones 5: 2
#     count-ones 255: 8
#     count-nz 5: 2

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# BitopIfCond -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

count_ones : I64, I64 -> I64
count_ones = |x, acc| (if (x == 0) { acc } else { (if (I64.bitwise_and(x, 1) == 1) { count_ones(I64.shr_zf_wrap(x, I64.to_u8_wrap(1)), (acc + 1)) } else { count_ones(I64.shr_zf_wrap(x, I64.to_u8_wrap(1)), acc) }) })

count_nz : I64, I64 -> I64
count_nz = |x, acc| (if (x == 0) { acc } else { (if ((x - (I64.div_trunc_by(x, 2) * 2)) == 1) { count_nz(I64.div_trunc_by(x, 2), (acc + 1)) } else { count_nz(I64.div_trunc_by(x, 2), acc) }) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("count-ones 5: ", Text.show_int(count_ones(5, 0)))))
	line!(Text.printed(Text.concat("count-ones 255: ", Text.show_int(count_ones(255, 0)))))
	line!(Text.printed(Text.concat("count-nz 5: ", Text.show_int(count_nz(5, 0)))))
	Ok({})
}
