# deriving-eq-recursive
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/deriving-eq-recursive.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     eq
#     ne
#     eq
#     eq
#     ne
#     eq

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# DerivingEqRecursive -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Tree := [Leaf, Fork(Tree, Tree)].{
	is_eq : Tree, Tree -> Bool
	is_eq = |a, b| eq_Tree(a, b)
}

leaf : Tree
leaf = Leaf

mk_fork : Tree, Tree -> Tree
mk_fork = |l, r| Fork(l, r)

pair_tree : Tree
pair_tree = mk_fork(leaf, leaf)

nested_tree : Tree
nested_tree = mk_fork(mk_fork(leaf, leaf), leaf)

eq_Tree : Tree, Tree -> Bool
eq_Tree = |ex, ey| (match ex {
	Leaf => (match ey {
		Leaf => True
		_ => False
	})
	Fork(exf0, exf1) => (match ey {
		Fork(eyf0, eyf1) => (eq_Tree(exf0, eyf0) and eq_Tree(exf1, eyf1))
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed((if eq_Tree(pair_tree, mk_fork(leaf, leaf)) { "eq" } else { "ne" })))
	line!(Text.printed((if eq_Tree(pair_tree, leaf) { "eq" } else { "ne" })))
	line!(Text.printed((if eq_Tree(leaf, leaf) { "eq" } else { "ne" })))
	line!(Text.printed((if eq_Tree(nested_tree, mk_fork(mk_fork(leaf, leaf), leaf)) { "eq" } else { "ne" })))
	line!(Text.printed((if eq_Tree(nested_tree, pair_tree) { "eq" } else { "ne" })))
	line!(Text.printed((if eq_Tree(pair_tree, pair_tree) { "eq" } else { "ne" })))
	Ok({})
}
