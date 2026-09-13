# The machine: one value holding every device, with a door per device. Each
# door takes the machine and hands it back, so a program threads it the way
# rocemit already threads Mem and a GPU Device.
#
# The devices are the ones codex-vm models for upstream's tests (essay
# notes/codex-devices-in-roc.md): memory, PCI configuration space, the block
# device, the keyboard, a console. The clock counts steps, not wall time, so a
# run is reproducible.
#
# Two programs drive it. Codex emitted by rocemit calls the doors named for
# Codex builtins, which take and answer Codex's Integer, and its opening boots
# the machine from the command line, where a test's .vmargs arrive. The page's
# app (MachineApp.roc) builds one with a disk image and calls the same doors
# and the ones below them.

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

	Flags : { bridge : Bool, deep : Bool, levels : U64, backward : Bool }

	# The page's machine: codex-vm's default devices, and one drive.
	new : List(U8) -> Machine.M
	new = |image| Machine.make(Mem.new(U64.to_i64_wrap(List.len(image))), Pci.table(0, False), image)

	# A batch run's machine, from codex-vm's command line. The PCI bridge flags
	# are modelled; any other flag names a device this machine does not have,
	# and a verdict that depends on that device cannot be reproduced, so the
	# run stops there. The memory's base moves with the argument count, as
	# rocemit's Mem.new does, to keep the program out of compile-time reach.
	boot : List(Str) -> Machine.M
	boot = |args| {
		f = Machine.flags(args, 0, { bridge: False, deep: False, levels: 0, backward: False })
		levels = if !f.bridge { 0 } else if f.levels != 0 { f.levels } else if f.deep { 2 } else { 1 }
		Machine.make(Mem.new(U64.to_i64_wrap(List.len(args))), Pci.table(levels, f.backward), [])
	}

	# -pci-bridge is one level, -pci-bridge-deep two, -pci-bridge-levels N
	# is N, and -pci-bridge-backward points the deepest bridge at bus 0.
	flags : List(Str), U64, Machine.Flags -> Machine.Flags
	flags = |args, i, f|
		match List.get(args, i) {
			Err(_) => f
			Ok(a) =>
				if a == "-pci-bridge" {
					Machine.flags(args, i + 1, { ..f, bridge: True })
				} else if a == "-pci-bridge-deep" {
					Machine.flags(args, i + 1, { ..f, bridge: True, deep: True })
				} else if a == "-pci-bridge-backward" {
					Machine.flags(args, i + 1, { ..f, bridge: True, backward: True })
				} else if a == "-pci-bridge-levels" {
					n = U64.from_str(List.get(args, i + 1) ?? "") ?? crash("machine: -pci-bridge-levels wants a number")
					Machine.flags(args, i + 2, { ..f, bridge: True, levels: n })
				} else {
					crash("machine: ${a} is not a codex-vm flag this machine models")
				}
		}

	make : Mem.Mem, Pci.Pci, List(U8) -> Machine.M
	make = |mem, pci, image| {
		mem: mem,
		pci: pci,
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

	# ---- the doors emitted Codex calls ----------------------------------
	#
	# A Codex builtin with the machine threaded through: the machine first, and
	# answered back beside the builtin's own answer, in Codex's Integer.

	# `peek-byte` .. `peek-qword`: `width` bytes, little-endian.
	load : Machine.M, I64, I64, I64 -> (Machine.M, I64)
	load = |m, base, off, width| (m, U64.to_i64_wrap(Mem.read(m.mem, base + off, width - 1, 0)))

	# `poke-byte` .. `poke-qword` answer 0.
	store : Machine.M, I64, I64, I64, I64 -> (Machine.M, I64)
	store = |m, base, off, v, width| ({ ..m, mem: Mem.write(m.mem, base + off, I64.to_u64_wrap(v), width) }, 0)

	alloc : Machine.M, I64 -> (Machine.M, I64)
	alloc = |m, n| {
		(mem, at) = Mem.alloc(m.mem, n)
		({ ..m, mem: mem }, at)
	}

	# `port-out-32` answers 0, as it does on x86. 0xCF8 latches a PCI address
	# and 0xCFC..0xCFF write the register it names.
	port_out_32 : Machine.M, I64, I64 -> (Machine.M, I64)
	port_out_32 = |m, port, value| {
		p = I64.to_u64_wrap(port)
		v = U64.bitwise_and(I64.to_u64_wrap(value), Pci.all_ones)
		if p == Pci.config_addr {
			({ ..m, pci: Pci.latch(m.pci, v) }, 0)
		} else if p >= Pci.config_data and p <= Pci.config_data + 3 {
			({ ..m, pci: Pci.write(m.pci, v) }, 0)
		} else {
			crash("machine: port-out-32 to port ${U64.to_str(p)}, which no modelled device claims")
		}
	}

	# `port-in-32`: 0xCFC..0xCFF read the register the latched address names.
	port_in_32 : Machine.M, I64 -> (Machine.M, I64)
	port_in_32 = |m, port| {
		p = I64.to_u64_wrap(port)
		if p >= Pci.config_data and p <= Pci.config_data + 3 {
			(m, U64.to_i64_wrap(Pci.read(m.pci, p - Pci.config_data)))
		} else {
			crash("machine: port-in-32 from port ${U64.to_str(p)}, which no modelled device claims")
		}
	}

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
