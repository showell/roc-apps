# Reservoir -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Random

Reservoir :: [].{
	ReservoirSample := { rs_items : List(I64), rs_capacity : I64, rs_count : I64, rs_seen : I64 }.{
		is_eq : Reservoir.ReservoirSample, Reservoir.ReservoirSample -> Bool
		is_eq = |a, b| eq_ReservoirSample(a, b)
	}

	reservoir_new : I64 -> Reservoir.ReservoirSample
	reservoir_new = |k| Reservoir.ReservoirSample.{ rs_items: [], rs_capacity: k, rs_count: 0, rs_seen: 0 }

	reservoir_add : Reservoir.ReservoirSample, I64, I64 -> Reservoir.ReservoirSample
	reservoir_add = |rs, item, seed| ({
		n : I64
		n = (rs.rs_seen + 1)
		(if (rs.rs_count < rs.rs_capacity) { Reservoir.ReservoirSample.{ rs_items: List.append(rs.rs_items, item), rs_capacity: rs.rs_capacity, rs_count: (rs.rs_count + 1), rs_seen: n } } else { ({
			j : I64
			j = reservoir_rand(seed, n)
			(if (j < rs.rs_capacity) { Reservoir.ReservoirSample.{ rs_items: (List.set(rs.rs_items, I64.to_u64_wrap(j), item) ?? crash("list-set-at past the end")), rs_capacity: rs.rs_capacity, rs_count: rs.rs_count, rs_seen: n } } else { Reservoir.ReservoirSample.{ rs_items: rs.rs_items, rs_capacity: rs.rs_capacity, rs_count: rs.rs_count, rs_seen: n } })
		}) })
	})

	reservoir_add_all : Reservoir.ReservoirSample, List(I64), I64, I64, I64 -> Reservoir.ReservoirSample
	reservoir_add_all = |rs, items, seed, i, len| (if (i >= len) { rs } else { reservoir_add_all(reservoir_add(rs, (List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), (seed + (i * 7919))), items, seed, (i + 1), len) })

	reservoir_rand : I64, I64 -> I64
	reservoir_rand = |seed, n| Random.rand_in_range(seed, n, 0, (n - 1))

	reservoir_items : Reservoir.ReservoirSample -> List(I64)
	reservoir_items = |rs| rs.rs_items

	reservoir_count : Reservoir.ReservoirSample -> I64
	reservoir_count = |rs| rs.rs_count

	reservoir_seen : Reservoir.ReservoirSample -> I64
	reservoir_seen = |rs| rs.rs_seen

	eq_ReservoirSample : Reservoir.ReservoirSample, Reservoir.ReservoirSample -> Bool
	eq_ReservoirSample = |ex, ey| ((((ex.rs_items == ey.rs_items) and (ex.rs_capacity == ey.rs_capacity)) and (ex.rs_count == ey.rs_count)) and (ex.rs_seen == ey.rs_seen))
}
