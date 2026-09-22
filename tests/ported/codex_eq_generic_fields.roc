# eq-generic-fields
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/eq-generic-fields.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     text-control     : yes
#     concrete-control : yes
#     one-param eq     : yes
#     one-param ne     : no
#     second param     : yes
#     second param ne  : no
#     one-param int eq : yes
#     one-param int ne : no
#     first param eq   : yes
#     first param ne   : no

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# EqGenericFields -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Pair(a) : [P(a, a)]
Holder(a, b) : [H(a, b)]
Plain : [Q(List(U8), List(U8))]

yn : Bool -> List(U8)
yn = |b| (if b { [30, 13, 19] } else { [18, 16] })

eq_Pair : Pair(a), Pair(a) -> Bool where [a.is_eq : a, a -> Bool]
eq_Pair = |ex, ey| (match ex {
	P(exf0, exf1) => (match ey {
		P(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

eq_Holder : Holder(a, b), Holder(a, b) -> Bool where [a.is_eq : a, a -> Bool, b.is_eq : b, b -> Bool]
eq_Holder = |ex, ey| (match ex {
	H(exf0, exf1) => (match ey {
		H(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

eq_Plain : Plain, Plain -> Bool
eq_Plain = |ex, ey| (match ex {
	Q(exf0, exf1) => (match ey {
		Q(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([14, 13, 36, 14, 73, 24, 16, 18, 14, 21, 16, 23, 2, 2, 2, 2, 2, 69, 2], yn(([4, 5] == Text.show_int(12))))))
	line!(Text.printed(List.concat([24, 16, 18, 24, 21, 13, 14, 13, 73, 24, 16, 18, 14, 21, 16, 23, 2, 69, 2], yn(eq_Plain(Q([4, 5], [12]), Q(Text.show_int(12), [12]))))))
	line!(Text.printed(List.concat([16, 18, 13, 73, 31, 15, 21, 15, 26, 2, 13, 37, 2, 2, 2, 2, 2, 69, 2], yn(eq_Pair(P([4, 5], [12]), P(Text.show_int(12), [12]))))))
	line!(Text.printed(List.concat([16, 18, 13, 73, 31, 15, 21, 15, 26, 2, 18, 13, 2, 2, 2, 2, 2, 69, 2], yn(eq_Pair(P([4, 5], [12]), P(Text.show_int(13), [12]))))))
	line!(Text.printed(List.concat([19, 13, 24, 16, 18, 22, 2, 31, 15, 21, 15, 26, 2, 2, 2, 2, 2, 69, 2], yn(eq_Holder(H(7, [4, 5]), H(7, Text.show_int(12)))))))
	line!(Text.printed(List.concat([19, 13, 24, 16, 18, 22, 2, 31, 15, 21, 15, 26, 2, 18, 13, 2, 2, 69, 2], yn(eq_Holder(H(7, [4, 5]), H(8, Text.show_int(12)))))))
	line!(Text.printed(List.concat([16, 18, 13, 73, 31, 15, 21, 15, 26, 2, 17, 18, 14, 2, 13, 37, 2, 69, 2], yn(eq_Pair(P(12, 9), P((6 + 6), 9))))))
	line!(Text.printed(List.concat([16, 18, 13, 73, 31, 15, 21, 15, 26, 2, 17, 18, 14, 2, 18, 13, 2, 69, 2], yn(eq_Pair(P(12, 9), P((6 + 7), 9))))))
	line!(Text.printed(List.concat([28, 17, 21, 19, 14, 2, 31, 15, 21, 15, 26, 2, 13, 37, 2, 2, 2, 69, 2], yn(eq_Holder(H([4, 5], 7), H(Text.show_int(12), 7))))))
	line!(Text.printed(List.concat([28, 17, 21, 19, 14, 2, 31, 15, 21, 15, 26, 2, 18, 13, 2, 2, 2, 69, 2], yn(eq_Holder(H([4, 5], 7), H(Text.show_int(13), 7))))))
	Ok({})
}
