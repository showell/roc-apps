# Mem -- the machine's address space. Taken from the module rocemit writes
# for emitted Codex programs (rust-codex-compiler, `MEM` in roc_emit.rs), so
# a program emitted later and the hand-written app here share one model of
# memory.
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

MachineMem :: [].{
	Node := [Empty, Leaf(List(U8)), Branch(List(MachineMem.Node))]

	Mem : { root : MachineMem.Node, top : I64 }

	# 6 bits of leaf, 5 levels of 5 bits: 2^31 bytes.
	leaf_bits : U64
	leaf_bits = 6

	leaf_size : U64
	leaf_size = 64

	fan : U64
	fan = 32

	depth : I64
	depth = 5

	new : I64 -> MachineMem.Mem
	new = |z| { root: Empty, top: 6291456 + z }

	alloc : MachineMem.Mem, I64 -> (MachineMem.Mem, I64)
	alloc = |mem, n| ({ root: mem.root, top: mem.top + n }, mem.top)

	# The index into the node at `level`: level 0 is the leaf's byte.
	part : U64, I64 -> U64
	part = |a, level|
		if level <= 0 {
			U64.bitwise_and(a, 63)
		} else {
			U64.bitwise_and(U64.div_trunc_by(a, MachineMem.pow32(level - 1) * MachineMem.leaf_size), 31)
		}

	pow32 : I64 -> U64
	pow32 = |k| if k <= 0 { 1 } else { 32 * MachineMem.pow32(k - 1) }

	# ---- reading --------------------------------------------------------

	byte_at : MachineMem.Node, U64, I64 -> U8
	byte_at = |node, a, level| match node {
		Empty => 0
		Leaf(bytes) => List.get(bytes, MachineMem.part(a, 0)) ?? 0
		Branch(kids) => MachineMem.byte_at(List.get(kids, MachineMem.part(a, level)) ?? Empty, a, level - 1)
	}

	load : MachineMem.Mem, I64, I64, I64 -> (MachineMem.Mem, I64)
	load = |mem, base, off, width| (mem, U64.to_i64_wrap(MachineMem.read(mem, base + off, width - 1, 0)))

	read : MachineMem.Mem, I64, I64, U64 -> U64
	read = |mem, addr, j, acc|
		if j < 0 {
			acc
		} else {
			b = MachineMem.byte_at(mem.root, I64.to_u64_wrap(addr + j), MachineMem.depth)
			MachineMem.read(mem, addr, j - 1, U64.plus_wrap(U64.times_wrap(acc, 256), U8.to_u64(b)))
		}

	# ---- writing --------------------------------------------------------

	store : MachineMem.Mem, I64, I64, I64, I64 -> (MachineMem.Mem, I64)
	store = |mem, base, off, v, width| (MachineMem.write(mem, base + off, I64.to_u64_wrap(v), width), 0)

	write : MachineMem.Mem, I64, U64, I64 -> MachineMem.Mem
	write = |mem, addr, u, left|
		if left <= 0 {
			mem
		} else {
			put = MachineMem.set_at(mem.root, I64.to_u64_wrap(addr), MachineMem.depth, U64.to_u8_wrap(u))
			MachineMem.write({ root: put, top: mem.top }, addr + 1, U64.div_trunc_by(u, 256), left - 1)
		}

	# **THE CHILD COMES OUT BEFORE IT IS WRITTEN.** A list handed to a
	# closure, or still named after the set, is shared and gets copied.
	# List.replace takes the child out and leaves a placeholder, so the
	# recursion works on something it owns. tests/copycheck.sh is the
	# instrument that tells the two apart.
	set_at : MachineMem.Node, U64, I64, U8 -> MachineMem.Node
	set_at = |node, a, level, v|
		if level <= 0 {
			match node {
				Leaf(bytes) => Leaf(List.set(bytes, MachineMem.part(a, 0), v) ?? crash("Mem: offset outside a leaf"))
				_ => Leaf(List.set(List.repeat(0.U8, MachineMem.leaf_size), MachineMem.part(a, 0), v) ?? crash("Mem: offset outside a leaf"))
			}
		} else {
			i = MachineMem.part(a, level)
			kids = match node {
				Branch(cs) => cs
				_ => List.repeat(Empty, MachineMem.fan)
			}
			taken = List.replace(kids, i, Empty) ?? crash("Mem: index outside a node")
			Branch(List.set(taken.list, i, MachineMem.set_at(taken.prev, a, level - 1, v)) ?? crash("Mem: index outside a node"))
		}
}
