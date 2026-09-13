# MachineE1000 -- Intel gigabit Ethernet as codex-vm models it for upstream's
# tests (tools/codex-vm.c: e1000_read, e1000_write, e1000_mdic_exec and the
# receive and transmit walks): the 8254x register window at 0xFE400000, a PHY
# reached through MDIC, under -i219 the I219's K1, ULP and MDIO-semaphore
# registers, rings the device walks in the machine's memory, and the fault
# flags that make the model refuse. codex-vm keeps the reason for every flag
# beside its declaration; this module follows what the flags do.
#
# The frames the device transmits are not summed or kept, since only the host
# ever read them. -e1000-nat and -e1000-strict-filter need the host's network
# stack and are not modelled, so a unit that passes one stops at the flag.

import MachineHpet
import MachineMem

MachineE1000 :: [].{
	bar : I64
	bar = 0xFE400000

	bar_size : I64
	bar_size = 0x20000

	E1000 : {
		present : Bool,
		i219 : Bool,
		faults : MachineE1000.Faults,
		# The register file, by word.
		regs : Dict(U64, U64),
		# The PHY's 32 IEEE registers, the page register 31 selects, and the
		# paged registers the model answers: 769.16, 770.17 (K1) and 779.16
		# (ULP configuration 1).
		phy : List(U64),
		page : U64,
		custom_mode : U64,
		k1 : U64,
		ulp : U64,
		# EXTCNF_CTRL under -i219: the semaphore's three ownership bits.
		extcnf : U64,
		extcnf_writes : U64,
		violated : Bool,
		# A ring register written under a live receiver.
		poisoned : Bool,
		reset_at : [NotReset, ResetAt(U64)],
		rx_cursor : U64,
		injected : U64,
		gprc_reads : U64,
	}

	Faults : {
		no_reset : Bool,
		no_link : Bool,
		no_mac : Bool,
		no_tx_dd : Bool,
		rdh_ro : Bool,
		no_phy : Bool,
		phy_err : Bool,
		phy_link : Bool,
		mdio_window : Bool,
		mdio_slow : Bool,
		ctrl_ro : Bool,
		asde : Bool,
		bme_clear : Bool,
		k1_nvm : Bool,
		swflag : Bool,
		mng_holds : Bool,
		extcnf_strict : Bool,
		mng_release_after : U64,
		inject_want : U64,
		inject_armed : Bool,
	}

	new : MachineE1000.E1000
	new = {
		present: False,
		i219: False,
		faults: {
			no_reset: False,
			no_link: False,
			no_mac: False,
			no_tx_dd: False,
			rdh_ro: False,
			no_phy: False,
			phy_err: False,
			phy_link: False,
			mdio_window: False,
			mdio_slow: False,
			ctrl_ro: False,
			asde: False,
			bme_clear: False,
			k1_nvm: True,
			swflag: False,
			mng_holds: False,
			extcnf_strict: False,
			mng_release_after: 0,
			inject_want: 0,
			inject_armed: False,
		},
		regs: Dict.empty(),
		phy: List.repeat(0, 32),
		page: 0,
		custom_mode: MachineE1000.custom_mode_reset,
		k1: 0,
		ulp: 0x0800,
		extcnf: 0,
		extcnf_writes: 0,
		violated: False,
		poisoned: False,
		reset_at: NotReset,
		rx_cursor: 0,
		injected: 0,
		gprc_reads: 0,
	}

	# ---- codex-vm's flags ------------------------------------------------
	#
	# Each flag puts the device on the bus; the -i219 family makes it the I219.
	# The answer says how many arguments the flag took.

	flag : MachineE1000.E1000, Str, Str -> [Took(MachineE1000.E1000, U64), NotMine]
	flag = |e, a, next| {
		on = { ..e, present: True }
		f = on.faults
		pch = { ..on, i219: True }
		if a == "-e1000" {
			Took(on, 1)
		} else if a == "-e1000-inject" {
			Took({ ..on, faults: { ..f, inject_want: MachineE1000.number(a, next) } }, 2)
		} else if a == "-e1000-inject-armed" {
			Took({ ..on, faults: { ..f, inject_armed: True } }, 1)
		} else if a == "-e1000-no-reset" {
			Took({ ..on, faults: { ..f, no_reset: True } }, 1)
		} else if a == "-e1000-no-link" {
			Took({ ..on, faults: { ..f, no_link: True } }, 1)
		} else if a == "-e1000-no-mac" {
			Took({ ..on, faults: { ..f, no_mac: True } }, 1)
		} else if a == "-e1000-no-tx-dd" {
			Took({ ..on, faults: { ..f, no_tx_dd: True } }, 1)
		} else if a == "-e1000-rdh-ro" {
			Took({ ..on, faults: { ..f, rdh_ro: True } }, 1)
		} else if a == "-e1000-no-phy" {
			Took({ ..on, faults: { ..f, no_phy: True } }, 1)
		} else if a == "-e1000-phy-err" {
			Took({ ..on, faults: { ..f, phy_err: True } }, 1)
		} else if a == "-e1000-phy-link" {
			Took({ ..on, faults: { ..f, phy_link: True } }, 1)
		} else if a == "-e1000-mdio-window" {
			Took({ ..on, faults: { ..f, mdio_window: True } }, 1)
		} else if a == "-e1000-mdio-slow" {
			Took({ ..on, faults: { ..f, mdio_slow: True } }, 1)
		} else if a == "-e1000-asde" {
			Took({ ..on, faults: { ..f, asde: True } }, 1)
		} else if a == "-nic-bme-clear" {
			Took({ ..on, faults: { ..f, bme_clear: True } }, 1)
		} else if a == "-e1000-preconfigured" {
			# The receiver arrives live, over a one-descriptor ring the driver
			# did not program.
			Took(MachineE1000.put(MachineE1000.put(on, MachineE1000.reg_rctl, MachineE1000.rctl_en), MachineE1000.reg_rdlen, 16), 1)
		} else if a == "-e1000-ctrl-ro" {
			# CTRL keeps the value the ASUS firmware leaves in it.
			ro = { ..on, faults: { ..f, ctrl_ro: True } }
			Took(MachineE1000.put(ro, MachineE1000.reg_ctrl, 0x180240), 1)
		} else if a == "-i219" {
			Took(pch, 1)
		} else if a == "-i219-k1-nvm" {
			Took({ ..pch, faults: { ..f, k1_nvm: MachineE1000.number(a, next) != 0 } }, 2)
		} else if a == "-i219-swflag" {
			Took({ ..pch, faults: { ..f, swflag: True } }, 1)
		} else if a == "-i219-mng-holds" {
			Took({ ..pch, faults: { ..f, swflag: True, mng_holds: True } }, 1)
		} else if a == "-i219-extcnf-strict" {
			Took({ ..pch, faults: { ..f, swflag: True, extcnf_strict: True } }, 1)
		} else if a == "-i219-mng-release-after" {
			Took({ ..pch, faults: { ..f, swflag: True, mng_holds: True, mng_release_after: MachineE1000.number(a, next) } }, 2)
		} else if a == "-i219-ulp-armed" {
			# The board's measured 0x0800, with STICKY_ULP (bit 4) and
			# EN_ULP_LANPHYPC (bit 10) set so a driver's disable has work to do.
			Took({ ..pch, ulp: 0x0C10 }, 1)
		} else {
			NotMine
		}
	}

	number : Str, Str -> U64
	number = |a, s| U64.from_str(s) ?? crash("machine: ${a} wants a number")

	# The device as it comes up on the bus: the PHY at reset, and the MNG bit
	# firmware holds from power-up under -i219-mng-holds.
	power_on : MachineE1000.E1000 -> MachineE1000.E1000
	power_on = |e| {
		fresh = MachineE1000.phy_reset(e)
		{ ..fresh, extcnf: if e.faults.mng_holds { MachineE1000.ext_mng } else { 0 } }
	}

	# The PHY register file at reset: auto-negotiation enabled, the model's own
	# identifiers, page 0, 769.16 at its reset value, and 770.17 at the NVM's.
	phy_reset : MachineE1000.E1000 -> MachineE1000.E1000
	phy_reset = |e| {
		..e,
		phy: List.concat([0x1000, 0, 0x0154, 0x0C00], List.repeat(0, 28)),
		page: 0,
		custom_mode: MachineE1000.custom_mode_reset,
		k1: if e.faults.k1_nvm { MachineE1000.k1_enable } else { 0 },
	}

	claims : I64 -> Bool
	claims = |a| a >= MachineE1000.bar and a < MachineE1000.bar + MachineE1000.bar_size

	# ---- the register window ---------------------------------------------

	# A 32-bit read `off` bytes into the window. The four statistics counters
	# clear on read, and reading RDH delivers what the receive ring can take
	# first, so the head it answers is the device's.
	read : MachineE1000.E1000, MachineMem.Mem, U64, Bool -> (MachineE1000.E1000, MachineMem.Mem, U64)
	read = |e, mem, off, dma|
		if off + 4 > I64.to_u64_wrap(MachineE1000.bar_size) {
			(e, mem, 0)
		} else if off == MachineE1000.reg_gprc or off == MachineE1000.reg_rnbc or off == MachineE1000.reg_mpc or off == MachineE1000.reg_crcerrs {
			v = MachineE1000.get(e, off)
			cleared = MachineE1000.put(e, off, 0)
			counted = if off == MachineE1000.reg_gprc { { ..cleared, gprc_reads: cleared.gprc_reads + 1 } } else { cleared }
			(counted, mem, v)
		} else if off == MachineE1000.reg_status {
			(e, mem, MachineE1000.status(e))
		} else if off == MachineE1000.reg_extcnf and e.i219 {
			(e, mem, e.extcnf)
		} else if off == MachineE1000.reg_ral {
			# 52:54:00:AB:CD:EF
			(e, mem, if e.faults.no_mac { 0 } else { 0xAB005452 })
		} else if off == MachineE1000.reg_rah {
			# Address valid, and the last two bytes.
			(e, mem, if e.faults.no_mac { 0 } else { 0x8000EFCD })
		} else if off == MachineE1000.reg_rdh {
			(moved, mem1) = MachineE1000.deliver(e, mem, dma)
			(moved, mem1, MachineE1000.get(moved, MachineE1000.reg_rdh))
		} else {
			(e, mem, MachineE1000.get(e, off))
		}

	# STATUS: link up as `link_up` decides, and under -e1000-asde the speed
	# fields. The MAC's own speed detection resolves to 10 Mb/s, and the PHY's
	# is 1000 once auto-negotiation is done; CTRL.ASDE picks the MAC's.
	status : MachineE1000.E1000 -> U64
	status = |e| {
		v = MachineE1000.get(e, MachineE1000.reg_status)
		linked = if MachineE1000.link_up(e) { U64.bitwise_or(v, 2) } else { v }
		if e.faults.asde {
			phy_speed = if MachineE1000.any_bits(MachineE1000.phy_reg(e, 1), MachineE1000.bmsr_aneg_done) { 2 } else { 0 }
			speed = if MachineE1000.any_bits(MachineE1000.get(e, MachineE1000.reg_ctrl), MachineE1000.ctrl_asde) { 0 } else { phy_speed }
			U64.bitwise_or(MachineE1000.clear(linked, 0x3C0), U64.shl_wrap(speed, 6))
		} else {
			linked
		}
	}

	# A 32-bit write `off` bytes into the window, at clock `clock`.
	write : MachineE1000.E1000, MachineMem.Mem, U64, U64, Bool, U64 -> (MachineE1000.E1000, MachineMem.Mem)
	write = |e, mem, off, val, dma, clock|
		if off + 4 > I64.to_u64_wrap(MachineE1000.bar_size) {
			(e, mem)
		} else if off == MachineE1000.reg_ctrl {
			if e.faults.ctrl_ro {
				(e, mem)
			} else if MachineE1000.any_bits(val, MachineE1000.ctrl_rst) {
				# A reset drops the negotiated link and opens the MDIO window.
				# RST clears itself unless the device is wedged in reset.
				bmsr = MachineE1000.clear(MachineE1000.phy_reg(e, 1), U64.bitwise_or(MachineE1000.bmsr_aneg_done, MachineE1000.bmsr_link))
				reset = { ..MachineE1000.set_phy(e, 1, bmsr), reset_at: ResetAt(clock) }
				(MachineE1000.put(reset, off, if e.faults.no_reset { val } else { MachineE1000.clear(val, MachineE1000.ctrl_rst) }), mem)
			} else {
				(MachineE1000.put(e, off, val), mem)
			}
		} else if off == MachineE1000.reg_rctl {
			# Disabling the receiver is the quiesce that clears a poisoned ring.
			live = MachineE1000.any_bits(val, MachineE1000.rctl_en)
			quiet = if live { e } else { { ..e, poisoned: False } }
			stored = MachineE1000.put(quiet, off, val)
			if live { MachineE1000.deliver(stored, mem, dma) } else { (stored, mem) }
		} else if off == MachineE1000.reg_rdbal or off == MachineE1000.reg_rdbah or off == MachineE1000.reg_rdlen {
			live = MachineE1000.any_bits(MachineE1000.get(e, MachineE1000.reg_rctl), MachineE1000.rctl_en)
			stored = MachineE1000.put(e, off, val)
			({ ..stored, poisoned: stored.poisoned or live, rx_cursor: 0 }, mem)
		} else if off == MachineE1000.reg_rdh {
			if e.faults.rdh_ro {
				(e, mem)
			} else {
				slots = U64.div_trunc_by(MachineE1000.get(e, MachineE1000.reg_rdlen), 16)
				stored = MachineE1000.put(e, off, val)
				({ ..stored, rx_cursor: if slots == 0 { 0 } else { U64.rem_by(val, slots) } }, mem)
			}
		} else if off == MachineE1000.reg_rdt {
			MachineE1000.deliver(MachineE1000.put(e, off, val), mem, dma)
		} else if off == MachineE1000.reg_tdt {
			MachineE1000.transmit(MachineE1000.put(e, off, val), mem, val, dma)
		} else if off == MachineE1000.reg_mdic {
			(done, answer) = MachineE1000.mdic(e, val, clock)
			(MachineE1000.put(done, off, answer), mem)
		} else if off == MachineE1000.reg_extcnf and e.i219 {
			(MachineE1000.extcnf_write(e, val), mem)
		} else if off == MachineE1000.reg_icr {
			(MachineE1000.put(e, off, 0), mem)
		} else {
			(MachineE1000.put(e, off, val), mem)
		}

	# ---- the link --------------------------------------------------------

	# STATUS.LU: CTRL.SLU, and under -e1000-phy-link auto-negotiation done too.
	link_up : MachineE1000.E1000 -> Bool
	link_up = |e|
		if e.faults.no_link or !MachineE1000.any_bits(MachineE1000.get(e, MachineE1000.reg_ctrl), MachineE1000.ctrl_slu) {
			False
		} else {
			!e.faults.phy_link or MachineE1000.any_bits(MachineE1000.phy_reg(e, 1), MachineE1000.bmsr_aneg_done)
		}

	# The I219's MAC stalls with the link up while K1 is enabled and not
	# disabled for gigabit.
	stalled : MachineE1000.E1000 -> Bool
	stalled = |e|
		e.i219 and MachineE1000.link_up(e) and !MachineE1000.any_bits(e.k1, MachineE1000.k1_giga_disable) and MachineE1000.any_bits(e.k1, MachineE1000.k1_enable)

	# ---- receive and transmit --------------------------------------------

	# The -e1000-inject frames, placed into the receive ring the way the silicon
	# would. A poisoned ring, a stalled MAC or a device without bus mastering
	# still takes and counts them and writes back no descriptor. Delivery stops
	# at the tail, and -e1000-inject-armed holds the frames until GPRC is read.
	deliver : MachineE1000.E1000, MachineMem.Mem, Bool -> (MachineE1000.E1000, MachineMem.Mem)
	deliver = |e, mem, dma| {
		want = e.faults.inject_want
		if e.faults.inject_armed and e.gprc_reads < 1 {
			(e, mem)
		} else if e.injected >= want {
			(e, mem)
		} else if e.poisoned or MachineE1000.stalled(e) or !dma {
			counted = MachineE1000.put(e, MachineE1000.reg_gprc, MachineE1000.get(e, MachineE1000.reg_gprc) + (want - e.injected))
			({ ..counted, injected: want }, mem)
		} else {
			ring = MachineE1000.ring(e, MachineE1000.reg_rdbal, MachineE1000.reg_rdbah)
			slots = U64.div_trunc_by(MachineE1000.get(e, MachineE1000.reg_rdlen), 16)
			if ring == 0 or slots == 0 { (e, mem) } else { MachineE1000.receive(e, mem, ring, slots) }
		}
	}

	receive : MachineE1000.E1000, MachineMem.Mem, U64, U64 -> (MachineE1000.E1000, MachineMem.Mem)
	receive = |e, mem, ring, slots|
		if e.injected >= e.faults.inject_want {
			(e, mem)
		} else {
			idx = U64.rem_by(e.rx_cursor, slots)
			if idx == MachineE1000.get(e, MachineE1000.reg_rdt) {
				# Ring full.
				(MachineE1000.put(e, MachineE1000.reg_rnbc, MachineE1000.get(e, MachineE1000.reg_rnbc) + 1), mem)
			} else {
				desc = U64.to_i64_wrap(ring + idx * 16)
				buf = MachineMem.read(mem, desc, 7, 0)
				if buf == 0 {
					(e, mem)
				} else {
					filled = MachineE1000.fill(mem, U64.to_i64_wrap(buf), MachineE1000.canned, 0)
					sized = MachineMem.write(filled, desc + 8, 60, 2)
					# DD and EOP.
					done = MachineMem.write(sized, desc + 12, 3, 1)
					next = U64.rem_by(idx + 1, slots)
					moved = MachineE1000.put(MachineE1000.put(e, MachineE1000.reg_rdh, next), MachineE1000.reg_gprc, MachineE1000.get(e, MachineE1000.reg_gprc) + 1)
					MachineE1000.receive({ ..moved, rx_cursor: next, injected: e.injected + 1 }, done, ring, slots)
				}
			}
		}

	# A tail write: the device takes every descriptor from its head to the tail
	# and marks each done, unless -e1000-no-tx-dd. A stalled MAC or a device
	# without bus mastering takes none.
	transmit : MachineE1000.E1000, MachineMem.Mem, U64, Bool -> (MachineE1000.E1000, MachineMem.Mem)
	transmit = |e, mem, tail, dma|
		if MachineE1000.stalled(e) or !dma {
			(e, mem)
		} else {
			ring = MachineE1000.ring(e, MachineE1000.reg_tdbal, MachineE1000.reg_tdbah)
			slots = U64.div_trunc_by(MachineE1000.get(e, MachineE1000.reg_tdlen), 16)
			if ring == 0 or slots == 0 {
				(MachineE1000.put(e, MachineE1000.reg_tdh, tail), mem)
			} else {
				head = U64.rem_by(MachineE1000.get(e, MachineE1000.reg_tdh), slots)
				MachineE1000.send(e, mem, ring, slots, head, U64.rem_by(tail, slots))
			}
		}

	send : MachineE1000.E1000, MachineMem.Mem, U64, U64, U64, U64 -> (MachineE1000.E1000, MachineMem.Mem)
	send = |e, mem, ring, slots, head, stop|
		if head == stop {
			(MachineE1000.put(e, MachineE1000.reg_tdh, head), mem)
		} else {
			marked = if e.faults.no_tx_dd { mem } else { MachineMem.write(mem, U64.to_i64_wrap(ring + head * 16 + 12), 1, 1) }
			MachineE1000.send(e, marked, ring, slots, U64.rem_by(head + 1, slots), stop)
		}

	ring : MachineE1000.E1000, U64, U64 -> U64
	ring = |e, lo, hi| U64.bitwise_or(MachineE1000.get(e, lo), U64.shl_wrap(MachineE1000.get(e, hi), 32))

	# A broadcast frame from the station address with EtherType 0x88B5.
	canned : List(U8)
	canned = [
		0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x52, 0x54, 0x00, 0xAB, 0xCD, 0xEF, 0x88, 0xB5,
		0xC0, 0xDE, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B,
		0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,
		0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
		0x28, 0x29, 0x2A, 0x2B,
	]

	fill : MachineMem.Mem, I64, List(U8), U64 -> MachineMem.Mem
	fill = |mem, at, bytes, i|
		match List.get(bytes, i) {
			Ok(b) => MachineE1000.fill(MachineMem.write(mem, at + U64.to_i64_wrap(i), U8.to_u64(b), 1), at, bytes, i + 1)
			Err(_) => mem
		}

	# ---- the PHY, through MDIC -------------------------------------------

	# One MDIC transaction, completed at once. Refused with E when the semaphore
	# is enforced and not held, when -e1000-phy-err, or at an address other than
	# 1; answered with neither R nor E while the MDIO window is closed or under
	# -e1000-no-phy.
	mdic : MachineE1000.E1000, U64, U64 -> (MachineE1000.E1000, U64)
	mdic = |e, val, clock| {
		reg = U64.bitwise_and(U64.shr_zf_wrap(val, 16), 31)
		addr = U64.bitwise_and(U64.shr_zf_wrap(val, 21), 31)
		op = U64.bitwise_and(val, 0x0C000000)
		refused = U64.bitwise_or(MachineE1000.clear(val, MachineE1000.mdic_ready), MachineE1000.mdic_error)
		silent = MachineE1000.clear(val, U64.bitwise_or(MachineE1000.mdic_ready, MachineE1000.mdic_error))
		if e.faults.swflag and !MachineE1000.any_bits(e.extcnf, MachineE1000.ext_sw) {
			(e, refused)
		} else if !MachineE1000.window_open(e, clock) or e.faults.no_phy {
			(e, silent)
		} else if e.faults.phy_err or addr != 1 {
			(e, refused)
		} else if op == 0x04000000 {
			MachineE1000.phy_write(e, val, reg, refused)
		} else if op == 0x08000000 {
			(e, MachineE1000.phy_read(e, val, reg, refused))
		} else {
			(e, refused)
		}
	}

	# -e1000-mdio-window: closed until 10 ms after CTRL.RST, by the machine's
	# clock. A device never reset has opened no window to violate.
	window_open : MachineE1000.E1000, U64 -> Bool
	window_open = |e, clock|
		if !e.faults.mdio_window {
			True
		} else {
			match e.reset_at {
				NotReset => True
				ResetAt(t) => U64.div_trunc_by((clock - t) * 1000, MachineHpet.hz) >= 10
			}
		}

	# BMCR's reset and restart-negotiation bits clear themselves; a restart
	# completes negotiation at once unless -e1000-no-link. Register 31 selects
	# the page from the data's upper 11 bits. On a page other than 0, only the
	# paged registers the model has are there.
	phy_write : MachineE1000.E1000, U64, U64, U64 -> (MachineE1000.E1000, U64)
	phy_write = |e, val, reg, refused| {
		given = U64.bitwise_and(val, MachineE1000.mdic_data)
		resets = reg == 0 and MachineE1000.any_bits(given, 0x8000)
		after_reset = if resets { MachineE1000.phy_reset(e) } else { e }
		unreset = if resets { MachineE1000.clear(given, 0x8000) } else { given }
		restarts = reg == 0 and MachineE1000.any_bits(unreset, 0x0200)
		data = if restarts { MachineE1000.clear(unreset, 0x0200) } else { unreset }
		negotiated =
			if restarts and !after_reset.faults.no_link {
				MachineE1000.set_phy(after_reset, 1, U64.bitwise_or(MachineE1000.phy_reg(after_reset, 1), U64.bitwise_or(MachineE1000.bmsr_aneg_done, MachineE1000.bmsr_link)))
			} else {
				after_reset
			}
		answered = MachineE1000.answer(val, data)
		if reg == 31 {
			({ ..negotiated, page: U64.shr_zf_wrap(data, 5) }, answered)
		} else if reg >= 16 and negotiated.page != 0 {
			if negotiated.page == 769 and reg == 16 {
				({ ..negotiated, custom_mode: data }, answered)
			} else if negotiated.i219 and negotiated.page == 770 and reg == 17 {
				({ ..negotiated, k1: data }, answered)
			} else if negotiated.i219 and negotiated.page == 779 and reg == 16 {
				({ ..negotiated, ulp: data }, answered)
			} else {
				(negotiated, refused)
			}
		} else if reg == 1 {
			(negotiated, answered)
		} else {
			(MachineE1000.set_phy(negotiated, reg, data), answered)
		}
	}

	# Under -e1000-mdio-slow an ordinary register read is refused until 769.16
	# bit 10 is set; the page register and 769.16 are exempt.
	phy_read : MachineE1000.E1000, U64, U64, U64 -> U64
	phy_read = |e, val, reg, refused|
		if reg == 31 {
			MachineE1000.answer(val, U64.bitwise_and(U64.shl_wrap(e.page, 5), MachineE1000.mdic_data))
		} else if reg >= 16 and e.page != 0 {
			if e.page == 769 and reg == 16 {
				MachineE1000.answer(val, e.custom_mode)
			} else if e.i219 and e.page == 770 and reg == 17 {
				MachineE1000.answer(val, e.k1)
			} else if e.i219 and e.page == 779 and reg == 16 {
				MachineE1000.answer(val, e.ulp)
			} else {
				refused
			}
		} else if e.faults.mdio_slow and !MachineE1000.any_bits(e.custom_mode, 0x0400) {
			refused
		} else {
			MachineE1000.answer(val, MachineE1000.phy_reg(e, reg))
		}

	answer : U64, U64 -> U64
	answer = |val, data| U64.bitwise_or(U64.bitwise_or(MachineE1000.clear(val, MachineE1000.mdic_data), MachineE1000.mdic_ready), data)

	# EXTCNF_CTRL's semaphore: writing the SW bit takes it only while neither HW
	# nor MNG is held, and firmware's MNG bit survives any write. A write that
	# asserts MNG or HW is a violation, and under -i219-extcnf-strict one
	# violation keeps SW from ever being granted. Under -i219-mng-release-after
	# N, firmware lets go of MNG at the Nth write.
	extcnf_write : MachineE1000.E1000, U64 -> MachineE1000.E1000
	extcnf_write = |e, val| {
		writes = e.extcnf_writes + 1
		held = if e.faults.mng_release_after != 0 and writes >= e.faults.mng_release_after { MachineE1000.clear(e.extcnf, MachineE1000.ext_mng) } else { e.extcnf }
		mng = U64.bitwise_and(held, MachineE1000.ext_mng)
		violated = e.violated or (e.faults.extcnf_strict and MachineE1000.any_bits(val, U64.bitwise_or(MachineE1000.ext_mng, MachineE1000.ext_hw)))
		free = U64.bitwise_or(mng, U64.bitwise_and(held, MachineE1000.ext_hw)) == 0
		keep = if MachineE1000.any_bits(val, MachineE1000.ext_sw) and free and !(e.faults.extcnf_strict and violated) { U64.bitwise_or(mng, MachineE1000.ext_sw) } else { mng }
		owner_bits = U64.bitwise_or(MachineE1000.ext_sw, U64.bitwise_or(MachineE1000.ext_hw, MachineE1000.ext_mng))
		{ ..e, extcnf_writes: writes, violated: violated, extcnf: U64.bitwise_or(MachineE1000.clear(val, owner_bits), keep) }
	}

	# ---- the register file -----------------------------------------------

	get : MachineE1000.E1000, U64 -> U64
	get = |e, off| Dict.get(e.regs, U64.div_trunc_by(off, 4)) ?? 0

	put : MachineE1000.E1000, U64, U64 -> MachineE1000.E1000
	put = |e, off, v| { ..e, regs: Dict.insert(e.regs, U64.div_trunc_by(off, 4), v) }

	phy_reg : MachineE1000.E1000, U64 -> U64
	phy_reg = |e, r| List.get(e.phy, r) ?? 0

	set_phy : MachineE1000.E1000, U64, U64 -> MachineE1000.E1000
	set_phy = |e, r, v| { ..e, phy: List.set(e.phy, r, v) ?? crash("e1000: no PHY register ${U64.to_str(r)}") }

	any_bits : U64, U64 -> Bool
	any_bits = |v, bits| U64.bitwise_and(v, bits) != 0

	clear : U64, U64 -> U64
	clear = |v, bits| U64.bitwise_and(v, U64.bitwise_xor(bits, 0xFFFFFFFF))

	reg_ctrl : U64
	reg_ctrl = 0x0000

	reg_status : U64
	reg_status = 0x0008

	reg_mdic : U64
	reg_mdic = 0x0020

	reg_icr : U64
	reg_icr = 0x00C0

	reg_rctl : U64
	reg_rctl = 0x0100

	reg_extcnf : U64
	reg_extcnf = 0x0F00

	reg_rdbal : U64
	reg_rdbal = 0x2800

	reg_rdbah : U64
	reg_rdbah = 0x2804

	reg_rdlen : U64
	reg_rdlen = 0x2808

	reg_rdh : U64
	reg_rdh = 0x2810

	reg_rdt : U64
	reg_rdt = 0x2818

	reg_tdbal : U64
	reg_tdbal = 0x3800

	reg_tdbah : U64
	reg_tdbah = 0x3804

	reg_tdlen : U64
	reg_tdlen = 0x3808

	reg_tdh : U64
	reg_tdh = 0x3810

	reg_tdt : U64
	reg_tdt = 0x3818

	reg_crcerrs : U64
	reg_crcerrs = 0x4000

	reg_mpc : U64
	reg_mpc = 0x4010

	reg_gprc : U64
	reg_gprc = 0x4074

	reg_rnbc : U64
	reg_rnbc = 0x40A0

	reg_ral : U64
	reg_ral = 0x5400

	reg_rah : U64
	reg_rah = 0x5404

	ctrl_rst : U64
	ctrl_rst = 0x04000000

	ctrl_slu : U64
	ctrl_slu = 0x40

	ctrl_asde : U64
	ctrl_asde = 0x20

	rctl_en : U64
	rctl_en = 0x02

	mdic_data : U64
	mdic_data = 0xFFFF

	mdic_ready : U64
	mdic_ready = 0x10000000

	mdic_error : U64
	mdic_error = 0x40000000

	bmsr_aneg_done : U64
	bmsr_aneg_done = 0x20

	bmsr_link : U64
	bmsr_link = 0x04

	custom_mode_reset : U64
	custom_mode_reset = 0x2180

	k1_giga_disable : U64
	k1_giga_disable = 0x2000

	k1_enable : U64
	k1_enable = 0x4000

	ext_sw : U64
	ext_sw = 0x20

	ext_hw : U64
	ext_hw = 0x40

	ext_mng : U64
	ext_mng = 0x80
}
