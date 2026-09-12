# rv-param-order
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/rv-param-order.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     bound: 3
#     swap: 3

app [main!] {}

# RvParamOrder -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
IntList := [INil, ICons(I64, IntList)].{
	is_eq : IntList, IntList -> Bool
	is_eq = |a, b| eq_intlist(a, b)
}

e_bound : I64, IntList -> I64
e_bound = |acc, xs| (match xs {
	ICons(_h, t) => e_bound((acc + 1), t)
	INil => acc
})

e_swap : IntList, I64 -> I64
e_swap = |xs, acc| (match xs {
	ICons(_h, t) => e_swap(t, (acc + 1))
	INil => acc
})

three : IntList
three = ICons(1, ICons(2, ICons(3, INil)))

eq_intlist : IntList, IntList -> Bool
eq_intlist = |ex, ey| (match ex {
	INil => (match ey {
		INil => True
		_ => False
	})
	ICons(exf0, exf1) => (match ey {
		ICons(eyf0, eyf1) => ((exf0 == eyf0) and eq_intlist(exf1, eyf1))
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Str.concat("bound: ", I64.to_str(e_bound(0, three))))
	line!(Str.concat("swap: ", I64.to_str(e_swap(three, 0))))
	Ok({})
}
