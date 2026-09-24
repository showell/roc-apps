# ir-check-clean
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ir-check-clean.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     shadow: 12
#     apply-twice: 20
#     capture: 18
#     tree-sum: 12
#     manhattan: 7
#     total: 15
#     text: ir-check

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Prelude

# IRCheckClean -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Tree := [Leaf(I64), Node(Tree, Tree)].{
	is_eq : Tree, Tree -> Bool
	is_eq = |a, b| eq_Tree(a, b)
}
Point := { x : I64, y : I64 }.{
	is_eq : Point, Point -> Bool
	is_eq = |a, b| a.x == b.x and a.y == b.y
}

shadow : I64 -> I64
shadow = |x| ({
	x_1 : I64
	x_1 = (x + 1)
	y : I64
	y = (x_1 * 2)
	(y + x_1)
})

apply_twice : I64 -> I64
apply_twice = |n| ({
	f = lam_0
	f(f(n))
})

capture : I64 -> I64
capture = |n| ({
	k : I64
	k = (n + 5)
	g = ({
		dev__1 = k
		|dev__2| lam_1(dev__1, dev__2)
	})
	g(3)
})

tree_sum : Tree -> I64
tree_sum = |t| (match t {
	Leaf(v) => v
	Node(l, r) => (tree_sum(l) + tree_sum(r))
})

sample_tree : Tree
sample_tree = Node(Leaf(3), Node(Leaf(4), Leaf(5)))

manhattan : Point -> I64
manhattan = |p| (Prelude.int_abs(p.x) + Prelude.int_abs(p.y))

total : List(I64) -> I64
total = |xs| total_loop(xs, 0, U64.to_i64_wrap(List.len(xs)), 0)

total_loop : List(I64), I64, I64, I64 -> I64
total_loop = |xs, i, len, acc| (if (i >= len) { acc } else { total_loop(xs, (i + 1), len, (acc + (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

eq_Tree : Tree, Tree -> Bool
eq_Tree = |ex, ey| (match ex {
	Leaf(exf0) => (match ey {
		Leaf(eyf0) => (exf0 == eyf0)
		_ => False
	})
	Node(exf0, exf1) => (match ey {
		Node(eyf0, eyf1) => (eq_Tree(exf0, eyf0) and eq_Tree(exf1, eyf1))
		_ => False
	})
})

lam_0 : I64 -> I64
lam_0 = |a| (a + a)

lam_1 : I64, I64 -> I64
lam_1 = |k, a| (a * k)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("shadow: ", CceText.show_int(shadow(3)))))
	line!(CceText.printed(CceText.concat("apply-twice: ", CceText.show_int(apply_twice(5)))))
	line!(CceText.printed(CceText.concat("capture: ", CceText.show_int(capture(1)))))
	line!(CceText.printed(CceText.concat("tree-sum: ", CceText.show_int(tree_sum(sample_tree)))))
	line!(CceText.printed(CceText.concat("manhattan: ", CceText.show_int(manhattan(Point.{ x: (0 - 3), y: 4 })))))
	line!(CceText.printed(CceText.concat("total: ", CceText.show_int(total([1, 2, 3, 4, 5])))))
	line!(CceText.printed(CceText.concat("text: ", CceText.concat(CceText.concat("ir", "-"), "check"))))
	Ok({})
}
