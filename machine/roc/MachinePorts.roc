# MachinePorts -- codex-vm's I/O ports other than PCI configuration space
# (tools/codex-vm.c, handle_io). The PIT's three channels and command register,
# the speaker gate at 0x61 and the CMOS index at 0x70 are modelled. A port
# another codex-vm device answers is named, so a program that reaches one
# stops the run there. Every other port is one codex-vm's handler leaves
# alone: a write is dropped and a read answers 0xFF.
#
# The PIT counts down from its reload value at 1,193,182 Hz. codex-vm counts
# by the host's clock; this machine counts by its own, in the HPET's ticks, of
# which there are twelve to a PIT tick.

MachinePorts :: [].{
	Channel : { mode : U64, access : U64, reload : U64, load_hi : Bool, read_hi : Bool, latched : U64, latch_valid : Bool }

	Ports : { pit : List(MachinePorts.Channel), speaker : Bool, cmos_index : U64 }

	new : MachinePorts.Ports
	new = {
		pit: List.repeat({ mode: 0, access: 0, reload: 0, load_hi: False, read_hi: False, latched: 0, latch_valid: False }, 3),
		speaker: False,
		cmos_index: 0,
	}

	# What answers at a port.
	owner : U64 -> [Pit, Speaker, CmosIndex, CmosData, Device(Str), Nobody]
	owner = |p|
		if p >= 0x40 and p <= 0x43 {
			Pit
		} else if p == 0x61 {
			Speaker
		} else if p == 0x70 {
			CmosIndex
		} else if p == 0x71 {
			CmosData
		} else if p == 0x20 or p == 0x21 or p == 0xA0 or p == 0xA1 {
			Device("the interrupt controllers")
		} else if (p >= 0x1F0 and p <= 0x1F7) or p == 0x3F6 {
			Device("the IDE channel at 32 bits")
		} else if p >= 0x3F8 and p <= 0x3FF {
			Device("COM1")
		} else if p >= 0x2F8 and p <= 0x2FF {
			Device("COM2")
		} else if p >= 0x3E8 and p <= 0x3EF {
			Device("COM3")
		} else if p >= 0x420 and p <= 0x423 {
			Device("the COM3 mailbox")
		} else if p == 0x60 or p == 0x64 {
			Device("the PS/2 keyboard controller")
		} else if p >= 0x300 and p < 0x320 {
			Device("the NE2000")
		} else if (p >= 0x3C0 and p <= 0x3CF) or p == 0x3D4 or p == 0x3D5 or p == 0x3DA {
			Device("the VGA registers")
		} else if p == 0x1CE or p == 0x1CF {
			Device("Bochs VBE")
		} else if p >= 0x400 and p <= 0x417 {
			Device("the GPU rasterizer")
		} else if p == 0x510 or p == 0x511 {
			Device("the host doorbell")
		} else if p >= 0xE0 and p <= 0xE4 {
			Device("the host's sleep and mouse ports")
		} else if p == 0xF4 {
			Device("the exit port")
		} else if p == 0x604 {
			Device("ACPI power control")
		} else if p == 0xCF9 {
			Device("the reset control register")
		} else if p == 0xCF8 or (p >= 0xCFC and p <= 0xCFF) {
			Device("PCI configuration space, at a width other than 32 bits")
		} else {
			Nobody
		}

	# A write, when the clock reads `clock`.
	write : MachinePorts.Ports, U64, U64, U64 -> [Wrote(MachinePorts.Ports), Claimed(Str)]
	write = |ports, clock, p, val|
		match MachinePorts.owner(p) {
			Pit => Wrote(MachinePorts.pit_write(ports, clock, p, U64.bitwise_and(val, 0xFF)))
			Speaker => Wrote({ ..ports, speaker: U64.bitwise_and(val, 3) == 3 })
			CmosIndex => Wrote({ ..ports, cmos_index: U64.bitwise_and(val, 0x7F) })
			CmosData => Wrote(ports)
			Device(name) => Claimed(name)
			Nobody => Wrote(ports)
		}

	# A read, when the clock reads `clock`.
	read : MachinePorts.Ports, U64, U64 -> [Read(MachinePorts.Ports, U64), Claimed(Str)]
	read = |ports, clock, p|
		match MachinePorts.owner(p) {
			Pit => {
				(next, v) = MachinePorts.pit_read(ports, clock, p)
				Read(next, v)
			}
			Speaker => Read(ports, if ports.speaker { 3 } else { 0 })
			CmosIndex => Read(ports, 0xFF)
			CmosData => MachinePorts.cmos_read(ports)
			Device(name) => Claimed(name)
			Nobody => Read(ports, 0xFF)
		}

	# CMOS 0x71: the status registers answer their fixed values, and the time
	# registers the host's local time, which this machine does not have.
	cmos_read : MachinePorts.Ports -> [Read(MachinePorts.Ports, U64), Claimed(Str)]
	cmos_read = |ports| {
		i = ports.cmos_index
		if i == 11 {
			Read(ports, 0x02)
		} else if i == 12 {
			Read(ports, 0)
		} else if i == 13 {
			Read(ports, 0x80)
		} else if i <= 10 and i != 1 and i != 3 and i != 5 {
			Claimed("the CMOS clock (the host's local time)")
		} else {
			Read(ports, 0)
		}
	}

	# ---- the PIT ----------------------------------------------------------

	channel : MachinePorts.Ports, U64 -> MachinePorts.Channel
	channel = |ports, ch| List.get(ports.pit, ch) ?? crash("machine: the PIT has no channel ${U64.to_str(ch)}")

	set_channel : MachinePorts.Ports, U64, MachinePorts.Channel -> MachinePorts.Ports
	set_channel = |ports, ch, c| { ..ports, pit: List.set(ports.pit, ch, c) ?? crash("machine: the PIT has no channel ${U64.to_str(ch)}") }

	# A reload of 0 is 65536.
	divisor : MachinePorts.Channel -> U64
	divisor = |c| if c.reload == 0 { 65536 } else { c.reload }

	# Where a channel's count stands: down from the reload value, by two in
	# mode 3, the square wave, and by one in every other mode.
	count : MachinePorts.Channel, U64 -> U64
	count = |c, clock| {
		div = MachinePorts.divisor(c)
		elapsed = U64.div_trunc_by(clock, 12)
		if c.mode == 3 {
			half = U64.div_trunc_by(div, 2)
			if half == 0 { 0 } else { div - 2 * U64.rem_by(elapsed, half) }
		} else {
			div - U64.rem_by(elapsed, div)
		}
	}

	# 0x43 sets a channel's access and mode, or with an access field of 0
	# latches its count so both halves are read from one instant. 0x40..0x42
	# load the reload value: low then high byte under access 3, the high byte
	# under 2, the low byte otherwise.
	pit_write : MachinePorts.Ports, U64, U64, U64 -> MachinePorts.Ports
	pit_write = |ports, clock, p, val|
		if p == 0x43 {
			ch = U64.bitwise_and(U64.shr_zf_wrap(val, 6), 3)
			access = U64.bitwise_and(U64.shr_zf_wrap(val, 4), 3)
			if ch >= 3 {
				ports
			} else {
				c = MachinePorts.channel(ports, ch)
				if access == 0 {
					MachinePorts.set_channel(ports, ch, { ..c, latched: U64.bitwise_and(MachinePorts.count(c, clock), 0xFFFF), latch_valid: True, read_hi: False })
				} else {
					MachinePorts.set_channel(ports, ch, { ..c, access: access, mode: U64.bitwise_and(U64.shr_zf_wrap(val, 1), 7), latch_valid: False, load_hi: False, read_hi: False })
				}
			}
		} else {
			ch = p - 0x40
			c = MachinePorts.channel(ports, ch)
			low = U64.bitwise_and(c.reload, 0xFF00)
			high = U64.bitwise_and(c.reload, 0x00FF)
			next =
				if c.access == 3 {
					if c.load_hi { { ..c, reload: U64.bitwise_or(high, U64.shl_wrap(val, 8)), load_hi: False } } else { { ..c, reload: U64.bitwise_or(low, val), load_hi: True } }
				} else if c.access == 2 {
					{ ..c, reload: U64.bitwise_or(high, U64.shl_wrap(val, 8)) }
				} else {
					{ ..c, reload: U64.bitwise_or(low, val) }
				}
			MachinePorts.set_channel(ports, ch, next)
		}

	# 0x43 reads 0. A channel answers its latched count until both halves have
	# been read, then the live count: low then high byte under access 3.
	pit_read : MachinePorts.Ports, U64, U64 -> (MachinePorts.Ports, U64)
	pit_read = |ports, clock, p|
		if p == 0x43 {
			(ports, 0)
		} else {
			ch = p - 0x40
			c = MachinePorts.channel(ports, ch)
			n = if c.latch_valid { c.latched } else { MachinePorts.count(c, clock) }
			low = U64.bitwise_and(n, 0xFF)
			high = U64.bitwise_and(U64.shr_zf_wrap(n, 8), 0xFF)
			if c.access == 3 {
				if c.read_hi {
					(MachinePorts.set_channel(ports, ch, { ..c, read_hi: False, latch_valid: False }), high)
				} else {
					(MachinePorts.set_channel(ports, ch, { ..c, read_hi: True }), low)
				}
			} else if c.access == 2 {
				(MachinePorts.set_channel(ports, ch, { ..c, latch_valid: False }), high)
			} else {
				(MachinePorts.set_channel(ports, ch, { ..c, latch_valid: False }), low)
			}
		}
}
