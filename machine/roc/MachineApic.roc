# MachineApic -- the local APIC and the IOAPIC as codex-vm models them for the
# boot core (tools/codex-vm.c: lapic_read_cpu, lapic_write_cpu, lapic_write,
# ioapic_read, ioapic_write).
#
# The local APIC answers its id, version and spurious-vector register, keeps
# the interrupt command register, and runs its timer. The current count falls
# from the initial count at the 100 MHz input rate over the divide
# configuration, by the machine's clock, and stops at zero: codex-vm re-arms a
# timer, and delivers its tick, only on the application processors. The IOAPIC
# keeps its select register, its id and 24 redirection entries.
#
# Neither delivers an interrupt here. `Machine` stops the run where one would
# reach the kernel, and a start-up IPI, which starts the application
# processors, stops it too: this machine has one core.

import MachineHpet

MachineApic :: [].{
	lapic_base : I64
	lapic_base = 0xFEE00000

	ioapic_base : I64
	ioapic_base = 0xFEC00000

	size : I64
	size = 0x1000

	Apic : {
		sivr : U64,
		icr_lo : U64,
		icr_hi : U64,
		lvt_timer : U64,
		init_count : U64,
		div_cfg : U64,
		# When the timer's period ends, in its 100 MHz input ticks; 0 disarmed.
		fire_at : U64,
		ioregsel : U64,
		ioapic_id : U64,
		redir : List(U64),
	}

	new : MachineApic.Apic
	new = { sivr: 0, icr_lo: 0, icr_hi: 0, lvt_timer: 0, init_count: 0, div_cfg: 0, fire_at: 0, ioregsel: 0, ioapic_id: 0, redir: List.repeat(0, 24) }

	claims_lapic : I64 -> Bool
	claims_lapic = |a| a >= MachineApic.lapic_base and a < MachineApic.lapic_base + MachineApic.size

	claims_ioapic : I64 -> Bool
	claims_ioapic = |a| a >= MachineApic.ioapic_base and a < MachineApic.ioapic_base + MachineApic.size

	# ---- the local APIC ---------------------------------------------------

	lapic_read : MachineApic.Apic, U64, U64 -> U64
	lapic_read = |apic, clock, off|
		if off == 0x20 {
			# The boot core's id, 0.
			0
		} else if off == 0x30 {
			0x00050014
		} else if off == 0xF0 {
			apic.sivr
		} else if off == 0x300 {
			apic.icr_lo
		} else if off == 0x310 {
			apic.icr_hi
		} else if off == 0x320 {
			apic.lvt_timer
		} else if off == 0x380 {
			apic.init_count
		} else if off == 0x390 {
			MachineApic.current_count(apic, clock)
		} else if off == 0x3E0 {
			apic.div_cfg
		} else {
			0
		}

	# Writing the initial count arms the timer for one period from now, and a
	# count of zero disarms it. An interrupt command with delivery mode 6 to
	# all but self is the start-up IPI.
	lapic_write : MachineApic.Apic, U64, U64, U64 -> [Wrote(MachineApic.Apic), StartsCores]
	lapic_write = |apic, clock, off, val|
		if off == 0x320 {
			Wrote({ ..apic, lvt_timer: val })
		} else if off == 0x3E0 {
			Wrote({ ..apic, div_cfg: val })
		} else if off == 0x380 {
			counted = { ..apic, init_count: val }
			Wrote({ ..counted, fire_at: if val == 0 { 0 } else { MachineApic.input_ticks(clock) + MachineApic.period(counted) } })
		} else if off == 0xF0 {
			Wrote({ ..apic, sivr: val })
		} else if off == 0x310 {
			Wrote({ ..apic, icr_hi: val })
		} else if off == 0x300 {
			deliver = U64.bitwise_and(U64.shr_zf_wrap(val, 8), 7)
			dest = U64.bitwise_and(U64.shr_zf_wrap(val, 18), 3)
			if deliver == 6 and dest == 3 { StartsCores } else { Wrote({ ..apic, icr_lo: val }) }
		} else {
			Wrote(apic)
		}

	# The machine's clock in the timer's 100 MHz input ticks.
	input_ticks : U64 -> U64
	input_ticks = |clock| U64.div_trunc_by(clock * 100000000, MachineHpet.hz)

	# A period is the initial count times the divisor, in input ticks, held
	# between 1 ms and 5 s.
	period : MachineApic.Apic -> U64
	period = |apic| {
		raw = apic.init_count * MachineApic.divisor(apic.div_cfg)
		if raw < 100000 { 100000 } else if raw > 500000000 { 500000000 } else { raw }
	}

	divisor : U64 -> U64
	divisor = |dcr| {
		i = U64.bitwise_and(U64.bitwise_or(U64.shr_zf_wrap(U64.bitwise_and(dcr, 8), 1), U64.bitwise_and(dcr, 3)), 7)
		List.get([2, 4, 8, 16, 32, 64, 128, 1], i) ?? 1
	}

	# The count falls in step with what remains of the period, and stays at 0
	# once it has run out.
	current_count : MachineApic.Apic, U64 -> U64
	current_count = |apic, clock|
		if apic.init_count == 0 {
			0
		} else {
			now = MachineApic.input_ticks(clock)
			whole = MachineApic.period(apic)
			left = if apic.fire_at > now { apic.fire_at - now } else { 0 }
			U64.div_trunc_by(apic.init_count * (if left > whole { whole } else { left }), whole)
		}

	# ---- the IOAPIC -------------------------------------------------------

	ioapic_read : MachineApic.Apic, U64 -> U64
	ioapic_read = |apic, off|
		if off == 0x00 {
			apic.ioregsel
		} else if off == 0x10 {
			sel = apic.ioregsel
			if sel == 0 {
				apic.ioapic_id
			} else if sel == 1 {
				# 24 entries, version 0x20.
				0x170020
			} else if sel >= 0x10 and sel < 0x40 {
				entry = List.get(apic.redir, U64.div_trunc_by(sel - 0x10, 2)) ?? 0
				if U64.rem_by(sel - 0x10, 2) == 1 { U64.shr_zf_wrap(entry, 32) } else { U64.bitwise_and(entry, 0xFFFFFFFF) }
			} else {
				0
			}
		} else {
			0
		}

	ioapic_write : MachineApic.Apic, U64, U64 -> MachineApic.Apic
	ioapic_write = |apic, off, val|
		if off == 0x00 {
			{ ..apic, ioregsel: val }
		} else if off == 0x10 {
			sel = apic.ioregsel
			if sel == 0 {
				{ ..apic, ioapic_id: U64.bitwise_and(val, 0x0F000000) }
			} else if sel >= 0x10 and sel < 0x40 {
				i = U64.div_trunc_by(sel - 0x10, 2)
				entry = List.get(apic.redir, i) ?? 0
				updated = if U64.rem_by(sel - 0x10, 2) == 1 { U64.bitwise_or(U64.bitwise_and(entry, 0xFFFFFFFF), U64.shl_wrap(val, 32)) } else { U64.bitwise_or(U64.bitwise_and(entry, 0xFFFFFFFF00000000), val) }
				{ ..apic, redir: List.set(apic.redir, i, updated) ?? crash("machine: the IOAPIC has no entry ${U64.to_str(i)}") }
			} else {
				apic
			}
		} else {
			apic
		}

	# Where an interrupt raised on an IOAPIC line goes: nowhere when its entry is
	# masked or names a vector below 32, as codex-vm's ioapic_raise drops it.
	delivers : MachineApic.Apic, U64 -> [Nowhere, Vector(U64)]
	delivers = |apic, line| {
		entry = List.get(apic.redir, line) ?? 0x10000
		vector = U64.bitwise_and(entry, 0xFF)
		if U64.bitwise_and(entry, 0x10000) != 0 or vector < 32 { Nowhere } else { Vector(vector) }
	}
}
