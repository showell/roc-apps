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

one_line : I64 -> Text
one_line = |n| (match n {
	1 => "one"
	2 => "two"
	3 => "three"
	_ => "other"
})

many_per_line : I64 -> Text
many_per_line = |n| (match n {
	1 => "one"
	2 => "two"
	3 => "three"
	4 => "four"
	5 => "five"
	6 => "six"
	_ => "other"
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat(Text.concat(Text.concat(Text.concat("one-line: ", one_line(1)), one_line(2)), one_line(3)), one_line(9))))
	line!(Text.printed(Text.concat("many-1: ", many_per_line(1))))
	line!(Text.printed(Text.concat("many-2: ", many_per_line(2))))
	line!(Text.printed(Text.concat("many-3: ", many_per_line(3))))
	line!(Text.printed(Text.concat("many-4: ", many_per_line(4))))
	line!(Text.printed(Text.concat("many-5: ", many_per_line(5))))
	line!(Text.printed(Text.concat("many-6: ", many_per_line(6))))
	line!(Text.printed(Text.concat("many-9: ", many_per_line(9))))
	Ok({})
}
