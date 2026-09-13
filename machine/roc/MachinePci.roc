# PCI configuration space, as codex-vm models it for upstream's tests
# (tools/codex-vm.c): an address latched through port 0xCF8 and a table of at
# most ten devices answering through 0xCFC. An empty slot, or any function
# other than 0, reads all ones, the value a bus walk skips; with the enable
# bit clear nothing answers, and the port reads 0xFF, as an unclaimed port does
# there.
#
# The bridge flags add codex-vm's chain of PCI-to-PCI bridges (header type 1,
# QEMU's pcie-root-port 1b36:000c), each with a virtio-net endpoint 1af4:1041
# behind it, in codex-vm's creation order, so the ten-device cap drops the
# devices it drops there.

MachinePci :: [].{
	Device : {
		bus : U64,
		slot : U64,
		vendor : U64,
		device : U64,
		class : U64,
		sub : U64,
		progif : U64,
		header : U64,
		# Six BARs, the window each decodes, and whether the guest is sizing
		# it: a write of all ones asks the size and keeps the base.
		bars : List(U64),
		sizes : List(U64),
		probing : List(Bool),
		irq : U64,
		command : U64,
		# A bridge's secondary and subordinate buses.
		secondary : U64,
		subordinate : U64,
	}

	Pci : { addr : U64, devices : List(MachinePci.Device) }

	# 0xCF8, and the first of the four data ports from 0xCFC.
	config_addr : U64
	config_addr = 3320

	config_data : U64
	config_data = 3324

	all_ones : U64
	all_ones = 4294967295

	max_devices : U64
	max_devices = 10

	# codex-vm's table: Bochs VGA 1234:1111, the NEC xHCI 1033:0194 with its
	# 16 KB register window, Intel HDA 8086:2668, on bus 0 slots 0..2, then
	# `levels` bridges. Each bridge sits on the bus before its level, the first
	# on the next bus-0 slot and the rest on slot 1, forwards to its level's
	# bus, and names the deepest bus as subordinate; the endpoint behind it
	# takes slot 0. `backward` points the deepest bridge at bus 0.
	table : U64, Bool -> MachinePci.Pci
	table = |levels, backward| {
		(t1, _vga) = MachinePci.add([], MachinePci.fresh(4660, 4369, 3, 0, 0, 4244635648, 0))
		xhci = MachinePci.fresh(4147, 404, 12, 3, 48, 4269801472, 10)
		(t2, _xhci) = MachinePci.add(t1, { ..xhci, sizes: [16384, 0, 0, 0, 0, 0] })
		(t3, _hda) = MachinePci.add(t2, MachinePci.fresh(32902, 9832, 4, 3, 0, 4261412864, 11))
		{ addr: 0, devices: MachinePci.bridges(t3, 1, levels, backward) }
	}

	bridges : List(MachinePci.Device), U64, U64, Bool -> List(MachinePci.Device)
	bridges = |ds, lv, levels, backward|
		if lv > levels {
			ds
		} else {
			(with_bridge, b) = MachinePci.add(ds, MachinePci.fresh(6966, 12, 6, 4, 0, 0, 0))
			placed = match b {
				At(i) => MachinePci.change(with_bridge, i, |d| {
					..d,
					header: 1,
					bus: lv - 1,
					slot: if lv == 1 { i } else { 1 },
					secondary: if backward and lv == levels { 0 } else { lv },
					subordinate: levels,
				})
				Full => with_bridge
			}
			(with_endpoint, e) = MachinePci.add(placed, MachinePci.fresh(6900, 4161, 2, 0, 0, 0, 0))
			behind = match e {
				At(i) => MachinePci.change(with_endpoint, i, |d| { ..d, bus: lv, slot: 0 })
				Full => with_endpoint
			}
			MachinePci.bridges(behind, lv + 1, levels, backward)
		}

	# A device as `pci_add_device` makes one: I/O and memory decoding on, and
	# one BAR, which decodes 64 KB when it has a base.
	fresh : U64, U64, U64, U64, U64, U64, U64 -> MachinePci.Device
	fresh = |vendor, device, class, sub, progif, bar0, irq| {
		bus: 0,
		slot: 0,
		vendor: vendor,
		device: device,
		class: class,
		sub: sub,
		progif: progif,
		header: 0,
		bars: [bar0, 0, 0, 0, 0, 0],
		sizes: [if bar0 == 0 { 0 } else { 65536 }, 0, 0, 0, 0, 0],
		probing: [False, False, False, False, False, False],
		irq: irq,
		command: 3,
		secondary: 0,
		subordinate: 0,
	}

	# `pci_add_device`: the device answers on bus 0 at the slot equal to its
	# index, and once the table is full nothing is added.
	add : List(MachinePci.Device), MachinePci.Device -> (List(MachinePci.Device), [At(U64), Full])
	add = |ds, d| {
		i = List.len(ds)
		if i >= MachinePci.max_devices { (ds, Full) } else { (List.append(ds, { ..d, slot: i }), At(i)) }
	}

	change : List(MachinePci.Device), U64, (MachinePci.Device -> MachinePci.Device) -> List(MachinePci.Device)
	change = |ds, i, f| List.update(ds, i, f) ?? crash("Pci: no device at that index")

	# ---- the ports --------------------------------------------------------

	latch : MachinePci.Pci, U64 -> MachinePci.Pci
	latch = |pci, v| { ..pci, addr: v }

	# The latched address: enable bit 31, bus 23..16, slot 15..11, function
	# 10..8, register 7..2.
	target : MachinePci.Pci -> [Off, Empty, Hit(U64, MachinePci.Device, U64)]
	target = |pci| {
		a = pci.addr
		if U64.bitwise_and(a, 2147483648) == 0 {
			Off
		} else if U64.bitwise_and(U64.div_trunc_by(a, 256), 7) != 0 {
			Empty
		} else {
			bus = U64.bitwise_and(U64.div_trunc_by(a, 65536), 255)
			slot = U64.bitwise_and(U64.div_trunc_by(a, 2048), 31)
			match MachinePci.find(pci.devices, bus, slot, 0) {
				Found(i, d) => Hit(i, d, U64.bitwise_and(a, 252))
				Missing => Empty
			}
		}
	}

	find : List(MachinePci.Device), U64, U64, U64 -> [Found(U64, MachinePci.Device), Missing]
	find = |ds, bus, slot, i|
		match List.get(ds, i) {
			Ok(d) => if d.bus == bus and d.slot == slot { Found(i, d) } else { MachinePci.find(ds, bus, slot, i + 1) }
			Err(_) => Missing
		}

	# A read through the data port `k` bytes past 0xCFC: the register, shifted
	# down by those bytes.
	read : MachinePci.Pci, U64 -> U64
	read = |pci, k|
		match MachinePci.target(pci) {
			Off => 255
			Empty => U64.div_trunc_by(MachinePci.all_ones, U64.pow(256, k))
			Hit(_i, d, off) => U64.div_trunc_by(MachinePci.register(d, off), U64.pow(256, k))
		}

	# Ids at 0x00, command at 0x04, class at 0x08 and header type at 0x0C, on
	# every device. A bridge has its bus numbers at 0x18 and nothing else; an
	# endpoint has BARs at 0x10..0x24 and its IRQ line at 0x3C.
	register : MachinePci.Device, U64 -> U64
	register = |d, off|
		if off == 0 {
			d.vendor + d.device * 65536
		} else if off == 4 {
			d.command
		} else if off == 8 {
			d.class * 16777216 + d.sub * 65536 + d.progif * 256
		} else if off == 12 {
			d.header * 65536
		} else if d.header == 1 {
			if off == 24 { d.bus + d.secondary * 256 + d.subordinate * 65536 } else { 0 }
		} else if off >= 16 and off <= 36 {
			MachinePci.bar(d, U64.div_trunc_by(off - 16, 4))
		} else if off == 60 {
			d.irq
		} else {
			0
		}

	# A BAR reads its base; while it is being sized, all ones above its window
	# with its four type bits kept, and 0 when it decodes nothing.
	bar : MachinePci.Device, U64 -> U64
	bar = |d, k| {
		base = List.get(d.bars, k) ?? 0
		size = List.get(d.sizes, k) ?? 0
		if !(List.get(d.probing, k) ?? False) {
			base
		} else if size == 0 {
			0
		} else {
			U64.bitwise_or(MachinePci.all_ones - (size - 1), U64.bitwise_and(base, 15))
		}
	}

	# A write through a data port. A bridge takes a command and nothing else,
	# since its bus numbers are fixed; an endpoint takes a command, or a BAR,
	# where all ones asks the size and keeps the base.
	write : MachinePci.Pci, U64 -> MachinePci.Pci
	write = |pci, v|
		match MachinePci.target(pci) {
			Hit(i, d, off) => { ..pci, devices: List.set(pci.devices, i, MachinePci.written(d, off, v)) ?? crash("Pci: no device at that index") }
			_ => pci
		}

	written : MachinePci.Device, U64, U64 -> MachinePci.Device
	written = |d, off, v|
		if off == 4 {
			{ ..d, command: U64.bitwise_and(v, 65535) }
		} else if d.header == 1 or off < 16 or off > 36 {
			d
		} else {
			k = U64.div_trunc_by(off - 16, 4)
			sizing = v == MachinePci.all_ones
			probing = List.set(d.probing, k, sizing) ?? crash("Pci: no such BAR")
			if sizing { { ..d, probing: probing } } else { { ..d, probing: probing, bars: List.set(d.bars, k, v) ?? crash("Pci: no such BAR") } }
		}
}
