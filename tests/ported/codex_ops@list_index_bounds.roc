# ops@list-index-bounds
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@list-index-bounds.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     read: 1 2 3 4
#     last=4
#     set: 0 10 20 30
#     ins-front: 99 1 2 3
#     ins-mid: 1 99 2 3
#     ins-end: 1 2 3 99

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# ListIndexBounds -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

walk_at : List(I64), I64, I64, CceText -> CceText
walk_at = |xs, i, n, acc| (if (i >= n) { acc } else { walk_at(xs, (i + 1), n, CceText.concat(CceText.concat(acc, " "), CceText.show_int((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

read_all : List(I64) -> CceText
read_all = |xs| walk_at(xs, 0, U64.to_i64_wrap(List.len(xs)), "")

set_walk : List(I64), I64, I64 -> List(I64)
set_walk = |xs, i, n| (if (i >= n) { xs } else { set_walk((List.set(xs, I64.to_u64_wrap(i), (i * 10)) ?? crash("list-set-at past the end")), (i + 1), n) })

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("read:", read_all([1, 2, 3, 4]))))
	line!(CceText.printed(CceText.concat("last=", CceText.show_int((List.get([1, 2, 3, 4], I64.to_u64_wrap(3)) ?? crash("list-at out of range"))))))
	line!(CceText.printed(CceText.concat("set:", read_all(set_walk([1, 2, 3, 4], 0, 4)))))
	line!(CceText.printed(CceText.concat("ins-front:", read_all((List.insert([1, 2, 3], I64.to_u64_wrap(0), 99) ?? crash("list-insert-at past the end"))))))
	line!(CceText.printed(CceText.concat("ins-mid:", read_all((List.insert([1, 2, 3], I64.to_u64_wrap(1), 99) ?? crash("list-insert-at past the end"))))))
	line!(CceText.printed(CceText.concat("ins-end:", read_all((List.insert([1, 2, 3], I64.to_u64_wrap(3), 99) ?? crash("list-insert-at past the end"))))))
	Ok({})
}
