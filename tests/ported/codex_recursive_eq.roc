# recursive-eq
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/recursive-eq.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     eq
#     eq
#     eq
#     ne
#     ne
#     eq
#     ne
#     eq
#     ne
#     ne
#     eq

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# RecursiveEq -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Nest := [Leaf, Wrap(Nest)].{
	is_eq : Nest, Nest -> Bool
	is_eq = |a, b| eq_Nest(a, b)
}
Chain := [End, Link(I64, Chain)].{
	is_eq : Chain, Chain -> Bool
	is_eq = |a, b| eq_Chain(a, b)
}

eq_Nest : Nest, Nest -> Bool
eq_Nest = |ex, ey| (match ex {
	Leaf => (match ey {
		Leaf => True
		_ => False
	})
	Wrap(exf0) => (match ey {
		Wrap(eyf0) => eq_Nest(exf0, eyf0)
		_ => False
	})
})

eq_Chain : Chain, Chain -> Bool
eq_Chain = |ex, ey| (match ex {
	End => (match ey {
		End => True
		_ => False
	})
	Link(exf0, exf1) => (match ey {
		Link(eyf0, eyf1) => ((exf0 == eyf0) and eq_Chain(exf1, eyf1))
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed((if eq_Nest(Wrap(Leaf), Wrap(Leaf)) { "eq" } else { "ne" })))
	line!(Text.printed((if eq_Nest(Wrap(Wrap(Leaf)), Wrap(Wrap(Leaf))) { "eq" } else { "ne" })))
	line!(Text.printed((if eq_Nest(Leaf, Leaf) { "eq" } else { "ne" })))
	line!(Text.printed((if eq_Nest(Wrap(Leaf), Leaf) { "eq" } else { "ne" })))
	line!(Text.printed((if eq_Nest(Wrap(Wrap(Leaf)), Wrap(Leaf)) { "eq" } else { "ne" })))
	line!(Text.printed((if (if eq_Nest(Wrap(Leaf), Wrap(Leaf)) { False } else { True }) { "ne" } else { "eq" })))
	line!(Text.printed((if (if eq_Nest(Wrap(Leaf), Leaf) { False } else { True }) { "ne" } else { "eq" })))
	line!(Text.printed((if eq_Chain(Link(1, Link(2, End)), Link(1, Link(2, End))) { "eq" } else { "ne" })))
	line!(Text.printed((if eq_Chain(Link(1, Link(2, End)), Link(1, Link(3, End))) { "eq" } else { "ne" })))
	line!(Text.printed((if eq_Chain(Link(1, Link(2, End)), Link(1, End)) { "eq" } else { "ne" })))
	line!(Text.printed((if eq_Chain(End, End) { "eq" } else { "ne" })))
	Ok({})
}
