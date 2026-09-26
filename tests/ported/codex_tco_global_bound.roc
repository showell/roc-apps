# tco-global-bound
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/tco-global-bound.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     lim 5
#     cmp 0
#     es2 70
#     cnt 5
#     es 70

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# TcoGlobalBound -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

lim : I64
lim = 5

es : I64, I64 -> I64
es = |i, acc| (if (i >= lim) { acc } else { es((i + 1), (acc + (i * 7))) })

es2 : I64, I64, I64 -> I64
es2 = |i, n, acc| (if (i >= n) { acc } else { es2((i + 1), n, (acc + (i * 7))) })

cnt : I64 -> I64
cnt = |i| (if (i >= lim) { i } else { cnt((i + 1)) })

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("lim ", CceText.show_int(lim))))
	line!(CceText.printed(CceText.concat("cmp ", CceText.show_int((if (3 >= lim) { 1 } else { 0 })))))
	line!(CceText.printed(CceText.concat("es2 ", CceText.show_int(es2(0, lim, 0)))))
	line!(CceText.printed(CceText.concat("cnt ", CceText.show_int(cnt(0)))))
	line!(CceText.printed(CceText.concat("es ", CceText.show_int(es(0, 0)))))
	Ok({})
}
