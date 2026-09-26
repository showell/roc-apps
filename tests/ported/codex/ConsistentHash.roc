# ConsistentHash -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceChar
import CceText
import Random

ConsistentHash :: [].{
	HashRingEntry := { hr_hash : I64, hr_node : I64 }.{
		is_eq : ConsistentHash.HashRingEntry, ConsistentHash.HashRingEntry -> Bool
		is_eq = |a, b| eq_HashRingEntry(a, b)
	}
	ConsistentHashRing := { hr_entries : List(ConsistentHash.HashRingEntry), hr_count : I64, hr_vnodes : I64 }.{
		is_eq : ConsistentHash.ConsistentHashRing, ConsistentHash.ConsistentHashRing -> Bool
		is_eq = |a, b| eq_ConsistentHashRing(a, b)
	}

	chr_new : I64 -> ConsistentHash.ConsistentHashRing
	chr_new = |vnodes| ConsistentHash.ConsistentHashRing.{ hr_entries: [], hr_count: 0, hr_vnodes: vnodes }

	chr_add_node : ConsistentHash.ConsistentHashRing, I64 -> ConsistentHash.ConsistentHashRing
	chr_add_node = |ring, node_id| chr_add_vnodes(ring, node_id, 0, ring.hr_vnodes)

	chr_add_vnodes : ConsistentHash.ConsistentHashRing, I64, I64, I64 -> ConsistentHash.ConsistentHashRing
	chr_add_vnodes = |ring, node_id, i, limit| (if (i >= limit) { ring } else { ({
		h : I64
		h = chr_hash_pair(node_id, i)
		entry = ConsistentHash.HashRingEntry.{ hr_hash: h, hr_node: node_id }
		pos : I64
		pos = chr_find_insert(ring.hr_entries, h, 0, ring.hr_count)
		new_entries = chr_insert_at(ring.hr_entries, pos, entry, ring.hr_count)
		chr_add_vnodes(ConsistentHash.ConsistentHashRing.{ hr_entries: new_entries, hr_count: (ring.hr_count + 1), hr_vnodes: ring.hr_vnodes }, node_id, (i + 1), limit)
	}) })

	chr_find_insert : List(ConsistentHash.HashRingEntry), I64, I64, I64 -> I64
	chr_find_insert = |entries, h, i, len| (if (i >= len) { len } else { (if ((List.get(entries, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).hr_hash > h) { i } else { chr_find_insert(entries, h, (i + 1), len) }) })

	chr_insert_at : List(ConsistentHash.HashRingEntry), I64, ConsistentHash.HashRingEntry, I64 -> List(ConsistentHash.HashRingEntry)
	chr_insert_at = |entries, pos, entry, len| chr_splice(entries, pos, entry, 0, len, [])

	chr_splice : List(ConsistentHash.HashRingEntry), I64, ConsistentHash.HashRingEntry, I64, I64, List(ConsistentHash.HashRingEntry) -> List(ConsistentHash.HashRingEntry)
	chr_splice = |entries, pos, entry, i, len, acc| (if (i > len) { acc } else { (if (i == pos) { chr_splice(entries, pos, entry, (i + 1), len, List.append(List.append(acc, entry), (if (i < len) { (List.get(entries, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) } else { entry }))) } else { (if (i < len) { chr_splice(entries, pos, entry, (i + 1), len, List.append(acc, (List.get(entries, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) } else { acc }) }) })

	chr_get_node : ConsistentHash.ConsistentHashRing, I64 -> I64
	chr_get_node = |ring, key| (if (ring.hr_count == 0) { (0 - 1) } else { ({
		h : I64
		h = chr_hash_key(key)
		chr_find_node(ring.hr_entries, h, 0, ring.hr_count)
	}) })

	chr_find_node : List(ConsistentHash.HashRingEntry), I64, I64, I64 -> I64
	chr_find_node = |entries, h, i, len| (if (i >= len) { (List.get(entries, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).hr_node } else { (if ((List.get(entries, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).hr_hash >= h) { (List.get(entries, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).hr_node } else { chr_find_node(entries, h, (i + 1), len) }) })

	chr_hash_key : I64 -> I64
	chr_hash_key = |key| ({
		h : I64
		h = Random.mix_bits(key, 1013904223)
		(if (h < 0) { (-h) } else { h })
	})

	chr_hash_text : CceText -> I64
	chr_hash_text = |key| chr_hash_key(chr_text_fold(key, 0, CceText.len(key), 5381))

	chr_text_fold : CceText, I64, I64, I64 -> I64
	chr_text_fold = |key, i, len, acc| (if (i >= len) { acc } else { chr_text_fold(key, (i + 1), len, I64.plus_wrap(I64.times_wrap(acc, 33), CceChar.code(CceText.char_at(key, i)))) })

	chr_hash_pair : I64, I64 -> I64
	chr_hash_pair = |node, vnode| ({
		h : I64
		h = Random.mix_bits(node, (vnode + 1))
		(if (h < 0) { (-h) } else { h })
	})

	chr_node_count : ConsistentHash.ConsistentHashRing -> I64
	chr_node_count = |ring| I64.div_trunc_by(ring.hr_count, ring.hr_vnodes)

	chr_entry_count : ConsistentHash.ConsistentHashRing -> I64
	chr_entry_count = |ring| ring.hr_count

	eq_HashRingEntry : ConsistentHash.HashRingEntry, ConsistentHash.HashRingEntry -> Bool
	eq_HashRingEntry = |ex, ey| ((ex.hr_hash == ey.hr_hash) and (ex.hr_node == ey.hr_node))

	eq_ConsistentHashRing : ConsistentHash.ConsistentHashRing, ConsistentHash.ConsistentHashRing -> Bool
	eq_ConsistentHashRing = |ex, ey| (((ex.hr_entries == ey.hr_entries) and (ex.hr_count == ey.hr_count)) and (ex.hr_vnodes == ey.hr_vnodes))
}
