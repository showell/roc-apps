# A persistent vector: a tree of 32-slot nodes over leaves of 32 entries,
# the shape of Elm's Array without its tail -- every vector here has its
# size when it is made, so nothing grows.
#
# **A WRITE COPIES AT MOST ONE NODE A LEVEL.** Roc writes a list in place
# only while nothing else refers to it. When something does, `set` copies
# the nodes on the path to the entry, 32 entries each, and never the whole
# vector. A fresh vector shares one node a level, so it costs a handful of
# allocations however large it is, and a region leaves the sharing the
# first time it is written.
#
# **A NODE IS TAKEN OUT BEFORE IT IS WRITTEN.** `List.replace` hands the
# child over and leaves a placeholder, so the child is written while
# nothing else refers to it, then put back.
Vec :: [].{
	Tree(a) := [Leaf(List(a)), Node(List(Tree(a)))]

	# `n` entries; each child of the root covers `unit` of them, and a leaf
	# is a root whose `unit` is one.
	V(a) : { n : U64, unit : U64, root : Tree(a) }

	width : U64
	width = 32

	repeat : U64, a -> V(a)
	repeat = |n, fill| {
		unit = Vec.unit_for(n, 1)
		{ n: n, unit: unit, root: Vec.full(unit, fill) }
	}

	unit_for : U64, U64 -> U64
	unit_for = |n, u| if u * Vec.width >= n { u } else { Vec.unit_for(n, u * Vec.width) }

	full : U64, a -> Tree(a)
	full = |unit, fill|
		if unit == 1 { Leaf(List.repeat(fill, Vec.width)) } else { Node(List.repeat(Vec.full(U64.div_trunc_by(unit, Vec.width), fill), Vec.width)) }

	len : V(a) -> U64
	len = |v| v.n

	# `fill` past the end.
	get : V(a), U64, a -> a
	get = |v, i, fill| if i >= v.n { fill } else { Vec.get_in(v.root, v.unit, i, fill) }

	get_in : Tree(a), U64, U64, a -> a
	get_in = |t, unit, i, fill| match t {
		Leaf(xs) => List.get(xs, i) ?? fill
		Node(ks) => Vec.get_in(List.get(ks, U64.div_trunc_by(i, unit)) ?? Leaf([]), U64.div_trunc_by(unit, Vec.width), U64.rem_by(i, unit), fill)
	}

	# Unchanged past the end.
	set : V(a), U64, a -> V(a)
	set = |v, i, x| {
		{ n, unit, root } = v
		if i >= n { { n: n, unit: unit, root: root } } else { { n: n, unit: unit, root: Vec.set_in(root, unit, i, x) } }
	}

	set_in : Tree(a), U64, U64, a -> Tree(a)
	set_in = |t, unit, i, x| match t {
		Leaf(xs) => Leaf(List.set(xs, i, x) ?? crash("Vec.set: outside a leaf"))
		Node(ks) => {
			c = U64.div_trunc_by(i, unit)
			taken = List.replace(ks, c, Leaf([])) ?? crash("Vec.set: outside a node")
			Node(List.set(taken.list, c, Vec.set_in(taken.prev, U64.div_trunc_by(unit, Vec.width), U64.rem_by(i, unit), x)) ?? crash("Vec.set: outside a node"))
		}
	}

	# The entry at `i` handed over, `x` left in its place: a value that is
	# itself written (an array in a vector of arrays) is written while
	# nothing else refers to it, then set back. `fill` past the end.
	replace : V(a), U64, a, a -> { v : V(a), prev : a }
	replace = |v, i, x, fill| {
		{ n, unit, root } = v
		if i >= n {
			{ v: { n: n, unit: unit, root: root }, prev: fill }
		} else {
			r = Vec.replace_in(root, unit, i, x)
			{ v: { n: n, unit: unit, root: r.tree }, prev: r.prev }
		}
	}

	replace_in : Tree(a), U64, U64, a -> { tree : Tree(a), prev : a }
	replace_in = |t, unit, i, x| match t {
		Leaf(xs) => {
			r = List.replace(xs, i, x) ?? crash("Vec.replace: outside a leaf")
			{ tree: Leaf(r.list), prev: r.prev }
		}
		Node(ks) => {
			c = U64.div_trunc_by(i, unit)
			taken = List.replace(ks, c, Leaf([])) ?? crash("Vec.replace: outside a node")
			inner = Vec.replace_in(taken.prev, U64.div_trunc_by(unit, Vec.width), U64.rem_by(i, unit), x)
			{ tree: Node(List.set(taken.list, c, inner.tree) ?? crash("Vec.replace: outside a node")), prev: inner.prev }
		}
	}
}
