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

import cdx.Sort
import cdx.Text

# SortTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

int_cmp : I64, I64 -> I64
int_cmp = |a, b| (a - b)

print_list! : List(I64), I64, I64 => {}
print_list! = |xs, i, len| ({
	(if (i >= len) { line!(Text.printed([])) } else { ({
		line!(Text.printed(Text.show_int((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))
		print_list!(xs, (i + 1), len)
	}) })
})

# --- Entry ---

main! = |_args| {
	({
		xs = [5, 3, 8, 1, 9, 2, 7, 4, 6]
		sorted = Sort.sort_by(xs, int_cmp)
		empty = Sort.sort_by([], int_cmp)
		single = Sort.sort_by([42], int_cmp)
		dupes = Sort.sort_by([3, 1, 4, 1, 5], int_cmp)
		({
			print_list!(sorted, 0, 9)
			line!(Text.printed(Text.show_int(U64.to_i64_wrap(List.len(empty)))))
			line!(Text.printed(Text.show_int((List.get(single, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))))
			print_list!(dupes, 0, 5)
		})
	})
	Ok({})
}
