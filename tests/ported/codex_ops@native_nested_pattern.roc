# ops@native-nested-pattern
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@native-nested-pattern.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     3000
#     304
#     -1
#     -1
#     1
#     -700
#     1234
#     -1
#     -1
#     2042
#     -1
#     -9
#     11
#     -1
#     104
#     1
#     2

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# NativeNestedPattern -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Tree := [Leaf(I64), Join(Tree, Tree), Tip].{
	is_eq : Tree, Tree -> Bool
	is_eq = |a, b| eq_Tree(a, b)
}
Packed : [Pack(I64, Tree, Bool, I64), Blank]
Box_(a) : [Wrapped(a)]

boxed_text : Box_(CceText) -> I64
boxed_text = |value| (match value {
	Wrapped("hi") => 1
	_ => 2
})

siblings : Tree -> I64
siblings = |v| (match v {
	Join(Leaf(a), Leaf(0)) if (I64.div_trunc_by(100, a) > 0) => (a * 1000)
	Join(Leaf(a), Leaf(b)) => ((a * 100) + b)
	_ => (0 - 1)
})

wide : Tree -> I64
wide = |v| (match v {
	Join(Join(Leaf(a), Leaf(b)), Join(Leaf(c), Leaf(d))) => ((((a * 1000) + (b * 100)) + (c * 10)) + d)
	_ => (0 - 1)
})

packed : Packed -> I64
packed = |v| (match v {
	Pack(first, Join(Leaf(a), Leaf(b)), True, last) => (((first + (a * 1000)) + (b * 10)) + last)
	Pack(first, Leaf(x), flag, last) => (if flag { ((x + first) + last) } else { (0 - x) })
	_ => (0 - 1)
})

scope : Tree -> I64
scope = |v| ({
	n : I64
	n = 99
	result : I64
	result = (match v {
		Join(Leaf(n_1), Leaf(m)) => (n_1 + m)
		_ => 0
	})
	(n + result)
})

eq_Tree : Tree, Tree -> Bool
eq_Tree = |ex, ey| (match ex {
	Leaf(exf0) => (match ey {
		Leaf(eyf0) => (exf0 == eyf0)
		_ => False
	})
	Join(exf0, exf1) => (match ey {
		Join(eyf0, eyf1) => (eq_Tree(exf0, eyf0) and eq_Tree(exf1, eyf1))
		_ => False
	})
	Tip => (match ey {
		Tip => True
		_ => False
	})
})

eq_Packed : Packed, Packed -> Bool
eq_Packed = |ex, ey| (match ex {
	Pack(exf0, exf1, exf2, exf3) => (match ey {
		Pack(eyf0, eyf1, eyf2, eyf3) => ((((exf0 == eyf0) and eq_Tree(exf1, eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3))
		_ => False
	})
	Blank => (match ey {
		Blank => True
		_ => False
	})
})

eq_Box : Box_(a), Box_(a) -> Bool where [a.is_eq : a, a -> Bool]
eq_Box = |ex, ey| (match ex {
	Wrapped(exf0) => (match ey {
		Wrapped(eyf0) => (exf0 == eyf0)
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.show_int(siblings(Join(Leaf(3), Leaf(0))))))
	line!(CceText.printed(CceText.show_int(siblings(Join(Leaf(3), Leaf(4))))))
	line!(CceText.printed(CceText.show_int(siblings(Join(Tip, Leaf(0))))))
	line!(CceText.printed(CceText.show_int(siblings(Join(Leaf(0), Tip)))))
	line!(CceText.printed(CceText.show_int(siblings(Join(Leaf(0), Leaf(1))))))
	line!(CceText.printed(CceText.show_int(siblings(Join(Leaf((0 - 7)), Leaf(0))))))
	line!(CceText.printed(CceText.show_int(wide(Join(Join(Leaf(1), Leaf(2)), Join(Leaf(3), Leaf(4)))))))
	line!(CceText.printed(CceText.show_int(wide(Join(Join(Leaf(1), Tip), Join(Leaf(3), Leaf(4)))))))
	line!(CceText.printed(CceText.show_int(wide(Join(Join(Leaf(1), Leaf(2)), Join(Leaf(3), Tip))))))
	line!(CceText.printed(CceText.show_int(packed(Pack(7, Join(Leaf(2), Leaf(4)), True, (0 - 5))))))
	line!(CceText.printed(CceText.show_int(packed(Pack(7, Join(Leaf(2), Leaf(4)), False, (0 - 5))))))
	line!(CceText.printed(CceText.show_int(packed(Pack(7, Leaf(9), False, (0 - 5))))))
	line!(CceText.printed(CceText.show_int(packed(Pack(7, Leaf(9), True, (0 - 5))))))
	line!(CceText.printed(CceText.show_int(packed(Blank))))
	line!(CceText.printed(CceText.show_int(scope(Join(Leaf(2), Leaf(3))))))
	line!(CceText.printed(CceText.show_int(boxed_text(Wrapped("hi")))))
	line!(CceText.printed(CceText.show_int(boxed_text(Wrapped("bye")))))
	Ok({})
}
