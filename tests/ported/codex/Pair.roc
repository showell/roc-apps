# Pair -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Pair :: [].{
	Pair(a, b) : { fst : a, snd : b }

	make_pair : a, b -> Pair.Pair(a, b)
	make_pair = |x, y| { fst: x, snd: y }

	pair_fst : Pair.Pair(a, b) -> a
	pair_fst = |p| p.fst

	pair_snd : Pair.Pair(a, b) -> b
	pair_snd = |p| p.snd

	swap : Pair.Pair(a, b) -> Pair.Pair(b, a)
	swap = |p| { fst: p.snd, snd: p.fst }
}
