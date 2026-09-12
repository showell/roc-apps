# eq-generic-recursive
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/eq-generic-recursive.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     text-control   : yes
#     named-concrete : yes
#     pair-generic   : yes
#     box-text-eq    : yes
#     box-text-ne    : no
#     box-int-eq     : yes
#     box-int-ne     : no
#     box-nested     : yes
#     box-depth-ne   : no

app [main!] {}

# EqGenericRecursive -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Pair(a) : [P(a, a)]
Box_(a) := [Empty, Cell(a, Box_(a))].{
	is_eq : Box_(a), Box_(a) -> Bool where [a.is_eq : a, a -> Bool]
	is_eq = |a, b| eq_Box(a, b)
}
Named := [Nil, Node(Str, Named)].{
	is_eq : Named, Named -> Bool
	is_eq = |a, b| eq_Named(a, b)
}

yn : Bool -> Str
yn = |b| (if b { "yes" } else { "no" })

eq_Pair : Pair(a), Pair(a) -> Bool where [a.is_eq : a, a -> Bool]
eq_Pair = |ex, ey| (match ex {
	P(exf0, exf1) => (match ey {
		P(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

eq_Box : Box_(a), Box_(a) -> Bool where [a.is_eq : a, a -> Bool]
eq_Box = |ex, ey| (match ex {
	Empty => (match ey {
		Empty => True
		_ => False
	})
	Cell(exf0, exf1) => (match ey {
		Cell(eyf0, eyf1) => ((exf0 == eyf0) and eq_Box(exf1, eyf1))
		_ => False
	})
})

eq_Named : Named, Named -> Bool
eq_Named = |ex, ey| (match ex {
	Nil => (match ey {
		Nil => True
		_ => False
	})
	Node(exf0, exf1) => (match ey {
		Node(eyf0, eyf1) => ((exf0 == eyf0) and eq_Named(exf1, eyf1))
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Str.concat("text-control   : ", yn(("12" == I64.to_str(12)))))
	line!(Str.concat("named-concrete : ", yn(eq_Named(Node("12", Nil), Node(I64.to_str(12), Nil)))))
	line!(Str.concat("pair-generic   : ", yn(eq_Pair(P("12", "9"), P(I64.to_str(12), "9")))))
	line!(Str.concat("box-text-eq    : ", yn(eq_Box(Cell("12", Empty), Cell(I64.to_str(12), Empty)))))
	line!(Str.concat("box-text-ne    : ", yn(eq_Box(Cell("12", Empty), Cell(I64.to_str(13), Empty)))))
	line!(Str.concat("box-int-eq     : ", yn(eq_Box(Cell(12, Empty), Cell((6 + 6), Empty)))))
	line!(Str.concat("box-int-ne     : ", yn(eq_Box(Cell(12, Empty), Cell((6 + 7), Empty)))))
	line!(Str.concat("box-nested     : ", yn(eq_Box(Cell("12", Cell("9", Empty)), Cell(I64.to_str(12), Cell("9", Empty))))))
	line!(Str.concat("box-depth-ne   : ", yn(eq_Box(Cell("12", Cell("9", Empty)), Cell("12", Empty)))))
	Ok({})
}
