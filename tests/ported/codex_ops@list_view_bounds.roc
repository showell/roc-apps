# ops@list-view-bounds
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@list-view-bounds.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     view: 2 3 4
#     view-len=3

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# ListViewBounds -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

walk_at : List(I64), I64, I64, CceText -> CceText
walk_at = |xs, i, n, acc| (if (i >= n) { acc } else { walk_at(xs, (i + 1), n, CceText.concat(CceText.concat(acc, " "), CceText.show_int((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

read_all : List(I64) -> CceText
read_all = |xs| walk_at(xs, 0, U64.to_i64_wrap(List.len(xs)), "")

tail_of : List(I64) -> List(I64)
tail_of = |xs| (match xs {
	[_h, .. as t] => t
	_ => xs
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("view:", read_all(tail_of([1, 2, 3, 4])))))
	line!(CceText.printed(CceText.concat("view-len=", CceText.show_int(U64.to_i64_wrap(List.len(tail_of([1, 2, 3, 4])))))))
	Ok({})
}
