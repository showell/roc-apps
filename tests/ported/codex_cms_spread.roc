# cms-spread
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/cms-spread.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     keys:           40
#     exact:          38
#     worst estimate: 2
#     cols used:      32 27 32 26
#     mostly exact:   True
#     rows spread:    True
#     total:          40

app [main!] { cdx: "./codex/main.roc" }

import cdx.CountMinSketch
import cdx.Text

# CmsSpreadTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

cst_width : I64
cst_width = 64

cst_depth : I64
cst_depth = 4

cst_keys : I64
cst_keys = 40

cst_key : I64 -> List(U8)
cst_key = |i| List.concat([34, 13, 30], Text.show_int(i))

cst_fill : CountMinSketch.CmSketch, I64, I64 -> CountMinSketch.CmSketch
cst_fill = |s, i, n| (if (i >= n) { s } else { cst_fill(CountMinSketch.cms_add(s, cst_key(i), 1), (i + 1), n) })

cst_exact : CountMinSketch.CmSketch, I64, I64, I64 -> I64
cst_exact = |s, i, n, acc| (if (i >= n) { acc } else { ({
	e = CountMinSketch.cms_count(s, cst_key(i))
	cst_exact(s, (i + 1), n, (acc + (if (e == 1) { 1 } else { 0 })))
}) })

cst_worst : CountMinSketch.CmSketch, I64, I64, I64 -> I64
cst_worst = |s, i, n, acc| (if (i >= n) { acc } else { ({
	e = CountMinSketch.cms_count(s, cst_key(i))
	cst_worst(s, (i + 1), n, (if (e > acc) { e } else { acc }))
}) })

cst_occupied : CountMinSketch.CmSketch, I64, I64, I64, I64 -> I64
cst_occupied = |s, row, col, w, acc| (if (col >= w) { acc } else { ({
	v = (List.get(s.cms_table, I64.to_u64_wrap(((row * w) + col))) ?? crash("list-at out of range"))
	cst_occupied(s, row, (col + 1), w, (acc + (if (v > 0) { 1 } else { 0 })))
}) })

# --- Entry ---

main! = |_args| {
	s = cst_fill(CountMinSketch.cms_new(cst_width, cst_depth), 0, cst_keys)
	exact = cst_exact(s, 0, cst_keys, 0)
	worst = cst_worst(s, 0, cst_keys, 0)
	r0 = cst_occupied(s, 0, 0, cst_width, 0)
	r1 = cst_occupied(s, 1, 0, cst_width, 0)
	r2 = cst_occupied(s, 2, 0, cst_width, 0)
	r3 = cst_occupied(s, 3, 0, cst_width, 0)
	line!(Text.printed(List.concat([34, 13, 30, 19, 69, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2], Text.show_int(cst_keys))))
	line!(Text.printed(List.concat([13, 36, 15, 24, 14, 69, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2], Text.show_int(exact))))
	line!(Text.printed(List.concat([27, 16, 21, 19, 14, 2, 13, 19, 14, 17, 26, 15, 14, 13, 69, 2], Text.show_int(worst))))
	line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([24, 16, 23, 19, 2, 25, 19, 13, 22, 69, 2, 2, 2, 2, 2, 2], Text.show_int(r0)), [2]), Text.show_int(r1)), [2]), Text.show_int(r2)), [2]), Text.show_int(r3))))
	line!(Text.printed(List.concat([26, 16, 19, 14, 23, 30, 2, 13, 36, 15, 24, 14, 69, 2, 2, 2], (if ((exact * 4) >= (cst_keys * 3)) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
	line!(Text.printed(List.concat([21, 16, 27, 19, 2, 19, 31, 21, 13, 15, 22, 69, 2, 2, 2, 2], (if ((((r0 > 20) and (r1 > 20)) and (r2 > 20)) and (r3 > 20)) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
	line!(Text.printed(List.concat([14, 16, 14, 15, 23, 69, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2], Text.show_int(CountMinSketch.cms_total(s)))))
	Ok({})
}
