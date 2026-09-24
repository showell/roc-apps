# list-pattern
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/list-pattern.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     sum=15
#     count=3
#     head=42
#     headE=0
#     second=6
#     secondE=0
#     sumE=0

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# ListPattern -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

sum_list : List(I64) -> I64
sum_list = |xs| (match xs {
	[] => 0
	[h, .. as t] => (h + sum_list(t))
})

count_list : List(I64) -> I64
count_list = |xs| (match xs {
	[_, .. as t] => (1 + count_list(t))
	[] => 0
})

head_or : List(I64), I64 -> I64
head_or = |xs, d| (match xs {
	[h, ..] => h
	_ => d
})

second_or : List(I64), I64 -> I64
second_or = |xs, d| (match xs {
	[_, .. as t] => head_or(t, d)
	[] => d
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("sum=", Text.show_int(sum_list([1, 2, 3, 4, 5])))))
	line!(Text.printed(Text.concat("count=", Text.show_int(count_list([7, 8, 9])))))
	line!(Text.printed(Text.concat("head=", Text.show_int(head_or([42, 1], 0)))))
	line!(Text.printed(Text.concat("headE=", Text.show_int(head_or([], 0)))))
	line!(Text.printed(Text.concat("second=", Text.show_int(second_or([5, 6, 7], 0)))))
	line!(Text.printed(Text.concat("secondE=", Text.show_int(second_or([5], 0)))))
	line!(Text.printed(Text.concat("sumE=", Text.show_int(sum_list([])))))
	Ok({})
}
