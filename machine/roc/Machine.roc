# The machine: one value holding every device, with a door per device. Each
# door takes the machine and hands it back, so a program threads it the way
# rocemit already threads Mem and a GPU Device.
#
# The devices are the ones codex-vm models for upstream's tests (essay
# notes/codex-devices-in-roc.md): memory, PCI configuration space, the block
# device, Intel gigabit Ethernet, the HPET, the keyboard, a console. No clock
# follows wall time, so a run is reproducible: the page counts steps, and the
# HPET counts the machine's own clock, which device register accesses move
# (`access_cost`).
#
# Codex emitted by rocemit calls the doors named for Codex builtins, which take
# and answer Codex's Integer, and its opening boots the machine from the
# command line, where a test's .vmargs arrive. The block doors end in `!`:
# MachineDisk is either the model (machine/roc) or the host's files
# (machine/native), and a door the host may answer is an effect. They answer
# as x86's block syscalls do, behind the boot process's capability word
# (MachineCaps), which `boot!` writes from the effects the opening declares.
# The page's app (MachineApp.roc) builds a machine with `make` and calls the
# rest.

import MachineCaps
import MachineDisk
import MachineE1000
import MachineHpet
import MachineMedia
import MachineMem
import MachinePci

Machine :: [].{
	Machine : {
		mem : MachineMem.Mem,
		pci : MachinePci.Pci,
		drives : MachineDisk.Drives,
		# Scancodes in the order they arrived, and the next one to read.
		keys : List(U8),
		key_at : U64,
		# What the program printed, as UTF-8.
		console : List(U8),
		steps : U64,
		# Where the last block read landed in memory, and how long it is.
		landed : I64,
		landed_len : I64,
		# The NIC, absent unless a flag puts it on the bus; the HPET; and the
		# machine's clock, in the HPET's counter ticks.
		e1000 : MachineE1000.E1000,
		hpet : MachineHpet.Hpet,
		clock : U64,
		# -board-mmio: RAM behind the three board peripheral windows.
		board_mmio : Bool,
		# The keystrokes a test types (its .keys), in the machine's clock, and
		# how many have been delivered.
		timeline : List({ at : U64, code : U8 }),
		typed : U64,
	}

	Flags : { bridge : Bool, deep : Bool, levels : U64, backward : Bool, disks : List(Str), e1000 : MachineE1000.E1000, hpet : MachineHpet.Hpet, board_mmio : Bool }

	# A batch run's machine, from codex-vm's command line and the effects the
	# program's opening declares. The PCI bridge flags, the NIC's and the
	# HPET's are modelled, and -disk and -disk2 name the files the drives are;
	# any other flag names a device this machine does not have, and a verdict
	# that depends on that device cannot be reproduced, so the run stops there.
	# The opening's grant goes
	# into the boot process's capability word, as x86's boot writes it. The
	# memory's base moves with the argument count, as it does where rocemit
	# threads Mem alone, to keep the program out of compile-time reach.
	boot! : List(Str), List(Str) => Machine.Machine
	boot! = |args, effects| {
		f = Machine.flags(args, 0, { bridge: False, deep: False, levels: 0, backward: False, disks: ["", ""], e1000: MachineE1000.new, hpet: MachineHpet.new, board_mmio: False })
		levels = if !f.bridge { 0 } else if f.levels != 0 { f.levels } else if f.deep { 2 } else { 1 }
		mem = MachineMem.write(MachineMem.new(U64.to_i64_wrap(List.len(args))), MachineCaps.word_addr, MachineCaps.grant(effects), 8)
		nic = if f.e1000.present { Nic(if f.e1000.i219 { 0x15B8 } else { 0x100E }, f.e1000.faults.bme_clear) } else { NoNic }
		made = Machine.make(mem, MachinePci.table(levels, f.backward, nic), MachineDisk.boot!(f.disks))
		{ ..made, e1000: if f.e1000.present { MachineE1000.power_on(f.e1000) } else { f.e1000 }, hpet: f.hpet, board_mmio: f.board_mmio, timeline: Machine.timeline_of(MachineMedia.keys) }
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
				} else if a == "-board-mmio" {
					Machine.flags(args, i + 1, { ..f, board_mmio: True })
				} else if a == "-disk" or a == "-disk2" {
					path = List.get(args, i + 1) ?? crash("machine: ${a} wants a file")
					at = if a == "-disk" { 0 } else { 1 }
					Machine.flags(args, i + 2, { ..f, disks: List.set(f.disks, at, path) ?? crash("machine: no such drive position") })
				} else {
					match MachineE1000.flag(f.e1000, a, List.get(args, i + 1) ?? "") {
						Took(e, n) => Machine.flags(args, i + n, { ..f, e1000: e })
						NotMine =>
							match MachineHpet.flag(f.hpet, a) {
								Took(h) => Machine.flags(args, i + 1, { ..f, hpet: h })
								NotMine => crash("machine: ${a} is not a codex-vm flag this machine models")
							}
					}
				}
		}

	make : MachineMem.Mem, MachinePci.Pci, MachineDisk.Drives -> Machine.Machine
	make = |mem, pci, drives| {
		mem: mem,
		pci: pci,
		drives: drives,
		keys: [],
		key_at: 0,
		console: [],
		steps: 0,
		landed: 0,
		landed_len: 0,
		e1000: MachineE1000.new,
		hpet: MachineHpet.new,
		clock: 0,
		board_mmio: False,
		timeline: [],
		typed: 0,
	}

	tick : Machine.Machine -> Machine.Machine
	tick = |m| { ..m, steps: m.steps + 1 }

	# ---- the doors emitted Codex calls ----------------------------------
	#
	# A Codex builtin with the machine threaded through: the machine first, and
	# answered back beside the builtin's own answer, in Codex's Integer.

	# **THE MACHINE'S CLOCK MOVES WHEN THE PROGRAM TOUCHES A DEVICE REGISTER.**
	# Each read or write in the NIC's or the HPET's window costs 100 µs, in the
	# HPET's counter ticks; memory costs nothing. codex-vm's counter follows the
	# host's clock, and the verdicts judge durations by bands the constant has
	# to land in: e1000-tx-deadline wants two clock readings with nothing
	# between them under 5 ms apart, and a million memory reads under 5 ms
	# too, so a register access costs less than 1.6 ms and memory none; a
	# no-link bring-up waits 8 s by the clock across batches of 4,096 STATUS
	# reads, which 100 µs keeps to tens of thousands of reads.
	access_cost : U64
	access_cost = 1432

	# **THE ADDRESS SPACE IS WHAT CODEX-VM BACKS, AND NOTHING ELSE.** Guest RAM
	# is the low 3 GB, codex-vm's default. Above it are the device windows
	# codex-vm traps, and under -board-mmio the three board peripheral windows it
	# maps as RAM, over any device window they cover. An address none of these
	# claims is one codex-vm faults on, or a device this machine does not model,
	# so a load or store there stops the run and names the address rather than
	# answering from memory.
	region : Machine.Machine, I64 -> [Ram, Nic, Hpet, Nothing(Str)]
	region = |m, a|
		if a >= 0 and a < Machine.ram_size {
			Ram
		} else if m.board_mmio and Machine.board_window(a) {
			Ram
		} else if m.e1000.present and MachineE1000.claims(a) {
			Nic
		} else if MachineHpet.claims(a) {
			Hpet
		} else {
			Nothing(Machine.unbacked(m, a))
		}

	ram_size : I64
	ram_size = 0xC0000000

	# RP2040 SIO, the Cortex-M PPB and SCB, and the BCM2711 peripherals.
	board_window : I64 -> Bool
	board_window = |a|
		(a >= 0xD0000000 and a < 0xD0010000) or (a >= 0xE0000000 and a < 0xE0010000) or (a >= 0xFE000000 and a < 0xFE900000)

	unbacked : Machine.Machine, I64 -> Str
	unbacked = |m, a|
		if a >= 0xFEE00000 and a < 0xFEE01000 {
			"the local APIC's registers, which this machine does not model"
		} else if a >= 0xFEC00000 and a < 0xFEC01000 {
			"the IOAPIC's registers, which this machine does not model"
		} else if a >= 0xFE000000 and a < 0xFE004000 and !m.board_mmio {
			"the HDA controller's registers, which this machine does not model"
		} else if a >= 0xFE800000 and a < 0xFE804000 and !m.board_mmio {
			"the xHCI controller's registers, which this machine does not model"
		} else if MachineE1000.claims(a) {
			"the e1000's window, with no NIC on the bus"
		} else if Machine.board_window(a) {
			"a board peripheral window, which is memory only under -board-mmio"
		} else {
			"which nothing backs"
		}

	hex : U64 -> Str
	hex = |v| Machine.hex_go(v, 8, "")

	hex_go : U64, U64, Str -> Str
	hex_go = |v, left, acc|
		if left == 0 {
			"0x${acc}"
		} else {
			d = Str.from_utf8([U64.to_u8_wrap(if U64.bitwise_and(v, 15) < 10 { 48 + U64.bitwise_and(v, 15) } else { 55 + U64.bitwise_and(v, 15) })]) ?? "?"
			Machine.hex_go(U64.shr_zf_wrap(v, 4), left - 1, Str.concat(d, acc))
		}

	# `peek-byte` .. `peek-qword`, and `read-mmio` and `read-mmio-32`: `width`
	# bytes, little-endian, from whatever backs the address. The NIC's and the
	# HPET's registers answer 32 bits at a time.
	load : Machine.Machine, I64, I64, I64 -> (Machine.Machine, I64)
	load = |m, base, off, width| {
		a = base + off
		match Machine.region(m, a) {
			Ram => (m, U64.to_i64_wrap(MachineMem.read(m.mem, a, width - 1, 0)))
			Nic =>
				if width != 4 {
					crash("machine: a ${I64.to_str(width)}-byte read of the e1000's registers, which this machine answers 32 bits at a time")
				} else {
					(e, mem, v) = MachineE1000.read(m.e1000, m.mem, I64.to_u64_wrap(a - MachineE1000.bar), Machine.nic_dma(m))
					({ ..m, e1000: e, mem: mem, clock: m.clock + Machine.access_cost }, U64.to_i64_wrap(v))
				}
			Hpet =>
				if width != 4 {
					crash("machine: a ${I64.to_str(width)}-byte read of the HPET's registers, which this machine answers 32 bits at a time")
				} else {
					clock = m.clock + Machine.access_cost
					({ ..m, clock: clock }, U64.to_i64_wrap(MachineHpet.read(m.hpet, clock, I64.to_u64_wrap(a - MachineHpet.base))))
				}
			Nothing(what) => crash("machine: a read at ${Machine.hex(I64.to_u64_wrap(a))}, ${what}")
		}
	}

	# `poke-byte` .. `poke-qword`, and `poke-mmio` and `poke-mmio-32`, answer 0.
	store : Machine.Machine, I64, I64, I64, I64 -> (Machine.Machine, I64)
	store = |m, base, off, v, width| {
		a = base + off
		u = I64.to_u64_wrap(v)
		match Machine.region(m, a) {
			Ram => ({ ..m, mem: MachineMem.write(m.mem, a, u, width) }, 0)
			Nic =>
				if width != 4 {
					crash("machine: a ${I64.to_str(width)}-byte write to the e1000's registers, which this machine takes 32 bits at a time")
				} else {
					clock = m.clock + Machine.access_cost
					(e, mem) = MachineE1000.write(m.e1000, m.mem, I64.to_u64_wrap(a - MachineE1000.bar), U64.bitwise_and(u, 0xFFFFFFFF), Machine.nic_dma(m), clock)
					({ ..m, e1000: e, mem: mem, clock: clock }, 0)
				}
			Hpet =>
				if width != 4 {
					crash("machine: a ${I64.to_str(width)}-byte write to the HPET's registers, which this machine takes 32 bits at a time")
				} else {
					clock = m.clock + Machine.access_cost
					({ ..m, clock: clock, hpet: MachineHpet.write(m.hpet, clock, I64.to_u64_wrap(a - MachineHpet.base), U64.bitwise_and(u, 0xFFFFFFFF)) }, 0)
				}
			Nothing(what) => crash("machine: a write at ${Machine.hex(I64.to_u64_wrap(a))}, ${what}")
		}
	}

	# The NIC may touch memory unless -nic-bme-clear has left its bus-master
	# bit clear.
	nic_dma : Machine.Machine -> Bool
	nic_dma = |m| !m.e1000.faults.bme_clear or MachinePci.bus_master(m.pci, 32902, 2)

	alloc : Machine.Machine, I64 -> (Machine.Machine, I64)
	alloc = |m, n| {
		(mem, at) = MachineMem.alloc(m.mem, n)
		({ ..m, mem: mem }, at)
	}

	# `port-out-32` answers 0, as it does on x86. 0xCF8 latches a PCI address
	# and 0xCFC..0xCFF write the register it names.
	port_out_32 : Machine.Machine, I64, I64 -> (Machine.Machine, I64)
	port_out_32 = |m, port, value| {
		p = I64.to_u64_wrap(port)
		v = U64.bitwise_and(I64.to_u64_wrap(value), MachinePci.all_ones)
		if p == MachinePci.config_addr {
			({ ..m, pci: MachinePci.latch(m.pci, v) }, 0)
		} else if p >= MachinePci.config_data and p <= MachinePci.config_data + 3 {
			({ ..m, pci: MachinePci.write(m.pci, v) }, 0)
		} else {
			crash("machine: port-out-32 to port ${U64.to_str(p)}, which no modelled device claims")
		}
	}

	# `port-in-32`: 0xCFC..0xCFF read the register the latched address names.
	port_in_32 : Machine.Machine, I64 -> (Machine.Machine, I64)
	port_in_32 = |m, port| {
		p = I64.to_u64_wrap(port)
		if p >= MachinePci.config_data and p <= MachinePci.config_data + 3 {
			(m, U64.to_i64_wrap(MachinePci.read(m.pci, p - MachinePci.config_data)))
		} else {
			crash("machine: port-in-32 from port ${U64.to_str(p)}, which no modelled device claims")
		}
	}

	# **THE BLOCK DOORS ASK THE CAPABILITY WORD FIRST**, as x86's block
	# syscalls do (X86_64Boot's emit-block-elev-gate): the boot process holds
	# the block-device bit, or the filesystem servicer's cell is set. The word
	# is memory, so a program that clears its own grant is denied from then on.
	block_granted : Machine.Machine -> Bool
	block_granted = |m| {
		word = MachineMem.read(m.mem, MachineCaps.word_addr, 7, 0)
		U64.bitwise_and(word, MachineCaps.bit(MachineCaps.block_device)) != 0 or MachineMem.read(m.mem, MachineCaps.fs_elevated_addr, 7, 0) != 0
	}

	# `block-select` chooses the drive the next block request addresses, and
	# answers 0; denied, it chooses nothing and answers -1.
	block_select! : Machine.Machine, I64 => (Machine.Machine, I64)
	block_select! = |m, n|
		if Machine.block_granted(m) {
			({ ..m, drives: MachineDisk.select(m.drives, I64.to_u64_wrap(n)) }, 0)
		} else {
			(m, -1)
		}

	# `block-sector-count`: the selected drive's size in sectors, 0 with nothing
	# on that position; denied, -1.
	block_sector_count! : Machine.Machine => (Machine.Machine, I64)
	block_sector_count! = |m|
		if Machine.block_granted(m) {
			(m, U64.to_i64_wrap(MachineDisk.sector_count!(m.drives)))
		} else {
			(m, -1)
		}

	# `block-read-sector` as x86 answers it: 512 bytes bump-allocated in memory,
	# the sector copied in, the address handed back. Denied, the buffer is
	# allocated and handed back all the same, with nothing read into it.
	block_read_sector! : Machine.Machine, I64 => (Machine.Machine, I64)
	block_read_sector! = |m, lba|
		if Machine.block_granted(m) {
			Machine.land(m, MachineDisk.read!(m.drives, I64.to_u64_wrap(lba)))
		} else {
			Machine.alloc(m, 512)
		}

	# `block-write-sector`: the 512 bytes at `buf` become the sector. It
	# answers 0 whether or not it was denied, and a denied write writes nothing.
	block_write_sector! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	block_write_sector! = |m, lba, buf|
		if Machine.block_granted(m) {
			({ ..m, drives: MachineDisk.write!(m.drives, I64.to_u64_wrap(lba), Machine.copy_out(m.mem, buf, 0, [])) }, 0)
		} else {
			(m, 0)
		}

	# A sector's bytes into freshly allocated memory: the address, and the
	# machine that remembers where they landed.
	land : Machine.Machine, List(U8) -> (Machine.Machine, I64)
	land = |m, bytes| {
		(mem1, base) = MachineMem.alloc(m.mem, 512)
		mem2 = Machine.copy_in(mem1, base, bytes, 0)
		({ ..m, mem: mem2, landed: base, landed_len: 512 }, base)
	}

	# ---- the process ----------------------------------------------------
	#
	# One process, the boot program, unscoped: nothing that spawns a process or
	# narrows a scope is modelled, so these are the kernel's answers before
	# anything has.

	# `process-get-pid`: the boot program's stack is outside the spawn pool,
	# which x86 answers as slot 0.
	process_get_pid : Machine.Machine -> (Machine.Machine, I64)
	process_get_pid = |m| (m, 0)

	# `process-get-scope`: an unset scope cell reads as the empty text, which
	# admits every path.
	process_get_scope : Machine.Machine, I64 -> (Machine.Machine, Str)
	process_get_scope = |m, _pid| (m, "")

	copy_in : MachineMem.Mem, I64, List(U8), U64 -> MachineMem.Mem
	copy_in = |mem, base, bytes, i|
		match List.get(bytes, i) {
			Ok(b) => Machine.copy_in(MachineMem.write(mem, base + U64.to_i64_wrap(i), U8.to_u64(b), 1), base, bytes, i + 1)
			Err(_) => mem
		}

	copy_out : MachineMem.Mem, I64, I64, List(U8) -> List(U8)
	copy_out = |mem, base, i, acc|
		if i >= 512 {
			acc
		} else {
			Machine.copy_out(mem, base, i + 1, List.append(acc, U64.to_u8_wrap(MachineMem.read(mem, base + i, 0, 0))))
		}

	# ---- memory ---------------------------------------------------------

	peek_byte : Machine.Machine, I64 -> U64
	peek_byte = |m, addr| U64.bitwise_and(MachineMem.read(m.mem, addr, 0, 0), 255)

	# ---- the keyboard ---------------------------------------------------

	# **A KEYSTROKE ARRIVES AT ITS TIME, AND A PROGRAM WAITING FOR ONE WAITS
	# UNTIL THEN.** codex-vm types a test's .keys timeline (`ms:scancode`
	# events, read by -keys-file) by the host's clock, writing each scancode
	# into the key cell at 28680 when its time comes. Here the timeline arrives
	# as MachineMedia.keys and runs on the machine's clock. A program polling an
	# empty cell never touches a device register, so that clock would not move
	# and the key would never come; instead a read that finds the cell empty
	# moves the clock to the next keystroke's time, and the next read finds it.
	# Keystrokes whose time has passed are written in order, so the last one due
	# is the one in the cell, as there.

	# `uefi-read-key-ex` asks UEFI's ConIn through the system table whose
	# address sits at 30704; without one, as on codex-vm's bare-metal boot, it
	# answers -1.
	uefi_read_key_ex : Machine.Machine -> (Machine.Machine, I64)
	uefi_read_key_ex = |m|
		if MachineMem.read(m.mem, 30704, 7, 0) == 0 {
			(m, -1)
		} else {
			crash("machine: uefi-read-key-ex with a UEFI system table, which this machine does not model")
		}

	# `uefi-read-key`: the key cell exchanged with zero, as its scancode byte.
	uefi_read_key : Machine.Machine -> (Machine.Machine, I64)
	uefi_read_key = |m| {
		due = Machine.type_due(m)
		code = U64.bitwise_and(MachineMem.read(due.mem, Machine.key_cell, 7, 0), 255)
		taken = { ..due, mem: MachineMem.write(due.mem, Machine.key_cell, 0, 8) }
		if code == 0 {
			match List.get(taken.timeline, taken.typed) {
				Ok(next) => ({ ..taken, clock: if next.at > taken.clock { next.at } else { taken.clock } }, 0)
				Err(_) => (taken, 0)
			}
		} else {
			(taken, U64.to_i64_wrap(code))
		}
	}

	key_cell : I64
	key_cell = 28680

	type_due : Machine.Machine -> Machine.Machine
	type_due = |m|
		match List.get(m.timeline, m.typed) {
			Ok(k) =>
				if k.at <= m.clock {
					Machine.type_due({ ..m, mem: MachineMem.write(m.mem, Machine.key_cell, U8.to_u64(k.code), 1), typed: m.typed + 1 })
				} else {
					m
				}
			Err(_) => m
		}

	# codex-vm's -keys-file format: `t:scancode` events, t in milliseconds,
	# separated by newlines or semicolons; `#` starts a comment that runs to
	# the end of the line.
	timeline_of : List(U8) -> List({ at : U64, code : U8 })
	timeline_of = |bytes| {
		text = Str.from_utf8(bytes) ?? crash("machine: the .keys timeline is not UTF-8")
		Machine.events_of(Str.split_on(text, "\n"), 0, [])
	}

	events_of : List(Str), U64, List({ at : U64, code : U8 }) -> List({ at : U64, code : U8 })
	events_of = |lines, i, acc|
		match List.get(lines, i) {
			Err(_) => acc
			Ok(line) => Machine.events_of(lines, i + 1, Machine.line_events(Str.split_on(line, ";"), 0, acc))
		}

	line_events : List(Str), U64, List({ at : U64, code : U8 }) -> List({ at : U64, code : U8 })
	line_events = |parts, i, acc|
		match List.get(parts, i) {
			Err(_) => acc
			Ok(part) => {
				event = Str.trim(part)
				if event == "" {
					Machine.line_events(parts, i + 1, acc)
				} else if Str.starts_with(event, "#") {
					acc
				} else {
					match Str.split_first(event, ":") {
						Ok(halves) => {
							ms = U64.from_str(Str.trim(halves.before)) ?? crash("machine: .keys time `${halves.before}`, which this machine reads in whole milliseconds")
							code = U8.from_str(Str.trim(halves.after)) ?? crash("machine: .keys scancode `${halves.after}`")
							Machine.line_events(parts, i + 1, List.append(acc, { at: U64.div_trunc_by(ms * MachineHpet.hz, 1000), code: code }))
						}
						Err(_) => crash("machine: .keys event `${event}` is not time:scancode")
					}
				}
			}
		}

	key_in : Machine.Machine, U8 -> Machine.Machine
	key_in = |m, code| { ..m, keys: List.append(m.keys, code) }

	# The next scancode, or -1 when none is waiting.
	key_next : Machine.Machine -> (Machine.Machine, I64)
	key_next = |m|
		match List.get(m.keys, m.key_at) {
			Ok(k) => ({ ..m, key_at: m.key_at + 1 }, U64.to_i64_wrap(U8.to_u64(k)))
			Err(_) => (m, -1)
		}

	keys_waiting : Machine.Machine -> Bool
	keys_waiting = |m| m.key_at < List.len(m.keys)

	# ---- the console ----------------------------------------------------

	print_line : Machine.Machine, Str -> Machine.Machine
	print_line = |m, s| { ..m, console: List.append(List.concat(m.console, Str.to_utf8(s)), 10) }
}
