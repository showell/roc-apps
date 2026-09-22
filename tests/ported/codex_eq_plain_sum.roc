# eq-plain-sum
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/eq-plain-sum.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     both eq : yes
#     both ne : yes
#     text eq : yes
#     cross ne : yes
#     sum field eq : yes
#     sum field ne : yes

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# EqPlainSum -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Pair : [Both(I64, I64), JustText(List(U8)), Neither]
Holder : [Wraps(Pair), Empty]

eq_Pair : Pair, Pair -> Bool
eq_Pair = |ex, ey| (match ex {
	Both(exf0, exf1) => (match ey {
		Both(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
	JustText(exf0) => (match ey {
		JustText(eyf0) => (exf0 == eyf0)
		_ => False
	})
	Neither => (match ey {
		Neither => True
		_ => False
	})
})

eq_Holder : Holder, Holder -> Bool
eq_Holder = |ex, ey| (match ex {
	Wraps(exf0) => (match ey {
		Wraps(eyf0) => eq_Pair(exf0, eyf0)
		_ => False
	})
	Empty => (match ey {
		Empty => True
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed((if eq_Pair(Both(1, 2), Both(1, 2)) { [32, 16, 14, 20, 2, 13, 37, 2, 69, 2, 30, 13, 19] } else { [32, 16, 14, 20, 2, 13, 37, 2, 69, 2, 18, 16] })))
	line!(Text.printed((if eq_Pair(Both(1, 2), Both(1, 3)) { [32, 16, 14, 20, 2, 18, 13, 2, 69, 2, 18, 16] } else { [32, 16, 14, 20, 2, 18, 13, 2, 69, 2, 30, 13, 19] })))
	line!(Text.printed((if eq_Pair(JustText([15]), JustText([15])) { [14, 13, 36, 14, 2, 13, 37, 2, 69, 2, 30, 13, 19] } else { [14, 13, 36, 14, 2, 13, 37, 2, 69, 2, 18, 16] })))
	line!(Text.printed((if eq_Pair(Both(1, 2), Neither) { [24, 21, 16, 19, 19, 2, 18, 13, 2, 69, 2, 18, 16] } else { [24, 21, 16, 19, 19, 2, 18, 13, 2, 69, 2, 30, 13, 19] })))
	line!(Text.printed((if eq_Holder(Wraps(Both(1, 2)), Wraps(Both(1, 2))) { [19, 25, 26, 2, 28, 17, 13, 23, 22, 2, 13, 37, 2, 69, 2, 30, 13, 19] } else { [19, 25, 26, 2, 28, 17, 13, 23, 22, 2, 13, 37, 2, 69, 2, 18, 16] })))
	line!(Text.printed((if eq_Holder(Wraps(Both(1, 2)), Wraps(JustText([15]))) { [19, 25, 26, 2, 28, 17, 13, 23, 22, 2, 18, 13, 2, 69, 2, 18, 16] } else { [19, 25, 26, 2, 28, 17, 13, 23, 22, 2, 18, 13, 2, 69, 2, 30, 13, 19] })))
	Ok({})
}
