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
			line!(Text.printed(List.concat([15, 69, 2], Text.show_int(a))))
			line!(Text.printed(List.concat([15, 73, 15, 28, 14, 13, 21, 69, 2], Text.show_int(a))))
			({
				b = bump(a)
				c = bump(b)
				d = bump(c)
				({
					line!(Text.printed(List.concat([24, 20, 15, 17, 18, 73, 17, 18, 73, 32, 16, 22, 30, 69, 2], Text.show_int(d))))
					line!(Text.printed(List.concat([24, 20, 15, 17, 18, 73, 32, 69, 2], Text.show_int(b))))
					line!(Text.printed(List.concat([24, 20, 15, 17, 18, 73, 24, 69, 2], Text.show_int(c))))
					line!(Text.printed(List.concat([24, 20, 15, 17, 18, 73, 22, 69, 2], Text.show_int(d))))
					line!(Text.printed(List.concat([24, 20, 15, 17, 18, 73, 19, 25, 26, 69, 2], Text.show_int((((a + b) + c) + d)))))
					({
						a_1 = 100
						({
							line!(Text.printed(List.concat([19, 20, 15, 22, 16, 27, 13, 22, 69, 2], Text.show_int(a_1))))
							line!(Text.printed(List.concat([19, 20, 15, 22, 16, 27, 13, 22, 73, 15, 28, 14, 13, 21, 69, 2], Text.show_int(a_1))))
							line!(Text.printed(List.concat([15, 21, 26, 73, 23, 16, 24, 15, 23, 69, 2], Text.show_int(arm_local(2)))))
						})
					})
				})
			})
		})
	})
	Ok({})
}
