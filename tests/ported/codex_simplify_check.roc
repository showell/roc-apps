# simplify-check
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/simplify-check.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     5
#     1
#     -4
#     7
#     5
#     42
#     100
#     9
#     2
#     10

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# SimplifyCheck -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

sc_fold : I64 -> I64
sc_fold = |_n| ({
	x = 2
	(x + 3)
})

sc_cmp : I64 -> I64
sc_cmp = |_n| ({
	m = 4
	(if (m < 10) { 1 } else { 0 })
})

sc_neg : I64 -> I64
sc_neg = |_n| ({
	a = 5
	((-a) + 1)
})

sc_bool : I64 -> I64
sc_bool = |_n| (if (True or False) { 7 } else { 8 })

sc_text : I64 -> I64
sc_text = |_n| Text.len([20, 13, 23, 23, 16])

sc_dead : I64 -> I64
sc_dead = |n| ({
	_u = (n + 1)
	(6 * 7)
})

sc_copy : I64 -> I64
sc_copy = |n| ({
	a = n
	b = a
	(b + 100)
})

sc_once : I64 -> I64
sc_once = |n| ({
	s = (n * n)
	(s + 9)
})

sc_cap : I64 -> I64
sc_cap = |n| ({
	x = n
	n_1 = (x + 1)
	(n_1 * 2)
})

sc_lamcap : I64 -> I64
sc_lamcap = |n| ({
	x = n
	lam_0(x, 10)
})

lam_0 : I64, I64 -> I64
lam_0 = |x, n_1| (x + n_1)

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.show_int(sc_fold(0))))
	line!(Text.printed(Text.show_int(sc_cmp(0))))
	line!(Text.printed(Text.show_int(sc_neg(0))))
	line!(Text.printed(Text.show_int(sc_bool(0))))
	line!(Text.printed(Text.show_int(sc_text(0))))
	line!(Text.printed(Text.show_int(sc_dead(0))))
	line!(Text.printed(Text.show_int(sc_copy(0))))
	line!(Text.printed(Text.show_int(sc_once(0))))
	line!(Text.printed(Text.show_int(sc_cap(0))))
	line!(Text.printed(Text.show_int(sc_lamcap(0))))
	Ok({})
}
