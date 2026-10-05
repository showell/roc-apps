# Maybe -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Maybe :: [].{
	Maybe(a) : [Just(a), None]

	eq_Maybe : Maybe.Maybe(a), Maybe.Maybe(a) -> Bool where [a.is_eq : a, a -> Bool]
	eq_Maybe = |ex, ey| (match ex {
		Just(exf0) => (match ey {
			Just(eyf0) => (exf0 == eyf0)
			_ => False
		})
		None => (match ey {
			None => True
			_ => False
		})
	})
}
