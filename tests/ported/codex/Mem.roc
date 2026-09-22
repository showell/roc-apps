# Mem -- Codex's address space, written by rocemit. Do not edit.
#
# `peek-byte`, `poke-32` and `alloc-bytes` read and write one heap. Codex
# gives them an empty effect row, so rocemit finds the definitions that
# touch memory by closure over the call graph and threads this value
# through them, the way it threads a GPU device.
#
# **A DOOR THAT READS OR WRITES IS AN EFFECT**, spelled `!` and typed `=>`,
# and so is every definition that reaches one: a platform may keep the bytes
# itself (roc-apps framebuffer/roc/Mem.roc). This one keeps them in the value,
# so its doors are pure underneath. The bump pointer's doors (`alloc`,
# `advance`, `mark`, `release`) are pure everywhere: the value carries it.
#
# **A PERSISTENT TRIE, NOT AN ARRAY OF PAGES.** An array is O(1) per write
# when the reference count cooperates and O(page) when it does not, and
# nothing in the source says which one you got: the difference between
# the two is one extra mention of a name. A trie is O(depth) BY
# CONSTRUCTION -- the spine is rebuilt every time, so there is no fast
# path to fall off. Five levels of 32 over 64-byte leaves is a 2 GB space
# in which a write touches five 32-wide nodes and one 64-byte leaf,
# whatever the compiler decides about sharing.
#
# It also removes the cap. There is no page table to size, so there is no
# address that reads zero and crashes when written, and an untouched
# address costs nothing at all.

