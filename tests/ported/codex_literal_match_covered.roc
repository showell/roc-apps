# literal-match-covered
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/literal-match-covered.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     0
#     7
#     0
#     0

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# LiteralMatchCovered -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

by_catch : I64 -> I64
by_catch = |n| (match n {
	1 => 10
	2 => 20
	_ => 0
})

by_var : I64 -> I64
by_var = |n| (match n {
	1 => 10
	k => k
})

by_bool : Bool -> I64
by_bool = |b| (match b {
	True => 1
	False => 0
})

by_text : CceText -> I64
by_text = |s| (match s {
	"a" => 1
	"b" => 2
	_ => 0
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.show_int(by_catch(3))))
	line!(CceText.printed(CceText.show_int(by_var(7))))
	line!(CceText.printed(CceText.show_int(by_bool(False))))
	line!(CceText.printed(CceText.show_int(by_text("c"))))
	Ok({})
}
