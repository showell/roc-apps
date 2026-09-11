# Maybe -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Maybe :: [].{
	Maybe(a) : [Just(a), None]

	from_maybe : Maybe.Maybe(a), a -> a
	from_maybe = |m, default| (match m {
		Just(x) => x
		None => default
	})

	is_just : Maybe.Maybe(a) -> Bool
	is_just = |m| (match m {
		Just(_x) => True
		None => False
	})

	is_none : Maybe.Maybe(a) -> Bool
	is_none = |m| (match m {
		Just(_x) => False
		None => True
	})

	maybe_map : (a -> b), Maybe.Maybe(a) -> Maybe.Maybe(b)
	maybe_map = |f, m| (match m {
		Just(x) => Just(f(x))
		None => None
	})

	maybe_bind : Maybe.Maybe(a), (a -> Maybe.Maybe(b)) -> Maybe.Maybe(b)
	maybe_bind = |m, f| (match m {
		Just(x) => f(x)
		None => None
	})
}
