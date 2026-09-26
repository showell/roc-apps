# KvStore -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import Hamt
import MathLib
import Maybe

KvStore :: [].{
	KvStore := { kv_data : Hamt.HamtMap(CceText), kv_count : I64 }.{
		is_eq : KvStore.KvStore, KvStore.KvStore -> Bool
		is_eq = |a, b| eq_KvStore(a, b)
	}

	kv_empty : KvStore.KvStore
	kv_empty = KvStore.KvStore.{ kv_data: Hamt.hamt_empty, kv_count: 0 }

	kv_singleton : CceText, CceText -> KvStore.KvStore
	kv_singleton = |key, val| KvStore.KvStore.{ kv_data: Hamt.hamt_set(Hamt.hamt_empty, key, val), kv_count: 1 }

	kv_get : KvStore.KvStore, CceText -> Maybe.Maybe(CceText)
	kv_get = |store, key| Hamt.hamt_get(store.kv_data, key)

	kv_put : KvStore.KvStore, CceText, CceText -> KvStore.KvStore
	kv_put = |store, key, val| ({
		existing = Hamt.hamt_get(store.kv_data, key)
		new_data = Hamt.hamt_set(store.kv_data, key, val)
		KvStore.KvStore.{ kv_data: new_data, kv_count: (match existing {
			Just(_v) => store.kv_count
			None => (store.kv_count + 1)
		}) }
	})

	kv_delete : KvStore.KvStore, CceText -> KvStore.KvStore
	kv_delete = |store, key| ({
		existing = Hamt.hamt_get(store.kv_data, key)
		(match existing {
			None => store
			Just(_v) => KvStore.KvStore.{ kv_data: Hamt.hamt_remove(store.kv_data, key), kv_count: (store.kv_count - 1) }
		})
	})

	kv_has : KvStore.KvStore, CceText -> Bool
	kv_has = |store, key| ({
		found = Hamt.hamt_get(store.kv_data, key)
		(match found {
			Just(_v) => True
			None => False
		})
	})

	kv_get_or : KvStore.KvStore, CceText, CceText -> CceText
	kv_get_or = |store, key, default| ({
		found = Hamt.hamt_get(store.kv_data, key)
		(match found {
			Just(v) => v
			None => default
		})
	})

	kv_put_all : KvStore.KvStore, List(CceText), List(CceText) -> KvStore.KvStore
	kv_put_all = |store, keys, vals| kv_put_all_loop(store, keys, vals, 0, MathLib.math_min(U64.to_i64_wrap(List.len(keys)), U64.to_i64_wrap(List.len(vals))))

	kv_put_all_loop : KvStore.KvStore, List(CceText), List(CceText), I64, I64 -> KvStore.KvStore
	kv_put_all_loop = |store, keys, vals, i, n| (if (i >= n) { store } else { kv_put_all_loop(kv_put(store, (List.get(keys, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), (List.get(vals, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), keys, vals, (i + 1), n) })

	kv_size : KvStore.KvStore -> I64
	kv_size = |store| store.kv_count

	kv_is_empty : KvStore.KvStore -> Bool
	kv_is_empty = |store| (store.kv_count == 0)

	format_kv : KvStore.KvStore, CceText -> CceText
	format_kv = |store, key| ({
		found = kv_get(store, key)
		(match found {
			Just(v) => CceText.concat(CceText.concat(key, "="), v)
			None => CceText.concat(key, "=<none>")
		})
	})

	eq_KvStore : KvStore.KvStore, KvStore.KvStore -> Bool
	eq_KvStore = |ex, ey| ((ex.kv_data == ey.kv_data) and (ex.kv_count == ey.kv_count))
}
