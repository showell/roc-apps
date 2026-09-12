# when-arm-nontail
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/when-arm-nontail.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     map-sum: 30
#     filter-sum: 6
#     tail-loop: 115

app [main!] {}

# WhenArmNonTail -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
IntList := [INil, ICons(I64, IntList)].{
	is_eq : IntList, IntList -> Bool
	is_eq = |a, b| eq_intlist(a, b)
}

is_even : I64 -> Bool
is_even = |n| ((I64.div_trunc_by(n, 2) * 2) == n)

dbl : I64 -> I64
dbl = |n| (n * 2)

my_sum : IntList -> I64
my_sum = |xs| (match xs {
	ICons(h, t) => (h + my_sum(t))
	INil => 0
})

my_map : (I64 -> I64), IntList -> IntList
my_map = |f, xs| (match xs {
	ICons(h, t) => ICons(f(h), my_map(f, t))
	INil => INil
})

my_filter : (I64 -> Bool), IntList -> IntList
my_filter = |pred, xs| (match xs {
	ICons(h, t) => (if pred(h) { ICons(h, my_filter(pred, t)) } else { my_filter(pred, t) })
	INil => INil
})

sum_real : IntList, I64 -> I64
sum_real = |xs, acc| (match xs {
	ICons(h, t) => sum_real(t, (acc + h))
	INil => acc
})

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
	({
		nums = ICons(1, ICons(2, ICons(3, ICons(4, ICons(5, INil)))))
		({
			line!(Str.concat("map-sum: ", I64.to_str(my_sum(my_map(dbl, nums)))))
			line!(Str.concat("filter-sum: ", I64.to_str(my_sum(my_filter(is_even, nums)))))
			line!(Str.concat("tail-loop: ", I64.to_str(sum_real(nums, 100))))
		})
	})
	Ok({})
}
