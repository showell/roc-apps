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

app [main!] {}

# RevisedNarrow -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Reading : { level : I64, label : Str }

make_literal : I64 -> Reading
make_literal = |n| { level: n, label: "lit" }

make_revised : Reading, I64 -> Reading
make_revised = |r, n| ({
	rev = r
	rv0 = n
	rv1 = "rev"
	{ ..{ ..rev, level: rv0 }, label: rv1 }
})

make_mixed : Reading, I64 -> Reading
make_mixed = |r, n| ({
	rev = r
	rv0 = "mixed"
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
			line!(Str.concat(Str.concat(Str.concat("literal: ", I64.to_str(a.level)), " "), a.label))
			line!(Str.concat(Str.concat(Str.concat("revised: ", I64.to_str(b.level)), " "), b.label))
			line!(Str.concat(Str.concat(Str.concat("mixed: ", I64.to_str(c.level)), " "), c.label))
		})
	})
	Ok({})
}
