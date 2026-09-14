# Tests for MachineMem: `roc test machine/roc/MachineMemTests.roc`. Multi-byte
# reads and writes take one walk down the trie when the bytes share a 64-byte
# leaf and a walk a byte when they cross its edge, and the two paths must agree
# with each other and with codex-vm's little-endian memory.

import MachineMem

MachineMemTests :: [].{
	# A byte at a time, the slow path, for comparison.
	put_each : MachineMem.Mem, I64, List(U8), U64 -> MachineMem.Mem
	put_each = |mem, addr, bytes, i|
		match List.get(bytes, i) {
			Err(_) => mem
			Ok(b) => MachineMemTests.put_each(MachineMem.write(mem, addr + U64.to_i64_wrap(i), U8.to_u64(b), 1), addr, bytes, i + 1)
		}

	byte : MachineMem.Mem, I64 -> U64
	byte = |mem, addr| MachineMem.read(mem, addr, 0, 0)
}

# Untouched memory reads zero, at any width and across a leaf's edge.
expect MachineMem.read(MachineMem.new(0), 0x1000, 7, 0) == 0
expect MachineMem.read(MachineMem.new(0), 0xBF00003E, 3, 0) == 0

# Four bytes inside one leaf go in and come back little-endian.
expect {
	m = MachineMem.write(MachineMem.new(0), 0x7C4, 0x12345678, 4)
	MachineMem.read(m, 0x7C4, 3, 0) == 0x12345678 and MachineMemTests.byte(m, 0x7C4) == 0x78 and MachineMemTests.byte(m, 0x7C7) == 0x12
}

# A value that crosses a leaf's edge (62 and 63 in one leaf, 64 and 65 in the
# next) reads back whole, and byte by byte.
expect {
	m = MachineMem.write(MachineMem.new(0), 62, 0xAABBCCDD, 4)
	MachineMem.read(m, 62, 3, 0) == 0xAABBCCDD and MachineMemTests.byte(m, 63) == 0xCC and MachineMemTests.byte(m, 64) == 0xBB
}

# The fast write and the byte-at-a-time write leave the same memory.
expect {
	fast = MachineMem.write(MachineMem.new(0), 0xBF000100, 0x0102030405060708, 8)
	slow = MachineMemTests.put_each(MachineMem.new(0), 0xBF000100, [8, 7, 6, 5, 4, 3, 2, 1], 0)
	MachineMem.read(fast, 0xBF000100, 7, 0) == MachineMem.read(slow, 0xBF000100, 7, 0) and MachineMem.read(fast, 0xBF000100, 7, 0) == 0x0102030405060708
}

# A narrower write changes only its own bytes.
expect {
	m = MachineMem.write(MachineMem.write(MachineMem.new(0), 0x2000, 0xFFFFFFFF, 4), 0x2001, 0, 1)
	MachineMem.read(m, 0x2000, 3, 0) == 0xFFFF00FF
}

# Writes in different leaves and different subtrees do not disturb each other.
expect {
	m = MachineMem.write(MachineMem.write(MachineMem.new(0), 0x100, 0x11, 1), 0xBF000000, 0x22, 1)
	MachineMemTests.byte(m, 0x100) == 0x11 and MachineMemTests.byte(m, 0xBF000000) == 0x22 and MachineMemTests.byte(m, 0x101) == 0
}
