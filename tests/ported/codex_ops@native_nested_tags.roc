# ops@native-nested-tags
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@native-nested-tags.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     1
#     2
#     3
#     3
#     3

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# NativeNestedTags -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Atom := [Yes, No, Both(Atom, Atom)].{
	is_eq : Atom, Atom -> Bool
	is_eq = |a, b| eq_Atom(a, b)
}

nested_tag : Atom -> I64
nested_tag = |value| (match value {
	Both(Yes, No) => 1
	Both(No, Yes) => 2
	_ => 3
})

eq_Atom : Atom, Atom -> Bool
eq_Atom = |ex, ey| (match ex {
	Yes => (match ey {
		Yes => True
		_ => False
	})
	No => (match ey {
		No => True
		_ => False
	})
	Both(exf0, exf1) => (match ey {
		Both(eyf0, eyf1) => (eq_Atom(exf0, eyf0) and eq_Atom(exf1, eyf1))
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.show_int(nested_tag(Both(Yes, No)))))
	line!(CceText.printed(CceText.show_int(nested_tag(Both(No, Yes)))))
	line!(CceText.printed(CceText.show_int(nested_tag(Both(Yes, Yes)))))
	line!(CceText.printed(CceText.show_int(nested_tag(Both(No, No)))))
	line!(CceText.printed(CceText.show_int(nested_tag(Yes))))
	Ok({})
}
