# PCI configuration space, as codex-vm models it for upstream's tests
# (tools/codex-vm.c): a latched address on port 0xCF8 and a table of devices
# answering reads on 0xCFC. An empty slot, or any function other than 0, reads
# all ones, the value a bus walk skips.
#
# Endpoints only, with one BAR each. Bridges (header type 1) and BAR sizing
# come when a test asks for them.

Pci :: [].{
	Device : { bus : U64, slot : U64, vendor : U64, device : U64, class : U64, sub : U64, progif : U64, bar0 : U64, irq : U64 }

	Pci : { addr : U64, devices : List(Pci.Device) }

	# codex-vm's default table: Bochs VGA 1234:1111, the NEC xHCI 1033:0194,
	# Intel HDA 8086:2668, on bus 0 slots 0..2.
	default : Pci.Pci
	default = {
		addr: 0,
		devices: [
			{ bus: 0, slot: 0, vendor: 4660, device: 4369, class: 3, sub: 0, progif: 0, bar0: 4244635648, irq: 0 },
			{ bus: 0, slot: 1, vendor: 4147, device: 404, class: 12, sub: 3, progif: 48, bar0: 4269801472, irq: 10 },
			{ bus: 0, slot: 2, vendor: 32902, device: 9832, class: 4, sub: 3, progif: 0, bar0: 4261412864, irq: 11 },
		],
	}

	# 0xCF8 and 0xCFC.
	config_addr : U64
	config_addr = 3320

	config_data : U64
	config_data = 3324

	all_ones : U64
	all_ones = 4294967295

	# A write to 0xCF8 latches the address; any other port is not PCI's.
	write_port : Pci.Pci, U64, U64 -> Pci.Pci
	write_port = |pci, port, value| if port == Pci.config_addr { { ..pci, addr: value } } else { pci }

	# A read of 0xCFC answers the register the latched address names:
	# enable bit 31, bus 23..16, slot 15..11, function 10..8, offset 7..2.
	read_port : Pci.Pci, U64 -> U64
	read_port = |pci, port|
		if port != Pci.config_data or pci.addr < 2147483648 {
			Pci.all_ones
		} else {
			a = pci.addr
			bus = U64.bitwise_and(U64.div_trunc_by(a, 65536), 255)
			slot = U64.bitwise_and(U64.div_trunc_by(a, 2048), 31)
			func = U64.bitwise_and(U64.div_trunc_by(a, 256), 7)
			off = U64.bitwise_and(a, 252)
			if func != 0 {
				Pci.all_ones
			} else {
				match Pci.find(pci.devices, bus, slot, 0) {
					Found(d) => Pci.register(d, off)
					Missing => Pci.all_ones
				}
			}
		}

	find : List(Pci.Device), U64, U64, U64 -> [Found(Pci.Device), Missing]
	find = |ds, bus, slot, i|
		match List.get(ds, i) {
			Ok(d) => if d.bus == bus and d.slot == slot { Found(d) } else { Pci.find(ds, bus, slot, i + 1) }
			Err(_) => Missing
		}

	# An endpoint's registers: ids at 0x00, command at 0x04 (I/O and memory
	# enabled), class at 0x08, header type at 0x0C, BAR 0 at 0x10, IRQ line
	# at 0x3C.
	register : Pci.Device, U64 -> U64
	register = |d, off|
		if off == 0 {
			d.vendor + d.device * 65536
		} else if off == 4 {
			3
		} else if off == 8 {
			d.class * 16777216 + d.sub * 65536 + d.progif * 256
		} else if off == 16 {
			d.bar0
		} else if off == 60 {
			d.irq
		} else {
			0
		}
}
