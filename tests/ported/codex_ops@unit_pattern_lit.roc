# ops@unit-pattern-lit
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@unit-pattern-lit.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     text-plain=matched
#     text-unit =matched
#     int-unit  =matched

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# UnitPatternLit -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Name : List(U8)
Count : I64

classify_plain : List(U8) -> List(U8)
classify_plain = |s| (match s {
	[19, 17, 18] => [26, 15, 14, 24, 20, 13, 22]
	_ => [28, 13, 23, 23, 73, 14, 20, 21, 16, 25, 29, 20]
})

classify_unit : Name -> List(U8)
classify_unit = |n| (match n {
	[19, 17, 18] => [26, 15, 14, 24, 20, 13, 22]
	_ => [28, 13, 23, 23, 73, 14, 20, 21, 16, 25, 29, 20]
})

classify_int : Count -> List(U8)
classify_int = |c| (match c {
	42 => [26, 15, 14, 24, 20, 13, 22]
	_ => [28, 13, 23, 23, 73, 14, 20, 21, 16, 25, 29, 20]
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([14, 13, 36, 14, 73, 31, 23, 15, 17, 18, 77], classify_plain([19, 17, 18]))))
	line!(Text.printed(List.concat([14, 13, 36, 14, 73, 25, 18, 17, 14, 2, 77], classify_unit([19, 17, 18]))))
	line!(Text.printed(List.concat([17, 18, 14, 73, 25, 18, 17, 14, 2, 2, 77], classify_int(42))))
	Ok({})
}
