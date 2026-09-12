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

	eq_tup2 : Tuple.Tup2(a, b), Tuple.Tup2(a, b) -> Bool where [a.is_eq : a, a -> Bool, b.is_eq : b, b -> Bool]
	eq_tup2 = |ex, ey| (match ex {
		MkTup2(exf0, exf1) => (match ey {
			MkTup2(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
	})

	eq_tup3 : Tuple.Tup3(a, b, c), Tuple.Tup3(a, b, c) -> Bool where [a.is_eq : a, a -> Bool, b.is_eq : b, b -> Bool, c.is_eq : c, c -> Bool]
	eq_tup3 = |ex, ey| (match ex {
		MkTup3(exf0, exf1, exf2) => (match ey {
			MkTup3(eyf0, eyf1, eyf2) => (((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2))
			_ => False
		})
	})

	eq_tup4 : Tuple.Tup4(a, b, c, d), Tuple.Tup4(a, b, c, d) -> Bool where [a.is_eq : a, a -> Bool, b.is_eq : b, b -> Bool, c.is_eq : c, c -> Bool, d.is_eq : d, d -> Bool]
	eq_tup4 = |ex, ey| (match ex {
		MkTup4(exf0, exf1, exf2, exf3) => (match ey {
			MkTup4(eyf0, eyf1, eyf2, eyf3) => ((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3))
			_ => False
		})
	})

	eq_tup5 : Tuple.Tup5(a, b, c, d, e), Tuple.Tup5(a, b, c, d, e) -> Bool where [a.is_eq : a, a -> Bool, b.is_eq : b, b -> Bool, c.is_eq : c, c -> Bool, d.is_eq : d, d -> Bool, e.is_eq : e, e -> Bool]
	eq_tup5 = |ex, ey| (match ex {
		MkTup5(exf0, exf1, exf2, exf3, exf4) => (match ey {
			MkTup5(eyf0, eyf1, eyf2, eyf3, eyf4) => (((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3)) and (exf4 == eyf4))
			_ => False
		})
	})
}
