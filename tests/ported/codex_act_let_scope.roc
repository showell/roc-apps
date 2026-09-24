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

import cdx.Text

# ActLetScope -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bump : I64 -> I64
bump = |n| (n + 1)

arm_local : I64 -> I64
arm_local = |n| ({
	v = n
	w = (if (n > 0) { ({
		v_1 = (n * 10)
		(v_1 + 1)
	}) } else { v })
	(w + v)
})

# --- Entry ---

main! = |_args| {
	({
		a = bump(1)
		({
			line!(Text.printed(Text.concat("a: ", Text.show_int(a))))
			line!(Text.printed(Text.concat("a-after: ", Text.show_int(a))))
			({
				b = bump(a)
				c = bump(b)
				d = bump(c)
				({
					line!(Text.printed(Text.concat("chain-in-body: ", Text.show_int(d))))
					line!(Text.printed(Text.concat("chain-b: ", Text.show_int(b))))
					line!(Text.printed(Text.concat("chain-c: ", Text.show_int(c))))
					line!(Text.printed(Text.concat("chain-d: ", Text.show_int(d))))
					line!(Text.printed(Text.concat("chain-sum: ", Text.show_int((((a + b) + c) + d)))))
					({
						a_1 = 100
						({
							line!(Text.printed(Text.concat("shadowed: ", Text.show_int(a_1))))
							line!(Text.printed(Text.concat("shadowed-after: ", Text.show_int(a_1))))
							line!(Text.printed(Text.concat("arm-local: ", Text.show_int(arm_local(2)))))
						})
					})
				})
			})
		})
	})
	Ok({})
}
