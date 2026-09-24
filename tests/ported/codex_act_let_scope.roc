# act-let-scope
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/act-let-scope.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     a: 2
#     a-after: 2
#     chain-in-body: 5
#     chain-b: 3
#     chain-c: 4
#     chain-d: 5
#     chain-sum: 14
#     shadowed: 100
#     shadowed-after: 100
#     arm-local: 23

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# ActLetScope -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bump : I64 -> I64
bump = |n| (n + 1)

arm_local : I64 -> I64
arm_local = |n| ({
	v : I64
	v = n
	w : I64
	w = (if (n > 0) { ({
		v_1 : I64
		v_1 = (n * 10)
		(v_1 + 1)
	}) } else { v })
	(w + v)
})

# --- Entry ---

main! = |_args| {
	({
		a : I64
		a = bump(1)
		({
			line!(CceText.printed(CceText.concat("a: ", CceText.show_int(a))))
			line!(CceText.printed(CceText.concat("a-after: ", CceText.show_int(a))))
			({
				b : I64
				b = bump(a)
				c : I64
				c = bump(b)
				d : I64
				d = bump(c)
				({
					line!(CceText.printed(CceText.concat("chain-in-body: ", CceText.show_int(d))))
					line!(CceText.printed(CceText.concat("chain-b: ", CceText.show_int(b))))
					line!(CceText.printed(CceText.concat("chain-c: ", CceText.show_int(c))))
					line!(CceText.printed(CceText.concat("chain-d: ", CceText.show_int(d))))
					line!(CceText.printed(CceText.concat("chain-sum: ", CceText.show_int((((a + b) + c) + d)))))
					({
						a_1 : I64
						a_1 = 100
						({
							line!(CceText.printed(CceText.concat("shadowed: ", CceText.show_int(a_1))))
							line!(CceText.printed(CceText.concat("shadowed-after: ", CceText.show_int(a_1))))
							line!(CceText.printed(CceText.concat("arm-local: ", CceText.show_int(arm_local(2)))))
						})
					})
				})
			})
		})
	})
	Ok({})
}
