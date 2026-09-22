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

classify : I64 -> List(U8)
classify = |n| (match n {
	1 => [16, 18, 13]
	2 => [14, 27, 16]
	1 => [45, 46, 41, 48, 42, 53, 73, 43, 44, 40]
	_ => [16, 14, 20, 13, 21]
})

name_of : Shape -> List(U8)
name_of = |s| (match s {
	Leaf => [23, 13, 15, 28]
	Fork => [28, 16, 21, 34]
	Leaf => [45, 46, 41, 48, 42, 53, 73, 50, 40, 42, 47]
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
