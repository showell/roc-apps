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

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# EqGenericRecursive -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Pair(a) : [P(a, a)]
Box_(a) := [Empty, Cell(a, Box_(a))].{
	is_eq : Box_(a), Box_(a) -> Bool where [a.is_eq : a, a -> Bool]
	is_eq = |a, b| eq_Box(a, b)
}
Named := [Nil, Node(List(U8), Named)].{
	is_eq : Named, Named -> Bool
	is_eq = |a, b| eq_Named(a, b)
}

yn : Bool -> List(U8)
yn = |b| (if b { [30, 13, 19] } else { [18, 16] })

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
	line!(Text.printed(List.concat([14, 13, 36, 14, 73, 24, 16, 18, 14, 21, 16, 23, 2, 2, 2, 69, 2], yn(([4, 5] == Text.show_int(12))))))
	line!(Text.printed(List.concat([18, 15, 26, 13, 22, 73, 24, 16, 18, 24, 21, 13, 14, 13, 2, 69, 2], yn(eq_Named(Node([4, 5], Nil), Node(Text.show_int(12), Nil))))))
	line!(Text.printed(List.concat([31, 15, 17, 21, 73, 29, 13, 18, 13, 21, 17, 24, 2, 2, 2, 69, 2], yn(eq_Pair(P([4, 5], [12]), P(Text.show_int(12), [12]))))))
	line!(Text.printed(List.concat([32, 16, 36, 73, 14, 13, 36, 14, 73, 13, 37, 2, 2, 2, 2, 69, 2], yn(eq_Box(Cell([4, 5], Empty), Cell(Text.show_int(12), Empty))))))
	line!(Text.printed(List.concat([32, 16, 36, 73, 14, 13, 36, 14, 73, 18, 13, 2, 2, 2, 2, 69, 2], yn(eq_Box(Cell([4, 5], Empty), Cell(Text.show_int(13), Empty))))))
	line!(Text.printed(List.concat([32, 16, 36, 73, 17, 18, 14, 73, 13, 37, 2, 2, 2, 2, 2, 69, 2], yn(eq_Box(Cell(12, Empty), Cell((6 + 6), Empty))))))
	line!(Text.printed(List.concat([32, 16, 36, 73, 17, 18, 14, 73, 18, 13, 2, 2, 2, 2, 2, 69, 2], yn(eq_Box(Cell(12, Empty), Cell((6 + 7), Empty))))))
	line!(Text.printed(List.concat([32, 16, 36, 73, 18, 13, 19, 14, 13, 22, 2, 2, 2, 2, 2, 69, 2], yn(eq_Box(Cell([4, 5], Cell([12], Empty)), Cell(Text.show_int(12), Cell([12], Empty)))))))
	line!(Text.printed(List.concat([32, 16, 36, 73, 22, 13, 31, 14, 20, 73, 18, 13, 2, 2, 2, 69, 2], yn(eq_Box(Cell([4, 5], Cell([12], Empty)), Cell([4, 5], Empty))))))
	Ok({})
}
