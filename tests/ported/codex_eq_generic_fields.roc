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

app [main!] {}

# EqGenericFields -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Pair(a) : [P(a, a)]
Holder(a, b) : [H(a, b)]
Plain : [Q(Str, Str)]

yn : Bool -> Str
yn = |b| (if b { "yes" } else { "no" })

eq_pair : Pair(a), Pair(a) -> Bool where [a.is_eq : a, a -> Bool]
eq_pair = |ex, ey| (match ex {
	P(exf0, exf1) => (match ey {
		P(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

eq_holder : Holder(a, b), Holder(a, b) -> Bool where [a.is_eq : a, a -> Bool, b.is_eq : b, b -> Bool]
eq_holder = |ex, ey| (match ex {
	H(exf0, exf1) => (match ey {
		H(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

eq_plain : Plain, Plain -> Bool
eq_plain = |ex, ey| (match ex {
	Q(exf0, exf1) => (match ey {
		Q(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Str.concat("text-control     : ", yn(("12" == I64.to_str(12)))))
	line!(Str.concat("concrete-control : ", yn(eq_plain(Q("12", "9"), Q(I64.to_str(12), "9")))))
	line!(Str.concat("one-param eq     : ", yn(eq_pair(P("12", "9"), P(I64.to_str(12), "9")))))
	line!(Str.concat("one-param ne     : ", yn(eq_pair(P("12", "9"), P(I64.to_str(13), "9")))))
	line!(Str.concat("second param     : ", yn(eq_holder(H(7, "12"), H(7, I64.to_str(12))))))
	line!(Str.concat("second param ne  : ", yn(eq_holder(H(7, "12"), H(8, I64.to_str(12))))))
	Ok({})
}
