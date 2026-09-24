# inline-cost-based
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/inline-cost-based.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     inline-cost-based: 1122 3351 9 40

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# InlineCostBased -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
PBox := { first : I64, second : I64, tag : I64 }.{
	is_eq : PBox, PBox -> Bool
	is_eq = |a, b| a.first == b.first and a.second == b.second and a.tag == b.tag
}

make_pbox : I64, I64 -> PBox
make_pbox = |a, b| PBox.{ first: a, second: b, tag: 7 }

pick2 : I64, I64 -> I64
pick2 = |a, b| (if (a > b) { a } else { b })

caller_one : I64
caller_one = ({
	x : I64
	x = 11
	y : I64
	y = 22
	bx = make_pbox(x, y)
	((bx.first * 100) + bx.second)
})

caller_two : I64
caller_two = ({
	p : I64
	p = 33
	q : I64
	q = 44
	bx = make_pbox(p, q)
	(((bx.first * 100) + bx.second) + bx.tag)
})

# --- Entry ---

main! = |_args| {
	({
		a : I64
		a = caller_one
		b : I64
		b = caller_two
		c : I64
		c = pick2(5, 9)
		d : I64
		d = pick2(40, 2)
		line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("inline-cost-based: ", CceText.show_int(a)), " "), CceText.show_int(b)), " "), CceText.show_int(c)), " "), CceText.show_int(d))))
	})
	Ok({})
}
