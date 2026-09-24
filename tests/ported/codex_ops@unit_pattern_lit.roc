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
Name : Text
Count : I64

classify_plain : Text -> Text
classify_plain = |s| (match s {
	"sin" => "matched"
	_ => "fell-through"
})

classify_unit : Name -> Text
classify_unit = |n| (match n {
	"sin" => "matched"
	_ => "fell-through"
})

classify_int : Count -> Text
classify_int = |c| (match c {
	42 => "matched"
	_ => "fell-through"
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("text-plain=", classify_plain("sin"))))
	line!(Text.printed(Text.concat("text-unit =", classify_unit("sin"))))
	line!(Text.printed(Text.concat("int-unit  =", classify_int(42))))
	Ok({})
}
