# The machine: one value holding every device, with a door per device. Each
# door takes the machine and hands it back, so a program threads it the way
# rocemit already threads Mem and a GPU Device.
#
# The devices are the ones codex-vm models for upstream's tests (essay
# notes/codex-devices-in-roc.md): memory, PCI configuration space, the block
# device, the keyboard, a console. The clock counts steps, not wall time, so a
# run is reproducible.

import Disk
import Mem
import Pci

Machine :: [].{
	M : {
		mem : Mem.Mem,
		pci : Pci.Pci,
		drives : Disk.Drives,
		# Scancodes in the order they arrived, and the next one to read.
		keys : List(U8),
		key_at : U64,
		# What the program printed, as UTF-8.
		console : List(U8),
		steps : U64,
		# Where the last block read landed in memory, and how long it is.
		landed : I64,
		landed_len : I64,
	}

	new : List(U8) -> Machine.M
	new = |image| {
		mem: Mem.new(U64.to_i64_wrap(List.len(image))),
		pci: Pci.default,
		drives: Disk.with_image(image),
		keys: [],
		key_at: 0,
		console: [],
		steps: 0,
		landed: 0,
		landed_len: 0,
	}

	tick : Machine.M -> Machine.M
	tick = |m| { ..m, steps: m.steps + 1 }

	# ---- ports ----------------------------------------------------------

	port_out_32 : Machine.M, U64, U64 -> Machine.M
	port_out_32 = |m, port, value| { ..m, pci: Pci.write_port(m.pci, port, value) }

	port_in_32 : Machine.M, U64 -> (Machine.M, U64)
	port_in_32 = |m, port| (m, Pci.read_port(m.pci, port))

	# ---- the block device -----------------------------------------------

	# `block-read-sector` as bare metal answers it: 512 bytes allocated in
	# memory, the sector copied in, the address handed back.
	block_read_sector : Machine.M, U64 -> (Machine.M, I64)
	block_read_sector = |m, lba| {
		bytes = Disk.sector(m.drives, lba)
		(mem1, base) = Mem.alloc(m.mem, 512)
		mem2 = Machine.copy_in(mem1, base, bytes, 0)
		({ ..m, mem: mem2, landed: base, landed_len: 512 }, base)
	}

	copy_in : Mem.Mem, I64, List(U8), U64 -> Mem.Mem
	copy_in = |mem, base, bytes, i|
		match List.get(bytes, i) {
			Ok(b) => Machine.copy_in(Mem.write(mem, base + U64.to_i64_wrap(i), U8.to_u64(b), 1), base, bytes, i + 1)
			Err(_) => mem
		}

	block_sector_count : Machine.M -> U64
	block_sector_count = |m| Disk.sector_count(m.drives)

	# ---- memory ---------------------------------------------------------

	peek_byte : Machine.M, I64 -> U64
	peek_byte = |m, addr| U64.bitwise_and(Mem.read(m.mem, addr, 0, 0), 255)

	# ---- the keyboard ---------------------------------------------------

	key_in : Machine.M, U8 -> Machine.M
	key_in = |m, code| { ..m, keys: List.append(m.keys, code) }

	# The next scancode, or -1 when none is waiting.
	key_next : Machine.M -> (Machine.M, I64)
	key_next = |m|
		match List.get(m.keys, m.key_at) {
			Ok(k) => ({ ..m, key_at: m.key_at + 1 }, U64.to_i64_wrap(U8.to_u64(k)))
			Err(_) => (m, -1)
		}

	keys_waiting : Machine.M -> Bool
	keys_waiting = |m| m.key_at < List.len(m.keys)

	# ---- the console ----------------------------------------------------

	print_line : Machine.M, Str -> Machine.M
	print_line = |m, s| { ..m, console: List.append(List.concat(m.console, Str.to_utf8(s)), 10) }
}
