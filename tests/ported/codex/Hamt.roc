# Hamt -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import ListUtils
import Maybe
import Text

Hamt :: [].{
	HamtEntry(a) : { key : Text, value : a }
	HamtNode(a) := [HamtEmpty, HamtLeaf(I64, Text, a), HamtCollision(I64, List(Hamt.HamtEntry(a))), HamtBranch(I64, List(Hamt.HamtNode(a)))].{
		is_eq : Hamt.HamtNode(a), Hamt.HamtNode(a) -> Bool where [a.is_eq : a, a -> Bool]
		is_eq = |a, b| eq_HamtNode(a, b)
	}
	HamtMap(a) : { root : Hamt.HamtNode(a), size : I64 }
	HamtSetResult(a) : { node : Hamt.HamtNode(a), delta : I64 }
	CollisionSetResult(a) : { entries : List(Hamt.HamtEntry(a)), delta : I64 }

	hamt_empty : Hamt.HamtMap(a)
	hamt_empty = { root: HamtEmpty, size: 0 }

	hamt_djb2_hash : Text -> I64
	hamt_djb2_hash = |s| hamt_djb2_loop(s, 0, Text.len(s), 5381)

	hamt_djb2_loop : Text, I64, I64, I64 -> I64
	hamt_djb2_loop = |s, i, len, h| (if (i == len) { abs_int(h) } else { hamt_djb2_loop(s, (i + 1), len, I64.plus_wrap(I64.times_wrap(h, 33), Text.char_at(s, i))) })

	abs_int : I64 -> I64
	abs_int = |n| (if (n < 0) { (-n) } else { n })

	pow2 : I64 -> I64
	pow2 = |n| I64.shl_wrap(1, I64.to_u8_wrap(n))

	extract_chunk : I64, I64 -> I64
	extract_chunk = |hash, level| I64.bitwise_and(I64.shr_zf_wrap(hash, I64.to_u8_wrap((level * 5))), 31)

	popcount : I64 -> I64
	popcount = |n| popcount_loop(I64.bitwise_and(n, 4294967295), 0)

	popcount_loop : I64, I64 -> I64
	popcount_loop = |n, count| (if (n == 0) { count } else { popcount_loop(I64.shr_zf_wrap(n, I64.to_u8_wrap(1)), (count + I64.bitwise_and(n, 1))) })

	bitmap_has : I64, I64 -> Bool
	bitmap_has = |bitmap, bit| (I64.bitwise_and(I64.shr_zf_wrap(bitmap, I64.to_u8_wrap(bit)), 1) == 1)

	bitmap_set : I64, I64 -> I64
	bitmap_set = |bitmap, bit| I64.bitwise_or(bitmap, pow2(bit))

	bitmap_index : I64, I64 -> I64
	bitmap_index = |bitmap, bit| popcount(I64.bitwise_and(bitmap, (pow2(bit) - 1)))

	# hamt_insert_at builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	hamt_insert_at : List(a), I64, a -> List(a)
	hamt_insert_at = |xs, i, x| hamt_insert_at_acc(xs, i, x, [])

	hamt_insert_at_acc : List(a), I64, a, List(a) -> List(a)
	hamt_insert_at_acc = |xs, i, x, acc| (if (i == 0) { List.concat(acc, List.concat([x], xs)) } else { hamt_insert_at_acc(ListUtils.list_tail(xs), (i - 1), x, List.append(acc, (List.get(xs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))) })

	# list_replace_at builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	list_replace_at : List(a), I64, a -> List(a)
	list_replace_at = |xs, i, x| list_replace_at_acc(xs, i, x, [])

	list_replace_at_acc : List(a), I64, a, List(a) -> List(a)
	list_replace_at_acc = |xs, i, x, acc| (if (i == 0) { List.concat(acc, List.concat([x], ListUtils.list_tail(xs))) } else { list_replace_at_acc(ListUtils.list_tail(xs), (i - 1), x, List.append(acc, (List.get(xs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))) })

	# list_remove_at builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	list_remove_at : List(a), I64 -> List(a)
	list_remove_at = |xs, i| list_remove_at_acc(xs, i, [])

	list_remove_at_acc : List(a), I64, List(a) -> List(a)
	list_remove_at_acc = |xs, i, acc| (if (i == 0) { List.concat(acc, ListUtils.list_tail(xs)) } else { list_remove_at_acc(ListUtils.list_tail(xs), (i - 1), List.append(acc, (List.get(xs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))) })

	hamt_get : Hamt.HamtMap(a), Text -> Maybe.Maybe(a)
	hamt_get = |m, key| ({
		hash = hamt_djb2_hash(key)
		hamt_node_get(m.root, hash, key, 0)
	})

	hamt_node_get : Hamt.HamtNode(a), I64, Text, I64 -> Maybe.Maybe(a)
	hamt_node_get = |node, hash, key, level| (match node {
		HamtEmpty => None
		HamtLeaf(_h, k, v) => (if (k == key) { Just(v) } else { None })
		HamtCollision(h, entries) => (if (h == hash) { collision_find(entries, key) } else { None })
		HamtBranch(bitmap, children) => ({
			chunk = extract_chunk(hash, level)
			(if bitmap_has(bitmap, chunk) { ({
				idx = bitmap_index(bitmap, chunk)
				hamt_node_get((List.get(children, I64.to_u64_wrap(idx)) ?? crash("list-at out of range")), hash, key, (level + 1))
			}) } else { None })
		})
	})

	collision_find : List(Hamt.HamtEntry(a)), Text -> Maybe.Maybe(a)
	collision_find = |entries, key| (if (U64.to_i64_wrap(List.len(entries)) == 0) { None } else { ({
		e = (List.get(entries, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
		(if (e.key == key) { Just(e.value) } else { collision_find(ListUtils.list_tail(entries), key) })
	}) })

	hamt_set : Hamt.HamtMap(a), Text, a -> Hamt.HamtMap(a)
	hamt_set = |m, key, value| ({
		hash = hamt_djb2_hash(key)
		result = hamt_node_set(m.root, hash, key, value, 0)
		{ root: result.node, size: (m.size + result.delta) }
	})

	hamt_node_set : Hamt.HamtNode(a), I64, Text, a, I64 -> Hamt.HamtSetResult(a)
	hamt_node_set = |node, hash, key, value, level| (match node {
		HamtEmpty => { node: HamtLeaf(hash, key, value), delta: 1 }
		HamtLeaf(h, k, v) => (if (k == key) { { node: HamtLeaf(h, key, value), delta: 0 } } else { (if (h == hash) { { node: HamtCollision(h, [{ key: k, value: v }, { key: key, value: value }]), delta: 1 } } else { ({
			new_node = make_branch(h, k, v, hash, key, value, level)
			{ node: new_node, delta: 1 }
		}) }) })
		HamtCollision(h, entries) => (if (h == hash) { ({
			updated = collision_set(entries, key, value)
			{ node: HamtCollision(h, updated.entries), delta: updated.delta }
		}) } else { ({
			col_node = HamtCollision(h, entries)
			hamt_node_set(make_single_branch(col_node, h, level), hash, key, value, level)
		}) })
		HamtBranch(bitmap, children) => ({
			chunk = extract_chunk(hash, level)
			(if bitmap_has(bitmap, chunk) { ({
				idx = bitmap_index(bitmap, chunk)
				child = (List.get(children, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))
				result = hamt_node_set(child, hash, key, value, (level + 1))
				{ node: HamtBranch(bitmap, list_replace_at(children, idx, result.node)), delta: result.delta }
			}) } else { ({
				idx = bitmap_index(bitmap, chunk)
				new_leaf = HamtLeaf(hash, key, value)
				{ node: HamtBranch(bitmap_set(bitmap, chunk), hamt_insert_at(children, idx, new_leaf)), delta: 1 }
			}) })
		})
	})

	make_single_branch : Hamt.HamtNode(a), I64, I64 -> Hamt.HamtNode(a)
	make_single_branch = |node, hash, level| ({
		chunk = extract_chunk(hash, level)
		HamtBranch(pow2(chunk), [node])
	})

	make_branch : I64, Text, a, I64, Text, a, I64 -> Hamt.HamtNode(a)
	make_branch = |h1, k1, v1, h2, k2, v2, level| (if (level > 6) { HamtCollision(h1, [{ key: k1, value: v1 }, { key: k2, value: v2 }]) } else { ({
		c1 = extract_chunk(h1, level)
		c2 = extract_chunk(h2, level)
		(if (c1 == c2) { ({
			child = make_branch(h1, k1, v1, h2, k2, v2, (level + 1))
			HamtBranch(pow2(c1), [child])
		}) } else { (if (c1 < c2) { HamtBranch(bitmap_set(pow2(c1), c2), [HamtLeaf(h1, k1, v1), HamtLeaf(h2, k2, v2)]) } else { HamtBranch(bitmap_set(pow2(c2), c1), [HamtLeaf(h2, k2, v2), HamtLeaf(h1, k1, v1)]) }) })
	}) })

	collision_set : List(Hamt.HamtEntry(a)), Text, a -> Hamt.CollisionSetResult(a)
	collision_set = |entries, key, value| collision_set_loop(entries, key, value, 0)

	collision_set_loop : List(Hamt.HamtEntry(a)), Text, a, I64 -> Hamt.CollisionSetResult(a)
	collision_set_loop = |entries, key, value, i| (if (i == U64.to_i64_wrap(List.len(entries))) { { entries: List.concat(entries, [{ key: key, value: value }]), delta: 1 } } else { ({
		e = (List.get(entries, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (e.key == key) { { entries: list_replace_at(entries, i, { key: key, value: value }), delta: 0 } } else { collision_set_loop(entries, key, value, (i + 1)) })
	}) })

	hamt_remove : Hamt.HamtMap(a), Text -> Hamt.HamtMap(a)
	hamt_remove = |m, key| ({
		hash = hamt_djb2_hash(key)
		result = hamt_node_remove(m.root, hash, key, 0)
		(match result {
			Just(new_root) => { root: new_root, size: (m.size - 1) }
			None => m
		})
	})

	hamt_node_remove : Hamt.HamtNode(a), I64, Text, I64 -> Maybe.Maybe(Hamt.HamtNode(a))
	hamt_node_remove = |node, hash, key, level| (match node {
		HamtEmpty => None
		HamtLeaf(_h, k, _v) => (if (k == key) { Just(HamtEmpty) } else { None })
		HamtCollision(h, entries) => (if (h == hash) { ({
			filtered = collision_remove(entries, key)
			(if (U64.to_i64_wrap(List.len(filtered)) == U64.to_i64_wrap(List.len(entries))) { None } else { (if (U64.to_i64_wrap(List.len(filtered)) == 1) { ({
				e = (List.get(filtered, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
				Just(HamtLeaf(h, e.key, e.value))
			}) } else { Just(HamtCollision(h, filtered)) }) })
		}) } else { None })
		HamtBranch(bitmap, children) => ({
			chunk = extract_chunk(hash, level)
			(if bitmap_has(bitmap, chunk) { ({
				idx = bitmap_index(bitmap, chunk)
				child = (List.get(children, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))
				result = hamt_node_remove(child, hash, key, (level + 1))
				(match result {
					None => None
					Just(new_child) => (match new_child {
						HamtEmpty => (if (U64.to_i64_wrap(List.len(children)) == 1) { Just(HamtEmpty) } else { ({
							new_bitmap = (bitmap - pow2(chunk))
							Just(HamtBranch(new_bitmap, list_remove_at(children, idx)))
						}) })
						_ => Just(HamtBranch(bitmap, list_replace_at(children, idx, new_child)))
					})
				})
			}) } else { None })
		})
	})

	# collision_remove builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	collision_remove : List(Hamt.HamtEntry(a)), Text -> List(Hamt.HamtEntry(a))
	collision_remove = |entries, key| collision_remove_acc(entries, key, [])

	collision_remove_acc : List(Hamt.HamtEntry(a)), Text, List(Hamt.HamtEntry(a)) -> List(Hamt.HamtEntry(a))
	collision_remove_acc = |entries, key, acc| (if (U64.to_i64_wrap(List.len(entries)) == 0) { acc } else { ({
		e = (List.get(entries, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
		(if (e.key == key) { List.concat(acc, ListUtils.list_tail(entries)) } else { collision_remove_acc(ListUtils.list_tail(entries), key, List.append(acc, e)) })
	}) })

	hamt_contains : Hamt.HamtMap(a), Text -> Bool
	hamt_contains = |m, key| (match hamt_get(m, key) {
		Just(_val) => True
		None => False
	})

	hamt_size : Hamt.HamtMap(a) -> I64
	hamt_size = |m| m.size

	hamt_fold : (a, Text, b -> a), a, Hamt.HamtMap(b) -> a
	hamt_fold = |f, init, m| hamt_node_fold(f, init, m.root)

	hamt_node_fold : (a, Text, b -> a), a, Hamt.HamtNode(b) -> a
	hamt_node_fold = |f, acc, node| (match node {
		HamtEmpty => acc
		HamtLeaf(_h, k, v) => f(acc, k, v)
		HamtCollision(_h, entries) => fold_entries(f, acc, entries, 0)
		HamtBranch(_bitmap, children) => fold_children(f, acc, children, 0)
	})

	fold_entries : (a, Text, b -> a), a, List(Hamt.HamtEntry(b)), I64 -> a
	fold_entries = |f, acc, entries, i| (if (i == U64.to_i64_wrap(List.len(entries))) { acc } else { ({
		e = (List.get(entries, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		fold_entries(f, f(acc, e.key, e.value), entries, (i + 1))
	}) })

	fold_children : (a, Text, b -> a), a, List(Hamt.HamtNode(b)), I64 -> a
	fold_children = |f, acc, children, i| (if (i == U64.to_i64_wrap(List.len(children))) { acc } else { fold_children(f, hamt_node_fold(f, acc, (List.get(children, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), children, (i + 1)) })

	hamt_to_list : Hamt.HamtMap(a) -> List(Hamt.HamtEntry(a))
	hamt_to_list = |m| hamt_fold(lam_0, [], m)

	hamt_from_list : List(Hamt.HamtEntry(a)) -> Hamt.HamtMap(a)
	hamt_from_list = |entries| hamt_from_list_loop(entries, 0, hamt_empty)

	hamt_from_list_loop : List(Hamt.HamtEntry(a)), I64, Hamt.HamtMap(a) -> Hamt.HamtMap(a)
	hamt_from_list_loop = |entries, i, m| (if (i == U64.to_i64_wrap(List.len(entries))) { m } else { ({
		e = (List.get(entries, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		hamt_from_list_loop(entries, (i + 1), hamt_set(m, e.key, e.value))
	}) })

	eq_HamtNode : Hamt.HamtNode(a), Hamt.HamtNode(a) -> Bool where [a.is_eq : a, a -> Bool]
	eq_HamtNode = |ex, ey| (match ex {
		HamtEmpty => (match ey {
			HamtEmpty => True
			_ => False
		})
		HamtLeaf(exf0, exf1, exf2) => (match ey {
			HamtLeaf(eyf0, eyf1, eyf2) => (((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2))
			_ => False
		})
		HamtCollision(exf0, exf1) => (match ey {
			HamtCollision(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
		HamtBranch(exf0, exf1) => (match ey {
			HamtBranch(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
	})

	lam_0 : List(Hamt.HamtEntry(a)), Text, a -> List(Hamt.HamtEntry(a))
	lam_0 = |acc, k, v| List.concat(acc, [{ key: k, value: v }])
}
