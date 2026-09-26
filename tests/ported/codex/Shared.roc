# Shared -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Shared :: [].{
	SharedArray := { sa_base : I64, sa_count : I64 }.{
		is_eq : Shared.SharedArray, Shared.SharedArray -> Bool
		is_eq = |a, b| eq_SharedArray(a, b)
	}
	DynamicSharedArray := { dsa_base : I64 }.{
		is_eq : Shared.DynamicSharedArray, Shared.DynamicSharedArray -> Bool
		is_eq = |a, b| eq_DynamicSharedArray(a, b)
	}

	make_shared_array : I64, I64 -> Shared.SharedArray
	make_shared_array = |base, count| Shared.SharedArray.{ sa_base: base, sa_count: count }

	make_dynamic_shared : I64 -> Shared.DynamicSharedArray
	make_dynamic_shared = |base| Shared.DynamicSharedArray.{ dsa_base: base }

	eq_SharedArray : Shared.SharedArray, Shared.SharedArray -> Bool
	eq_SharedArray = |ex, ey| ((ex.sa_base == ey.sa_base) and (ex.sa_count == ey.sa_count))

	eq_DynamicSharedArray : Shared.DynamicSharedArray, Shared.DynamicSharedArray -> Bool
	eq_DynamicSharedArray = |ex, ey| (ex.dsa_base == ey.dsa_base)
}
