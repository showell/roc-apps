# DisjointSlice -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

DisjointSlice :: [].{
	DisjointSlice := { ds_base : I64, ds_length : I64 }.{
		is_eq : DisjointSlice.DisjointSlice, DisjointSlice.DisjointSlice -> Bool
		is_eq = |a, b| eq_DisjointSlice(a, b)
	}

	disjoint_from_buffer : I64, I64 -> DisjointSlice.DisjointSlice
	disjoint_from_buffer = |base, len| DisjointSlice.DisjointSlice.{ ds_base: base, ds_length: len }

	disjoint_length : DisjointSlice.DisjointSlice -> I64
	disjoint_length = |s| s.ds_length

	eq_DisjointSlice : DisjointSlice.DisjointSlice, DisjointSlice.DisjointSlice -> Bool
	eq_DisjointSlice = |ex, ey| ((ex.ds_base == ey.ds_base) and (ex.ds_length == ey.ds_length))
}
