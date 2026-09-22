# match-arms-per-line
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/match-arms-per-line.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     one-line: onetwothreeother
#     many-1: one
#     many-2: two
#     many-3: three
#     many-4: four
#     many-5: five
#     many-6: six
#     many-9: other

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# MatchArmsPerLine -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

one_line : I64 -> List(U8)
one_line = |n| (match n {
	1 => [16, 18, 13]
	2 => [14, 27, 16]
	3 => [14, 20, 21, 13, 13]
	_ => [16, 14, 20, 13, 21]
})

many_per_line : I64 -> List(U8)
many_per_line = |n| (match n {
	1 => [16, 18, 13]
	2 => [14, 27, 16]
	3 => [14, 20, 21, 13, 13]
	4 => [28, 16, 25, 21]
	5 => [28, 17, 33, 13]
	6 => [19, 17, 36]
	_ => [16, 14, 20, 13, 21]
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat(List.concat(List.concat(List.concat([16, 18, 13, 73, 23, 17, 18, 13, 69, 2], one_line(1)), one_line(2)), one_line(3)), one_line(9))))
	line!(Text.printed(List.concat([26, 15, 18, 30, 73, 4, 69, 2], many_per_line(1))))
	line!(Text.printed(List.concat([26, 15, 18, 30, 73, 5, 69, 2], many_per_line(2))))
	line!(Text.printed(List.concat([26, 15, 18, 30, 73, 6, 69, 2], many_per_line(3))))
	line!(Text.printed(List.concat([26, 15, 18, 30, 73, 7, 69, 2], many_per_line(4))))
	line!(Text.printed(List.concat([26, 15, 18, 30, 73, 8, 69, 2], many_per_line(5))))
	line!(Text.printed(List.concat([26, 15, 18, 30, 73, 9, 69, 2], many_per_line(6))))
	line!(Text.printed(List.concat([26, 15, 18, 30, 73, 12, 69, 2], many_per_line(9))))
	Ok({})
}
