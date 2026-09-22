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

import cdx.Text

# RevisedNarrow -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Reading : { level : I64, label : List(U8) }

make_literal : I64 -> Reading
make_literal = |n| { level: n, label: [23, 17, 14] }

make_revised : Reading, I64 -> Reading
make_revised = |r, n| ({
	rev = r
	rv0 = n
	rv1 = [21, 13, 33]
	{ ..{ ..rev, level: rv0 }, label: rv1 }
})

make_mixed : Reading, I64 -> Reading
make_mixed = |r, n| ({
	rev = r
	rv0 = [26, 17, 36, 13, 22]
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
			line!(Text.printed(List.concat(List.concat(List.concat([23, 17, 14, 13, 21, 15, 23, 69, 2], Text.show_int(a.level)), [2]), a.label)))
			line!(Text.printed(List.concat(List.concat(List.concat([21, 13, 33, 17, 19, 13, 22, 69, 2], Text.show_int(b.level)), [2]), b.label)))
			line!(Text.printed(List.concat(List.concat(List.concat([26, 17, 36, 13, 22, 69, 2], Text.show_int(c.level)), [2]), c.label)))
		})
	})
	Ok({})
}
