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

import cdx.CceText

# UnitPatternLit -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Name : CceText
Count : I64

classify_plain : CceText -> CceText
classify_plain = |s| (match s {
	"sin" => "matched"
	_ => "fell-through"
})

classify_unit : Name -> CceText
classify_unit = |n| (match n {
	"sin" => "matched"
	_ => "fell-through"
})

classify_int : Count -> CceText
classify_int = |c| (match c {
	42 => "matched"
	_ => "fell-through"
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("text-plain=", classify_plain("sin"))))
	line!(CceText.printed(CceText.concat("text-unit =", classify_unit("sin"))))
	line!(CceText.printed(CceText.concat("int-unit  =", classify_int(42))))
	Ok({})
}
