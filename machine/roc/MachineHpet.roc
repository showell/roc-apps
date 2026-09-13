# MachineHpet -- the High Precision Event Timer as codex-vm models it
# (tools/codex-vm.c, hpet_read and hpet_write): a register window at 0xFED00000
# whose 64-bit main counter, read in halves at F0 and F4, runs at 14,318,180 Hz
# while bit 0 of the configuration is set and holds its count while it is clear.
# Timer 0's registers read back what was written; nothing here raises its
# interrupt.
#
# codex-vm's counter follows the host's clock, which is why every verdict about
# time is a band. This one follows the machine's clock, in counter ticks, which
# `Machine` moves as the program touches device registers (`access_cost`).
#
# -no-hpet reads every register as zero and drops every write; -hpet-frozen
# reads all ones.

MachineHpet :: [].{
	base : I64
	base = 0xFED00000

	size : I64
	size = 0x1000

	hz : U64
	hz = 14318180

	Hpet : {
		absent : Bool,
		all_ones : Bool,
		config : U64,
		int_status : U64,
		t0_config : U64,
		t0_comparator : U64,
		# The count banked at the last stop, and the clock at the last start.
		banked : U64,
		epoch : U64,
	}

	new : MachineHpet.Hpet
	new = { absent: False, all_ones: False, config: 0, int_status: 0, t0_config: 0, t0_comparator: 0, banked: 0, epoch: 0 }

	flag : MachineHpet.Hpet, Str -> [Took(MachineHpet.Hpet), NotMine]
	flag = |h, a|
		if a == "-no-hpet" {
			Took({ ..h, absent: True })
		} else if a == "-hpet-frozen" {
			Took({ ..h, all_ones: True })
		} else {
			NotMine
		}

	claims : I64 -> Bool
	claims = |a| a >= MachineHpet.base and a < MachineHpet.base + MachineHpet.size

	# The main counter when the machine's clock reads `clock`.
	count : MachineHpet.Hpet, U64 -> U64
	count = |h, clock| if U64.bitwise_and(h.config, 1) == 0 { h.banked } else { h.banked + (clock - h.epoch) }

	# A 32-bit read `off` bytes into the window, when the clock reads `clock`.
	read : MachineHpet.Hpet, U64, U64 -> U64
	read = |h, clock, off|
		if h.absent {
			0
		} else if h.all_ones {
			0xFFFFFFFF
		} else if off == 0x00 {
			# GCAP_ID: revision 1, one timer, 64-bit, vendor Intel.
			0x8086A201
		} else if off == 0x04 {
			# The tick period, 69,841,279 femtoseconds.
			0x0429B17F
		} else if off == 0x10 {
			h.config
		} else if off == 0x20 {
			h.int_status
		} else if off == 0xF0 {
			MachineHpet.low(MachineHpet.count(h, clock))
		} else if off == 0xF4 {
			MachineHpet.high(MachineHpet.count(h, clock))
		} else if off == 0x100 {
			MachineHpet.low(h.t0_config)
		} else if off == 0x104 {
			MachineHpet.high(h.t0_config)
		} else if off == 0x108 {
			MachineHpet.low(h.t0_comparator)
		} else if off == 0x10C {
			MachineHpet.high(h.t0_comparator)
		} else {
			0
		}

	# A 32-bit write. Clearing the enable bit banks the count, and setting it
	# starts the count again from there.
	write : MachineHpet.Hpet, U64, U64, U64 -> MachineHpet.Hpet
	write = |h, clock, off, val|
		if h.absent or h.all_ones {
			h
		} else if off == 0x10 {
			was = U64.bitwise_and(h.config, 1) != 0
			on = U64.bitwise_and(val, 1) != 0
			if was and !on {
				{ ..h, config: val, banked: h.banked + (clock - h.epoch) }
			} else if on and !was {
				{ ..h, config: val, epoch: clock }
			} else {
				{ ..h, config: val }
			}
		} else if off == 0x20 {
			# Write one to clear.
			{ ..h, int_status: U64.bitwise_and(h.int_status, U64.bitwise_xor(val, 0xFFFFFFFF)) }
		} else if off == 0x100 {
			{ ..h, t0_config: MachineHpet.with_low(h.t0_config, val) }
		} else if off == 0x104 {
			{ ..h, t0_config: MachineHpet.with_high(h.t0_config, val) }
		} else if off == 0x108 {
			{ ..h, t0_comparator: MachineHpet.with_low(h.t0_comparator, val) }
		} else if off == 0x10C {
			{ ..h, t0_comparator: MachineHpet.with_high(h.t0_comparator, val) }
		} else {
			h
		}

	low : U64 -> U64
	low = |v| U64.bitwise_and(v, 0xFFFFFFFF)

	high : U64 -> U64
	high = |v| U64.shr_zf_wrap(v, 32)

	with_low : U64, U64 -> U64
	with_low = |v, lo| U64.bitwise_or(U64.shl_wrap(MachineHpet.high(v), 32), lo)

	with_high : U64, U64 -> U64
	with_high = |v, hi| U64.bitwise_or(U64.shl_wrap(hi, 32), MachineHpet.low(v))
}
