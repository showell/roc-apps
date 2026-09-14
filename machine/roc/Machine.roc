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

import MachineApic
import MachineCaps
import MachineDisk
import MachineE1000
import MachineHpet
import MachineIde
import MachineMedia
import MachineMem
import MachineNat
import MachineNe2k
import MachinePci
import MachinePorts

Machine :: [].{
	Machine : {
		mem : MachineMem.Mem,
		pci : MachinePci.Pci,
		drives : MachineDisk.Drives,
		# The IDE channel's registers over those drives.
		ide : MachineIde.Ide,
		# The NE2000, the frames the NAT has queued for its ring, and the
		# lease the NAT's DHCP offers, in seconds.
		ne2k : MachineNe2k.Card,
		rx : List(List(U8)),
		lease : U64,
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
		# The filesystem and network scopes processes were given, by pid; x86
		# keeps a text pointer in each entry, and this machine keeps the text.
		scopes : Dict(U64, Str),
		net_scopes : Dict(U64, Str),
		# The I/O ports below PCI's.
		ports : MachinePorts.Ports,
		# The local APIC and the IOAPIC.
		apic : MachineApic.Apic,
	}

	Flags : { bridge : Bool, deep : Bool, levels : U64, backward : Bool, disks : List(Str), board_mmio : Bool, lease : U64 }

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
		(f, fe1000, fhpet) = Machine.flags(args, 0, { bridge: False, deep: False, levels: 0, backward: False, disks: ["", ""], board_mmio: False, lease: 3600 }, MachineE1000.new, MachineHpet.new)
		levels = if !f.bridge { 0 } else if f.levels != 0 { f.levels } else if f.deep { 2 } else { 1 }
		# The process table as the boot leaves it: the boot program's entry
		# marked running (2) with the opening's grant, and process 1 granted the
		# console bit (X86_64Chapter's emit-start).
		table = MachineMem.write(MachineMem.new(U64.to_i64_wrap(List.len(args))), Machine.proc_table, 2, 8)
		granted = MachineMem.write(table, MachineCaps.word_addr, MachineCaps.grant(effects), 8)
		mem = MachineMem.write(granted, Machine.cap_addr(1), 1, 8)
		nic = if fe1000.present { Nic(if fe1000.i219 { 0x15B8 } else { 0x100E }, fe1000.faults.bme_clear) } else { NoNic }
		# The boot probes the NE2000 and copies its station address out
		# (X86_64Boot's emit-nic-init); every run starts with that done.
		(card, address) = MachineNe2k.booted
		nic_mem = Machine.copy_in(MachineMem.write(mem, Machine.nic_present_addr, 1, 8), Machine.nic_mac_addr, address, 0)
		made = Machine.make(nic_mem, MachinePci.table(levels, f.backward, nic), MachineDisk.boot!(f.disks))
		{ ..made, ide: MachineIde.attach!(made.drives), ne2k: card, lease: f.lease, e1000: if fe1000.present { MachineE1000.power_on(fe1000) } else { fe1000 }, hpet: fhpet, board_mmio: f.board_mmio, timeline: Machine.timeline_of(MachineMedia.keys) }
	}

	# -pci-bridge is one level, -pci-bridge-deep two, -pci-bridge-levels N
	# is N, and -pci-bridge-backward points the deepest bridge at bus 0.
	#
	# The e1000 and the HPET travel beside the flags, not inside them: on Roc's
	# dev backend for wasm, this function copying a record that holds them in
	# every branch fails to link ("relocations not in offset order").
	flags : List(Str), U64, Machine.Flags, MachineE1000.E1000, MachineHpet.Hpet -> (Machine.Flags, MachineE1000.E1000, MachineHpet.Hpet)
	flags = |args, i, f, e1000, hpet|
		match List.get(args, i) {
			Err(_) => (f, e1000, hpet)
			Ok(a) =>
				if a == "-pci-bridge" {
					Machine.flags(args, i + 1, { ..f, bridge: True }, e1000, hpet)
				} else if a == "-pci-bridge-deep" {
					Machine.flags(args, i + 1, { ..f, bridge: True, deep: True }, e1000, hpet)
				} else if a == "-pci-bridge-backward" {
					Machine.flags(args, i + 1, { ..f, bridge: True, backward: True }, e1000, hpet)
				} else if a == "-pci-bridge-levels" {
					n = U64.from_str(List.get(args, i + 1) ?? "") ?? crash("machine: -pci-bridge-levels wants a number")
					Machine.flags(args, i + 2, { ..f, bridge: True, levels: n }, e1000, hpet)
				} else if a == "-board-mmio" {
					Machine.flags(args, i + 1, { ..f, board_mmio: True }, e1000, hpet)
				} else if a == "-dhcp-lease" {
					n = U64.from_str(List.get(args, i + 1) ?? "") ?? crash("machine: -dhcp-lease wants a number")
					Machine.flags(args, i + 2, { ..f, lease: n }, e1000, hpet)
				} else if a == "-disk" or a == "-disk2" {
					path = List.get(args, i + 1) ?? crash("machine: ${a} wants a file")
					at = if a == "-disk" { 0 } else { 1 }
					Machine.flags(args, i + 2, { ..f, disks: List.set(f.disks, at, path) ?? crash("machine: no such drive position") }, e1000, hpet)
				} else {
					match MachineE1000.flag(e1000, a, List.get(args, i + 1) ?? "") {
						Took(e, n) => Machine.flags(args, i + n, f, e, hpet)
						NotMine =>
							match MachineHpet.flag(hpet, a) {
								Took(h) => Machine.flags(args, i + 1, f, e1000, h)
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
		ide: MachineIde.new,
		ne2k: MachineNe2k.reset,
		rx: [],
		lease: 3600,
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
		scopes: Dict.empty(),
		net_scopes: Dict.empty(),
		ports: MachinePorts.new,
		apic: MachineApic.new,
	}

	tick : Machine.Machine -> Machine.Machine
	tick = |m| { ..m, steps: m.steps + 1 }

	# ---- the doors emitted Codex calls ----------------------------------
	#
	# A Codex builtin with the machine threaded through: the machine first, and
	# answered back beside the builtin's own answer, in Codex's Integer.

	# **THE MACHINE'S CLOCK MOVES WHEN THE PROGRAM TOUCHES A DEVICE REGISTER.**
	# Each read or write of a device register, in an MMIO window or at a port,
	# costs 10 µs, in the HPET's counter ticks; memory costs nothing. codex-vm's
	# clocks follow the host's, and the verdicts judge durations by bands the
	# constant has to land in:
	# - e1000-tx-deadline wants two clock readings with nothing between them,
	#   and a million memory reads, under 5 ms: under 1.6 ms a register access,
	#   and memory free.
	# - timer-registers arms the local APIC for 160 ms and spins 8,000 register
	#   reads before sampling it again, expecting the count still falling:
	#   under 20 µs a register access.
	# - e1000-link-deadline waits 8 s by the clock across batches of 4,096
	#   STATUS reads, which 10 µs keeps to about half a million reads.
	access_cost : U64
	access_cost = 143

	# **THE ADDRESS SPACE IS WHAT CODEX-VM BACKS, AND NOTHING ELSE.** Guest RAM
	# is the low 3 GB, codex-vm's default. Above it are the device windows
	# codex-vm traps, and under -board-mmio the three board peripheral windows it
	# maps as RAM, over any device window they cover. An address none of these
	# claims is one codex-vm faults on, or a device this machine does not model,
	# so a load or store there stops the run and names the address rather than
	# answering from memory.
	region : Machine.Machine, I64 -> [Ram, Nic, Hpet, Lapic, Ioapic, Nothing(Str)]
	region = |m, a|
		if a >= 0 and a < Machine.ram_size {
			Ram
		} else if m.board_mmio and Machine.board_window(a) {
			Ram
		} else if m.e1000.present and MachineE1000.claims(a) {
			Nic
		} else if MachineHpet.claims(a) {
			Hpet
		} else if MachineApic.claims_lapic(a) {
			Lapic
		} else if MachineApic.claims_ioapic(a) {
			Ioapic
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
		if a >= 0xFE000000 and a < 0xFE004000 and !m.board_mmio {
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
					h = Machine.hpet_polled(m, clock)
					({ ..m, clock: clock, hpet: h }, U64.to_i64_wrap(MachineHpet.read(h, clock, I64.to_u64_wrap(a - MachineHpet.base))))
				}
			Lapic =>
				if width != 4 {
					crash("machine: a ${I64.to_str(width)}-byte read of the local APIC's registers, which this machine answers 32 bits at a time")
				} else {
					clock = m.clock + Machine.access_cost
					({ ..m, clock: clock }, U64.to_i64_wrap(MachineApic.lapic_read(m.apic, clock, I64.to_u64_wrap(a - MachineApic.lapic_base))))
				}
			Ioapic =>
				if width != 4 {
					crash("machine: a ${I64.to_str(width)}-byte read of the IOAPIC's registers, which this machine answers 32 bits at a time")
				} else {
					({ ..m, clock: m.clock + Machine.access_cost }, U64.to_i64_wrap(MachineApic.ioapic_read(m.apic, I64.to_u64_wrap(a - MachineApic.ioapic_base))))
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
					h = Machine.hpet_polled(m, clock)
					({ ..m, clock: clock, hpet: MachineHpet.write(h, clock, I64.to_u64_wrap(a - MachineHpet.base), U64.bitwise_and(u, 0xFFFFFFFF)) }, 0)
				}
			Lapic =>
				if width != 4 {
					crash("machine: a ${I64.to_str(width)}-byte write to the local APIC's registers, which this machine takes 32 bits at a time")
				} else {
					clock = m.clock + Machine.access_cost
					match MachineApic.lapic_write(m.apic, clock, I64.to_u64_wrap(a - MachineApic.lapic_base), U64.bitwise_and(u, 0xFFFFFFFF)) {
						Wrote(apic) => ({ ..m, clock: clock, apic: apic }, 0)
						StartsCores => crash("machine: a start-up IPI, which starts the application processors, and this machine has one core")
					}
				}
			Ioapic =>
				if width != 4 {
					crash("machine: a ${I64.to_str(width)}-byte write to the IOAPIC's registers, which this machine takes 32 bits at a time")
				} else {
					({ ..m, clock: m.clock + Machine.access_cost, apic: MachineApic.ioapic_write(m.apic, I64.to_u64_wrap(a - MachineApic.ioapic_base), U64.bitwise_and(u, 0xFFFFFFFF)) }, 0)
				}
			Nothing(what) => crash("machine: a write at ${Machine.hex(I64.to_u64_wrap(a))}, ${what}")
		}
	}

	# The HPET's timer 0, checked when the clock reads `clock`. An interrupt it
	# raises on an IOAPIC line whose entry is unmasked would reach the kernel's
	# device-interrupt handler, and this machine delivers no interrupts, so the
	# run stops there.
	hpet_polled : Machine.Machine, U64 -> MachineHpet.Hpet
	hpet_polled = |m, clock| {
		(h, raised) = MachineHpet.poll(m.hpet, clock)
		match raised {
			Quiet => h
			Raised(line) =>
				match MachineApic.delivers(m.apic, line) {
					Nowhere => h
					Vector(v) => crash("machine: the HPET raised IOAPIC line ${U64.to_str(line)} on vector ${U64.to_str(v)}, and this machine delivers no interrupts")
				}
		}
	}

	# The NIC may touch memory unless -nic-bme-clear has left its bus-master
	# bit clear.
	nic_dma : Machine.Machine -> Bool
	nic_dma = |m| !m.e1000.faults.bme_clear or MachinePci.bus_master(m.pci, 32902, 2)

	# `atomic-exchange`: the qword at the address becomes `value`, and the old
	# one is the answer, as x86's xchg.
	# `__buf-write-byte base off v`: the low byte of `v` at base + off, to
	# whatever backs the address; answers off + 1.
	write_byte : Machine.Machine, I64, I64, I64 -> (Machine.Machine, I64)
	write_byte = |m, base, off, v| {
		(next, _) = Machine.store(m, base, off, v, 1)
		(next, off + 1)
	}

	# `__buf-write-bytes base off bytes`: the low byte of each element from
	# base + off on, to whatever backs each address; answers off plus the
	# count, the offset past the last.
	write_bytes : Machine.Machine, I64, I64, List(I64) -> (Machine.Machine, I64)
	write_bytes = |m, base, off, bytes| (Machine.write_each(m, base + off, bytes, 0), off + U64.to_i64_wrap(List.len(bytes)))

	write_each : Machine.Machine, I64, List(I64), U64 -> Machine.Machine
	write_each = |m, at, bytes, i|
		match List.get(bytes, i) {
			Err(_) => m
			Ok(b) => {
				(next, _) = Machine.store(m, at, U64.to_i64_wrap(i), b, 1)
				Machine.write_each(next, at, bytes, i + 1)
			}
		}

	# `__buf-read-bytes base off count`: the `count` bytes from base + off on,
	# each as an unsigned value from whatever backs its address; a count of
	# zero or less reads none. The list is a Roc value, so the heap's bump
	# pointer does not move for it, as it moves for no list.
	read_bytes : Machine.Machine, I64, I64, I64 -> (Machine.Machine, List(I64))
	read_bytes = |m, base, off, count| Machine.read_each(m, base + off, count, List.with_capacity(I64.to_u64_wrap(I64.max(count, 0))))

	read_each : Machine.Machine, I64, I64, List(I64) -> (Machine.Machine, List(I64))
	read_each = |m, at, count, acc| {
		i = U64.to_i64_wrap(List.len(acc))
		if i >= count {
			(m, acc)
		} else {
			(next, b) = Machine.load(m, at, i, 1)
			Machine.read_each(next, at, count, List.append(acc, b))
		}
	}

	exchange : Machine.Machine, I64, I64 -> (Machine.Machine, I64)
	exchange = |m, addr, value| {
		(read, old) = Machine.load(m, addr, 0, 8)
		(written, _) = Machine.store(read, addr, 0, value, 8)
		(written, old)
	}

	alloc : Machine.Machine, I64 -> (Machine.Machine, I64)
	alloc = |m, n| {
		(mem, at) = MachineMem.alloc(m.mem, n)
		({ ..m, mem: mem }, at)
	}

	# `__heap-advance`: the bump pointer moves past `n` bytes, and the answer is
	# Nothing.
	advance : Machine.Machine, I64 -> (Machine.Machine, {})
	advance = |m, n| {
		(mem, _at) = MachineMem.alloc(m.mem, n)
		({ ..m, mem: mem }, {})
	}

	# `__heap-save` answers the bump pointer, and `__heap-restore` rewinds to it
	# and answers 0, as x86's r10 does.
	mark : Machine.Machine -> (Machine.Machine, I64)
	mark = |m| (m, m.mem.top)

	release : Machine.Machine, I64 -> (Machine.Machine, I64)
	release = |m, h| ({ ..m, mem: { root: m.mem.root, top: h } }, 0)

	# **A PORT IS A DEVICE REGISTER.** Every port read or write moves the
	# machine's clock by `access_cost`, as a register access in an MMIO window
	# does, and answers as codex-vm does at that port (MachinePorts), at the
	# width the builtin names. The writes answer 0, as they do on x86.

	# `port-out-32`: 0xCF8 latches a PCI address and 0xCFC..0xCFF write the
	# register it names; any other port is the port map's.
	port_out_32 : Machine.Machine, I64, I64 -> (Machine.Machine, I64)
	port_out_32 = |m, port, value| {
		p = I64.to_u64_wrap(port)
		v = U64.bitwise_and(I64.to_u64_wrap(value), MachinePci.all_ones)
		clock = m.clock + Machine.access_cost
		if p == MachinePci.config_addr {
			({ ..m, pci: MachinePci.latch(m.pci, v), clock: clock }, 0)
		} else if p >= MachinePci.config_data and p <= MachinePci.config_data + 3 {
			({ ..m, pci: MachinePci.write(m.pci, v), clock: clock }, 0)
		} else {
			Machine.port_write(m, p, v, "port-out-32")
		}
	}

	# `port-in-32`: 0xCFC..0xCFF read the register the latched address names.
	port_in_32 : Machine.Machine, I64 -> (Machine.Machine, I64)
	port_in_32 = |m, port| {
		p = I64.to_u64_wrap(port)
		if p >= MachinePci.config_data and p <= MachinePci.config_data + 3 {
			({ ..m, clock: m.clock + Machine.access_cost }, U64.to_i64_wrap(MachinePci.read(m.pci, p - MachinePci.config_data)))
		} else {
			Machine.port_read(m, p, MachinePci.all_ones, "port-in-32")
		}
	}

	# **THE BYTE AND 16-BIT DOORS ARE EFFECTS.** They reach the IDE channel,
	# whose commands load and store sectors through MachineDisk's doors, which
	# on the native platform are the host's files. The 32-bit doors reach PCI
	# and the port map, and are not.
	port_out_byte! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	port_out_byte! = |m, port, value| Machine.port_out!(m, I64.to_u64_wrap(port), U64.bitwise_and(I64.to_u64_wrap(value), 0xFF), "port-out-byte")

	port_out_16! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	port_out_16! = |m, port, value| Machine.port_out!(m, I64.to_u64_wrap(port), U64.bitwise_and(I64.to_u64_wrap(value), 0xFFFF), "port-out-16")

	port_in_byte! : Machine.Machine, I64 => (Machine.Machine, I64)
	port_in_byte! = |m, port| Machine.port_in!(m, I64.to_u64_wrap(port), 0xFF, "port-in-byte")

	port_in_16! : Machine.Machine, I64 => (Machine.Machine, I64)
	port_in_16! = |m, port| Machine.port_in!(m, I64.to_u64_wrap(port), 0xFFFF, "port-in-16")

	# A byte or 16-bit access: the IDE channel's registers, the NE2000's, or
	# the port map.
	port_out! : Machine.Machine, U64, U64, Str => (Machine.Machine, I64)
	port_out! = |m, p, v, builtin|
		if MachineIde.claims(p) {
			(ide, drives) = MachineIde.write!(m.ide, m.drives, p, v)
			({ ..m, ide: ide, drives: drives, clock: m.clock + Machine.access_cost }, 0)
		} else if p >= 0x300 and p < 0x320 {
			Machine.ne2k_write(m, p - 0x300, v, if builtin == "port-out-byte" { 1 } else { 2 })
		} else {
			Machine.port_write(m, p, v, builtin)
		}

	port_in! : Machine.Machine, U64, U64, Str => (Machine.Machine, I64)
	port_in! = |m, p, mask, builtin|
		if MachineIde.claims(p) {
			(ide, v) = MachineIde.read!(m.ide, m.drives, p)
			({ ..m, ide: ide, clock: m.clock + Machine.access_cost }, U64.to_i64_wrap(U64.bitwise_and(v, mask)))
		} else if p >= 0x300 and p < 0x320 {
			(card, v) = MachineNe2k.read(m.ne2k, p - 0x300, if mask == 0xFF { 1 } else { 2 })
			({ ..m, ne2k: card, clock: m.clock + Machine.access_cost }, U64.to_i64_wrap(U64.bitwise_and(v, mask)))
		} else {
			Machine.port_read(m, p, mask, builtin)
		}

	# A write to the NE2000. A transmit hands the frame to the NAT, and what
	# the NAT answers is queued, at most 256 frames; a transmit or a BNRY write
	# lays the queue into the ring.
	ne2k_write : Machine.Machine, U64, U64, U64 -> (Machine.Machine, I64)
	ne2k_write = |m, off, v, size| {
		(card, effect) = MachineNe2k.write(m.ne2k, off, v, size)
		queue =
			match effect {
				Transmit(frame) =>
					match MachineNat.tx(frame, m.lease) {
						Replies(frames) => List.sublist(List.concat(m.rx, frames), { start: 0, len: 256 })
						Host(what) => crash("machine: the program sent a frame to ${what}, which this machine does not have")
					}
				_ => m.rx
			}
		(laid, rest) =
			match effect {
				Nothing => (card, queue)
				_ => MachineNe2k.inject(card, queue)
			}
		({ ..m, ne2k: laid, rx: rest, clock: m.clock + Machine.access_cost }, 0)
	}

	# ---- the network ----------------------------------------------------
	#
	# x86's network builtins are kernel helpers that drive the NE2000 through
	# its ports (X86_64IPCHelpers), once the running process's capability word
	# allows it: network-read, bit 8, or network-write, bit 9; otherwise they
	# answer -1, as they do when the boot found no card. The boot leaves the
	# card's presence at 33024 and its station address at 33032.

	nic_present_addr : I64
	nic_present_addr = 33024

	nic_mac_addr : I64
	nic_mac_addr = 33032

	net_allowed : Machine.Machine, I64 -> Bool
	net_allowed = |m, bit| U64.bitwise_and(MachineMem.read(m.mem, MachineCaps.word_addr, 7, 0), MachineCaps.bit(bit)) != 0

	# `net-status`: whether the boot found the card.
	net_status : Machine.Machine -> (Machine.Machine, I64)
	net_status = |m|
		if Machine.net_allowed(m, MachineCaps.network_read) {
			(m, U64.to_i64_wrap(MachineMem.read(m.mem, Machine.nic_present_addr, 7, 0)))
		} else {
			(m, -1)
		}

	# `net-get-hwaddr i`: byte `i` of the station address; -1 from 6 on.
	net_get_hwaddr : Machine.Machine, I64 -> (Machine.Machine, I64)
	net_get_hwaddr = |m, i|
		if !Machine.net_allowed(m, MachineCaps.network_read) or i >= 6 {
			(m, -1)
		} else {
			(m, U64.to_i64_wrap(MachineMem.read(m.mem, Machine.nic_mac_addr + i, 0, 0)))
		}

	# `net-send-raw buf len`: the frame into card memory at page 64 by remote
	# DMA, `len` halved in words, then transmitted; answers `len`.
	net_send_raw! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	net_send_raw! = |m, buf, len|
		if !Machine.net_allowed(m, MachineCaps.network_write) or MachineMem.read(m.mem, Machine.nic_present_addr, 7, 0) == 0 {
			(m, -1)
		} else {
			n = I64.to_u64_wrap(len)
			hi = U64.to_i64_wrap(U64.div_trunc_by(n, 256))
			staged = Machine.outs!(m, [(0x300, 0x22), (0x308, 0), (0x309, 64), (0x30A, len), (0x30B, hi), (0x300, 0x12)])
			(copied, _) = Machine.outsw!(staged, buf, 0, U64.to_i64_wrap(U64.div_trunc_by(n, 2)), 0x310)
			(Machine.outs!(copied, [(0x304, 64), (0x305, len), (0x306, hi), (0x300, 0x26)]), len)
		}

	# `net-recv-raw buf`: the next frame in the ring, if CURR has moved past
	# BNRY, into `buf` a word at a time, BNRY moved on; answers its length, 0
	# when there is none or its header's length is past 1,536.
	net_recv_raw! : Machine.Machine, I64 => (Machine.Machine, I64)
	net_recv_raw! = |m, buf|
		if !Machine.net_allowed(m, MachineCaps.network_read) or MachineMem.read(m.mem, Machine.nic_present_addr, 7, 0) == 0 {
			(m, -1)
		} else {
			(m1, curr) = Machine.port_in_byte!(Machine.outs!(m, [(0x300, 0x62)]), 0x307)
			(m2, bnry) = Machine.port_in_byte!(Machine.outs!(m1, [(0x300, 0x22)]), 0x303)
			if bnry == curr {
				(m2, 0)
			} else {
				m3 = Machine.outs!(m2, [(0x308, 0), (0x309, bnry), (0x30A, 4), (0x30B, 0), (0x300, 0x0A)])
				(m4, head) = Machine.port_in_16!(m3, 0x310)
				(m5, total) = Machine.port_in_16!(m4, 0x310)
				body = U64.minus_wrap(I64.to_u64_wrap(total), 4)
				if body > 1536 {
					(m5, 0)
				} else {
					even = U64.bitwise_and(body + 1, 0xFFFFFFFFFFFFFFFE)
					m6 = Machine.outs!(m5, [(0x308, 4), (0x30A, U64.to_i64_wrap(even)), (0x30B, U64.to_i64_wrap(U64.div_trunc_by(even, 256))), (0x300, 0x0A)])
					(m7, _) = Machine.insw!(m6, buf, 0, U64.to_i64_wrap(U64.div_trunc_by(even, 2)), 0x310)
					(Machine.outs!(m7, [(0x303, I64.div_trunc_by(head, 256))]), U64.to_i64_wrap(body))
				}
			}
		}

	# Bytes out to ports, in order.
	outs! : Machine.Machine, List((I64, I64)) => Machine.Machine
	outs! = |m, writes| Machine.outs_from!(m, writes, 0)

	outs_from! : Machine.Machine, List((I64, I64)), U64 => Machine.Machine
	outs_from! = |m, writes, i|
		match List.get(writes, i) {
			Err(_) => m
			Ok(w) => {
				(port, v) = w
				(next, _) = Machine.port_out_byte!(m, port, v)
				Machine.outs_from!(next, writes, i + 1)
			}
		}

	# `port-in-16-block addr count port` is x86's `rep insw`: `count` words from
	# the port into memory at `addr`, answering 0; `port-out-16-block` is `rep
	# outsw`, the other way. A buffer in the GPU's memory page (addresses whose
	# top bits are 190) needs the running process's gpu-memory capability, and
	# without it nothing moves and the answer is -1 (X86_64Boot's
	# emit-gpu-mem-guard). Each word is one access to the port.
	port_in_16_block! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	port_in_16_block! = |m, addr, count, port|
		if Machine.gpu_page_denied(m, addr) {
			(m, -1)
		} else {
			Machine.insw!(m, addr, 0, count, port)
		}

	port_out_16_block! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
	port_out_16_block! = |m, addr, count, port|
		if Machine.gpu_page_denied(m, addr) {
			(m, -1)
		} else {
			Machine.outsw!(m, addr, 0, count, port)
		}

	insw! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	insw! = |m, addr, i, count, port|
		if i >= count {
			(m, 0)
		} else {
			(m1, w) = Machine.port_in_16!(m, port)
			(m2, _) = Machine.store(m1, addr, i * 2, w, 2)
			Machine.insw!(m2, addr, i + 1, count, port)
		}

	outsw! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	outsw! = |m, addr, i, count, port|
		if i >= count {
			(m, 0)
		} else {
			(m1, w) = Machine.load(m, addr, i * 2, 2)
			(m2, _) = Machine.port_out_16!(m1, port, w)
			Machine.outsw!(m2, addr, i + 1, count, port)
		}

	gpu_page_denied : Machine.Machine, I64 -> Bool
	gpu_page_denied = |m, addr|
		U64.div_trunc_by(I64.to_u64_wrap(addr), 0x1000000) == 190
		and U64.bitwise_and(MachineMem.read(m.mem, MachineCaps.word_addr, 7, 0), MachineCaps.bit(MachineCaps.gpu_memory)) == 0

	port_write : Machine.Machine, U64, U64, Str -> (Machine.Machine, I64)
	port_write = |m, p, v, builtin| {
		clock = m.clock + Machine.access_cost
		match MachinePorts.write(m.ports, clock, p, v) {
			Wrote(ports) => ({ ..m, ports: ports, clock: clock }, 0)
			Claimed(device) => crash("machine: ${builtin} to port ${Machine.hex(p)}, ${device}, which this machine does not model")
		}
	}

	port_read : Machine.Machine, U64, U64, Str -> (Machine.Machine, I64)
	port_read = |m, p, mask, builtin| {
		clock = m.clock + Machine.access_cost
		match MachinePorts.read(m.ports, clock, p) {
			Read(ports, v) => ({ ..m, ports: ports, clock: clock }, U64.to_i64_wrap(U64.bitwise_and(v, mask)))
			Claimed(device) => crash("machine: ${builtin} from port ${Machine.hex(p)}, ${device}, which this machine does not model")
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
	# One process runs, the boot program; nothing spawns another. The table has
	# 16 entries of 256 bytes at 20480, and a pid past it is refused.

	proc_table : I64
	proc_table = 20480

	cap_addr : I64 -> I64
	cap_addr = |pid| Machine.proc_table + pid * 256 + 56

	# The running process holds capability-admin, bit 14.
	admin : Machine.Machine -> Bool
	admin = |m| U64.bitwise_and(MachineMem.read(m.mem, MachineCaps.word_addr, 7, 0), 0x4000) != 0

	# `process-get-pid`: the boot program's stack is outside the spawn pool,
	# which x86 answers as slot 0.
	process_get_pid : Machine.Machine -> (Machine.Machine, I64)
	process_get_pid = |m| (m, 0)

	# `process-yield`: x86 scans the table from the slot after the running one
	# for a READY process (state 1) whose affinity (offset 16) is -1 or the
	# running process's core (offset 8), and answers 0 when it finds none. No
	# process but the booted one runs here, so a READY slot stops the run.
	process_yield : Machine.Machine -> (Machine.Machine, I64)
	process_yield = |m|
		match Machine.ready_slot(m, 1) {
			Ok(pid) => crash("machine: process-yield found process ${I64.to_str(pid)} ready, and this machine runs no process but the booted one")
			Err(_) => (m, 0)
		}

	ready_slot : Machine.Machine, I64 -> Try(I64, [NoneReady])
	ready_slot = |m, pid|
		if pid >= 16 {
			Err(NoneReady)
		} else {
			entry = Machine.proc_table + pid * 256
			affinity = U64.to_i64_wrap(MachineMem.read(m.mem, entry + 16, 7, 0))
			core = U64.to_i64_wrap(MachineMem.read(m.mem, Machine.proc_table + 8, 7, 0))
			if MachineMem.read(m.mem, entry, 7, 0) == 1 and (affinity == -1 or affinity == core) {
				Ok(pid)
			} else {
				Machine.ready_slot(m, pid + 1)
			}
		}

	# `process-get-cap`: a process's capability word; -1 past the table.
	process_get_cap : Machine.Machine, I64 -> (Machine.Machine, I64)
	process_get_cap = |m, pid| if pid >= 16 { (m, -1) } else { Machine.load(m, Machine.cap_addr(pid), 0, 8) }

	# `process-restrict-cap`: clears one bit of a process's word and answers 0,
	# or answers -1 when the running process lacks capability-admin or the pid
	# is past the table.
	process_restrict_cap : Machine.Machine, I64, I64 -> (Machine.Machine, I64)
	process_restrict_cap = |m, pid, bit|
		if !Machine.admin(m) or pid >= 16 {
			(m, -1)
		} else {
			a = Machine.cap_addr(pid)
			word = MachineMem.read(m.mem, a, 7, 0)
			cleared = U64.bitwise_and(word, U64.bitwise_xor(U64.shl_wrap(1, U64.to_u8_wrap(I64.to_u64_wrap(bit))), 0xFFFFFFFFFFFFFFFF))
			({ ..m, mem: MachineMem.write(m.mem, a, cleared, 8) }, 0)
		}

	# `process-set-scope`: a process's filesystem scope, under the same two
	# refusals as `process-restrict-cap`; answers 0.
	process_set_scope : Machine.Machine, I64, Str -> (Machine.Machine, I64)
	process_set_scope = |m, pid, scope|
		if !Machine.admin(m) or pid >= 16 {
			(m, -1)
		} else {
			({ ..m, scopes: Dict.insert(m.scopes, I64.to_u64_wrap(pid), scope) }, 0)
		}

	# `process-get-scope` and `process-get-network-scope`: the scope given, and
	# the empty text, which admits everything, when none was or the pid is past
	# the table.
	process_get_scope : Machine.Machine, I64 -> (Machine.Machine, Str)
	process_get_scope = |m, pid| (m, if pid >= 16 { "" } else { Dict.get(m.scopes, I64.to_u64_wrap(pid)) ?? "" })

	process_get_network_scope : Machine.Machine, I64 -> (Machine.Machine, Str)
	process_get_network_scope = |m, pid| (m, if pid >= 16 { "" } else { Dict.get(m.net_scopes, I64.to_u64_wrap(pid)) ?? "" })

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