Mem :: [].{
	Node := [Empty, Leaf(List(U8)), Branch(List(Mem.Node))]

	Mem : { root : Mem.Node, top : I64 }

	# 6 bits of leaf, 5 levels of 5 bits: 2^31 bytes.
	leaf_bits : U64
	leaf_bits = 6

	leaf_size : U64
	leaf_size = 64

	fan : U64
	fan = 32

	depth : I64
	depth = 5

	new : I64 -> Mem.Mem
	new = |z| { root: Empty, top: 6291456 + z }

	alloc : Mem.Mem, I64 -> (Mem.Mem, I64)
	alloc = |mem, n| ({ root: mem.root, top: mem.top + n }, mem.top)

	# `__heap-advance`: the bump pointer moves past `n` bytes.
	advance : Mem.Mem, I64 -> (Mem.Mem, {})
	advance = |mem, n| ({ root: mem.root, top: mem.top + n }, {})

	# `__heap-save` answers the bump pointer, and `__heap-restore` rewinds to it.
	mark : Mem.Mem -> (Mem.Mem, I64)
	mark = |mem| (mem, mem.top)

	release : Mem.Mem, I64 -> (Mem.Mem, I64)
	release = |mem, h| ({ root: mem.root, top: h }, 0)

	# The index into the node at `level`: level 0 is the leaf's byte.
	part : U64, I64 -> U64
	part = |a, level|
		if level <= 0 {
			U64.bitwise_and(a, 63)
		} else {
			U64.bitwise_and(U64.div_trunc_by(a, Mem.pow32(level - 1) * Mem.leaf_size), 31)
		}

	pow32 : I64 -> U64
	pow32 = |k| if k <= 0 { 1 } else { 32 * Mem.pow32(k - 1) }

	# ---- reading --------------------------------------------------------

	byte_at : Mem.Node, U64, I64 -> U8
	byte_at = |node, a, level| match node {
		Empty => 0
		Leaf(bytes) => List.get(bytes, Mem.part(a, 0)) ?? 0
		Branch(kids) => Mem.byte_at(List.get(kids, Mem.part(a, level)) ?? Empty, a, level - 1)
	}

	load! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	load! = |mem, base, off, width| (mem, U64.to_i64_wrap(Mem.read(mem, base + off, width - 1, 0)))

	read : Mem.Mem, I64, I64, U64 -> U64
	read = |mem, addr, j, acc|
		if j < 0 {
			acc
		} else {
			b = Mem.byte_at(mem.root, I64.to_u64_wrap(addr + j), Mem.depth)
			Mem.read(mem, addr, j - 1, U64.plus_wrap(U64.times_wrap(acc, 256), U8.to_u64(b)))
		}

	# ---- writing --------------------------------------------------------

	store! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	store! = |mem, base, off, v, width| (Mem.write(mem, base + off, I64.to_u64_wrap(v), width), 0)

	# `atomic-exchange`: the qword at the address becomes `v`, and the old one
	# is the answer.
	exchange! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	exchange! = |mem, addr, v| (Mem.write(mem, addr, I64.to_u64_wrap(v), 8), U64.to_i64_wrap(Mem.read(mem, addr, 7, 0)))

	# `__buf-write-byte base off v`: the low byte of `v` at base + off;
	# answers off + 1.
	write_byte! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	write_byte! = |mem, base, off, v| (Mem.write(mem, base + off, I64.to_u64_wrap(v), 1), off + 1)

	# `__buf-write-bytes base off bytes`: the low byte of each element from
	# base + off on; answers off plus the count, the offset past the last.
	write_bytes! : Mem.Mem, I64, I64, List(I64) => (Mem.Mem, I64)
	write_bytes! = |mem, base, off, bytes| (Mem.write_each(mem, base + off, bytes, 0), off + U64.to_i64_wrap(List.len(bytes)))

	write_each : Mem.Mem, I64, List(I64), U64 -> Mem.Mem
	write_each = |mem, at, bytes, i|
		match List.get(bytes, i) {
			Err(_) => mem
			Ok(b) => Mem.write_each(Mem.write(mem, at + U64.to_i64_wrap(i), I64.to_u64_wrap(b), 1), at, bytes, i + 1)
		}

	# `__buf-read-bytes base off count`: the `count` bytes from base + off on,
	# each as an unsigned value; a count of zero or less reads none.
	read_bytes! : Mem.Mem, I64, I64, I64 => (Mem.Mem, List(I64))
	read_bytes! = |mem, base, off, count| (mem, Mem.read_each(mem, base + off, count, List.with_capacity(I64.to_u64_wrap(I64.max(count, 0)))))

	read_each : Mem.Mem, I64, I64, List(I64) -> List(I64)
	read_each = |mem, at, count, acc| {
		i = U64.to_i64_wrap(List.len(acc))
		if i >= count {
			acc
		} else {
			Mem.read_each(mem, at, count, List.append(acc, U64.to_i64_wrap(Mem.read(mem, at + i, 0, 0))))
		}
	}

	write : Mem.Mem, I64, U64, I64 -> Mem.Mem
	write = |mem, addr, u, left|
		if left <= 0 {
			mem
		} else {
			put = Mem.set_at(mem.root, I64.to_u64_wrap(addr), Mem.depth, U64.to_u8_wrap(u))
			Mem.write({ root: put, top: mem.top }, addr + 1, U64.div_trunc_by(u, 256), left - 1)
		}

	# **THE CHILD COMES OUT BEFORE IT IS WRITTEN.** A list handed to a
	# closure, or still named after the set, is shared and gets copied.
	# List.replace takes the child out and leaves a placeholder, so the
	# recursion works on something it owns. tests/copycheck.sh is the
	# instrument that tells the two apart.
	set_at : Mem.Node, U64, I64, U8 -> Mem.Node
	set_at = |node, a, level, v|
		if level <= 0 {
			match node {
				Leaf(bytes) => Leaf(List.set(bytes, Mem.part(a, 0), v) ?? crash("Mem: offset outside a leaf"))
				_ => Leaf(List.set(List.repeat(0.U8, Mem.leaf_size), Mem.part(a, 0), v) ?? crash("Mem: offset outside a leaf"))
			}
		} else {
			i = Mem.part(a, level)
			kids = match node {
				Branch(cs) => cs
				_ => List.repeat(Empty, Mem.fan)
			}
			taken = List.replace(kids, i, Empty) ?? crash("Mem: index outside a node")
			Branch(List.set(taken.list, i, Mem.set_at(taken.prev, a, level - 1, v)) ?? crash("Mem: index outside a node"))
		}
}
