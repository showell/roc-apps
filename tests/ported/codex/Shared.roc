# Shared -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Shared :: [].{
	SharedArray := { sa_base : I64, sa_count : I64 }.{
		is_eq : Shared.SharedArray, Shared.SharedArray -> Bool
		is_eq = |a, b| a.sa_base == b.sa_base and a.sa_count == b.sa_count
	}
	DynamicSharedArray := { dsa_base : I64 }.{
		is_eq : Shared.DynamicSharedArray, Shared.DynamicSharedArray -> Bool
		is_eq = |a, b| a.dsa_base == b.dsa_base
	}

	make_shared_array : I64, I64 -> Shared.SharedArray
	make_shared_array = |base, count| Shared.SharedArray.{ sa_base: base, sa_count: count }

	make_dynamic_shared : I64 -> Shared.DynamicSharedArray
	make_dynamic_shared = |base| Shared.DynamicSharedArray.{ dsa_base: base }
}
