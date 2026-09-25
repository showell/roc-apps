# sort-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/sort-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     1
#     2
#     3
#     4
#     5
#     6
#     7
#     8
#     9
#     
#     0
#     42
#     1
#     1
#     3
#     4
#     5

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Sort

# SortTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

int_cmp : I64, I64 -> I64
int_cmp = |a, b| (a - b)

print_list! : List(I64), I64, I64 => {}
print_list! = |xs, i, len| ({
	(if (i >= len) { line!(CceText.printed("")) } else { ({
		line!(CceText.printed(CceText.show_int((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))
		print_list!(xs, (i + 1), len)
	}) })
})

# --- Entry ---

main! = |_args| {
	({
		xs : List(I64)
		xs = [5, 3, 8, 1, 9, 2, 7, 4, 6]
		sort_by_v1 = Sort.sort_by(xs, int_cmp)
		_xs_v2 = sort_by_v1.1
		sorted : List(I64)
		sorted = sort_by_v1.0
		sort_by_v3 = Sort.sort_by([], int_cmp)
		empty : List(I64)
		empty = sort_by_v3.0
		sort_by_v4 = Sort.sort_by([42], int_cmp)
		single : List(I64)
		single = sort_by_v4.0
		sort_by_v5 = Sort.sort_by([3, 1, 4, 1, 5], int_cmp)
		dupes : List(I64)
		dupes = sort_by_v5.0
		({
			print_list!(sorted, 0, 9)
			line!(CceText.printed(CceText.show_int(U64.to_i64_wrap(List.len(empty)))))
			line!(CceText.printed(CceText.show_int((List.get(single, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))))
			print_list!(dupes, 0, 5)
		})
	})
	Ok({})
}
