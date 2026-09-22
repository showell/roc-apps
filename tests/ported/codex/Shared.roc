# Shared -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Shared :: [].{
	SharedArray : { sa_base : I64, sa_count : I64 }
	DynamicSharedArray : { dsa_base : I64 }

	make_shared_array : I64, I64 -> Shared.SharedArray
	make_shared_array = |base, count| { sa_base: base, sa_count: count }

	make_dynamic_shared : I64 -> Shared.DynamicSharedArray
	make_dynamic_shared = |base| { dsa_base: base }
}
