# ops@int-mul-wrapping
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@int-mul-wrapping.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     funnel   want -2446744073709551616: -2446744073709551616
#     param    want -2446744073709551616: -2446744073709551616
#     in-band  want 9000000000000000000: 9000000000000000000
#     small    want 42: 42

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Wrap64

# IntMulWrapping -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

big : I64
big = 4000000000

by_param : I64, I64 -> I64
by_param = |a, b| I64.times_wrap(a, b)

by_plain : I64, I64 -> I64
by_plain = |a, b| (a * b)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("funnel   want -2446744073709551616: ", CceText.show_int(Wrap64.w64_mul(big, big)))))
	line!(CceText.printed(CceText.concat("param    want -2446744073709551616: ", CceText.show_int(by_param(big, big)))))
	line!(CceText.printed(CceText.concat("in-band  want 9000000000000000000: ", CceText.show_int(by_plain(3000000000, 3000000000)))))
	line!(CceText.printed(CceText.concat("small    want 42: ", CceText.show_int(by_plain(6, 7)))))
	Ok({})
}
