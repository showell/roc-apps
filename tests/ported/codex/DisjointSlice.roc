# DisjointSlice -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

DisjointSlice :: [].{
	DisjointSlice := { ds_base : I64, ds_length : I64 }.{
		is_eq : DisjointSlice.DisjointSlice, DisjointSlice.DisjointSlice -> Bool
		is_eq = |a, b| a.ds_base == b.ds_base and a.ds_length == b.ds_length
	}

	disjoint_from_buffer : I64, I64 -> DisjointSlice.DisjointSlice
	disjoint_from_buffer = |base, len| DisjointSlice.DisjointSlice.{ ds_base: base, ds_length: len }

	disjoint_length : DisjointSlice.DisjointSlice -> I64
	disjoint_length = |s| s.ds_length
}
