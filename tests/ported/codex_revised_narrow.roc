# revised-narrow
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/revised-narrow.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     literal: 42 lit
#     revised: 7 rev
#     mixed: 99 mixed

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# RevisedNarrow -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Reading := { level : I64, label : CceText }.{
	is_eq : Reading, Reading -> Bool
	is_eq = |a, b| a.level == b.level and a.label == b.label
}

make_literal : I64 -> Reading
make_literal = |n| Reading.{ level: n, label: "lit" }

make_revised : Reading, I64 -> Reading
make_revised = |r, n| ({
	rev = r
	rv0 : I64
	rv0 = n
	rv1 : CceText
	rv1 = "rev"
	{ ..{ ..rev, level: rv0 }, label: rv1 }
})

make_mixed : Reading, I64 -> Reading
make_mixed = |r, n| ({
	rev = r
	rv0 : CceText
	rv0 = "mixed"
	rv1 : I64
	rv1 = n
	{ ..{ ..rev, label: rv0 }, level: rv1 }
})

# --- Entry ---

main! = |_args| {
	({
		a = make_literal(42)
		b = make_revised(make_literal(5), 7)
		c = make_mixed(make_literal(5), 99)
		({
			line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat("literal: ", CceText.show_int(a.level)), " "), a.label)))
			line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat("revised: ", CceText.show_int(b.level)), " "), b.label)))
			line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat("mixed: ", CceText.show_int(c.level)), " "), c.label)))
		})
	})
	Ok({})
}
