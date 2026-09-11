# Tuple -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Tuple :: [].{
	Tup2(a, b) : [MkTup2(a, b)]
	Tup3(a, b, c) : [MkTup3(a, b, c)]
	Tup4(a, b, c, d) : [MkTup4(a, b, c, d)]
	Tup5(a, b, c, d, e) : [MkTup5(a, b, c, d, e)]

	pair_first : Tuple.Tup2(a, b) -> a
	pair_first = |p| (match p {
		MkTup2(x, _y) => x
	})

	pair_second : Tuple.Tup2(a, b) -> b
	pair_second = |p| (match p {
		MkTup2(_x, y) => y
	})
}
