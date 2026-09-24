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

import cdx.CceText

# EqPlainSum -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Pair : [Both(I64, I64), JustText(CceText), Neither]
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
	line!(CceText.printed((if eq_Pair(Both(1, 2), Both(1, 2)) { "both eq : yes" } else { "both eq : no" })))
	line!(CceText.printed((if eq_Pair(Both(1, 2), Both(1, 3)) { "both ne : no" } else { "both ne : yes" })))
	line!(CceText.printed((if eq_Pair(JustText("a"), JustText("a")) { "text eq : yes" } else { "text eq : no" })))
	line!(CceText.printed((if eq_Pair(Both(1, 2), Neither) { "cross ne : no" } else { "cross ne : yes" })))
	line!(CceText.printed((if eq_Holder(Wraps(Both(1, 2)), Wraps(Both(1, 2))) { "sum field eq : yes" } else { "sum field eq : no" })))
	line!(CceText.printed((if eq_Holder(Wraps(Both(1, 2)), Wraps(JustText("a"))) { "sum field ne : no" } else { "sum field ne : yes" })))
	Ok({})
}
