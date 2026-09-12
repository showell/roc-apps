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

app [main!] {}

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
			line!(Str.concat("a: ", I64.to_str(a)))
			line!(Str.concat("a-after: ", I64.to_str(a)))
			({
				b = bump(a)
				c = bump(b)
				d = bump(c)
				({
					line!(Str.concat("chain-in-body: ", I64.to_str(d)))
					line!(Str.concat("chain-b: ", I64.to_str(b)))
					line!(Str.concat("chain-c: ", I64.to_str(c)))
					line!(Str.concat("chain-d: ", I64.to_str(d)))
					line!(Str.concat("chain-sum: ", I64.to_str((((a + b) + c) + d))))
					({
						a_1 = 100
						({
							line!(Str.concat("shadowed: ", I64.to_str(a_1)))
							line!(Str.concat("shadowed-after: ", I64.to_str(a_1)))
							line!(Str.concat("arm-local: ", I64.to_str(arm_local(2))))
						})
					})
				})
			})
		})
	})
	Ok({})
}
