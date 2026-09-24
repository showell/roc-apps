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

import cdx.Text

# InlineCostBased -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
PBox : { first : I64, second : I64, tag : I64 }

make_pbox : I64, I64 -> PBox
make_pbox = |a, b| { first: a, second: b, tag: 7 }

pick2 : I64, I64 -> I64
pick2 = |a, b| (if (a > b) { a } else { b })

caller_one : I64
caller_one = ({
	x = 11
	y = 22
	bx = make_pbox(x, y)
	((bx.first * 100) + bx.second)
})

caller_two : I64
caller_two = ({
	p = 33
	q = 44
	bx = make_pbox(p, q)
	(((bx.first * 100) + bx.second) + bx.tag)
})

# --- Entry ---

main! = |_args| {
	({
		a = caller_one
		b = caller_two
		c = pick2(5, 9)
		d = pick2(40, 2)
		line!(Text.printed(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("inline-cost-based: ", Text.show_int(a)), " "), Text.show_int(b)), " "), Text.show_int(c)), " "), Text.show_int(d))))
	})
	Ok({})
}
