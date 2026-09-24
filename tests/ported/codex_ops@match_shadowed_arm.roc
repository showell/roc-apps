# ops@match-shadowed-arm
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@match-shadowed-arm.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     one
#     two
#     other
#     leaf
#     fork

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# MatchShadowedArm -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Shape : [Leaf, Fork]

classify : I64 -> Text
classify = |n| (match n {
	1 => "one"
	2 => "two"
	1 => "SHADOW-INT"
	_ => "other"
})

name_of : Shape -> Text
name_of = |s| (match s {
	Leaf => "leaf"
	Fork => "fork"
	Leaf => "SHADOW-CTOR"
})

eq_Shape : Shape, Shape -> Bool
eq_Shape = |ex, ey| (match ex {
	Leaf => (match ey {
		Leaf => True
		_ => False
	})
	Fork => (match ey {
		Fork => True
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(classify(1)))
	line!(Text.printed(classify(2)))
	line!(Text.printed(classify(3)))
	line!(Text.printed(name_of(Leaf)))
	line!(Text.printed(name_of(Fork)))
	Ok({})
}
