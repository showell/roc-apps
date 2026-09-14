# The NE2000 as codex-vm models it (tools/codex-vm.c, ne2k_handle_out,
# ne2k_handle_in and ne2k_inject_rx) at ports 0x300-0x31F: the command
# register's page select, the page 0 and page 1 registers, 32 KB of card
# memory reached by remote DMA through the data port at 0x310, and the
# receive ring between PSTART and PSTOP. Reading or writing 0x31F resets the
# card, whose PROM holds the station address with each byte doubled.
#
# Writing TXP to the command register hands the frame between TPSR and TBCR
# to the NAT. A transmit, and a write to BNRY, lay whatever the NAT queued
# into the ring, each frame behind the card's 4-byte header (status, next
# page, length), for as long as the ring has room.

MachineNe2k :: [].{
	Card : {
		mem : List(U8),
		isr : U64,
		imr : U64,
		dcr : U64,
		tcr : U64,
		rcr : U64,
		tpsr : U64,
		tbcr : U64,
		pstart : U64,
		pstop : U64,
		bnry : U64,
		curr : U64,
		rsar : U64,
		rbcr : U64,
		par : List(U8),
		mar : List(U8),
		page : U64,
		started : Bool,
	}

	# What a write asks of the machine: nothing more, a frame for the NAT, or
	# the queued frames laid into the ring.
	Effect : [Nothing, Transmit(List(U8)), Inject]

	mem_size : U64
	mem_size = 32768

	station : List(U8)
	station = [0x52, 0x54, 0x00, 0x12, 0x34, 0x56]

	reset : MachineNe2k.Card
	reset = {
		mem: MachineNe2k.prom(0, List.repeat(0.U8, 32768)),
		isr: 0x80,
		imr: 0,
		dcr: 0,
		tcr: 0,
		rcr: 0,
		tpsr: 0,
		tbcr: 0,
		pstart: 0,
		pstop: 0,
		bnry: 0,
		curr: 0,
		rsar: 0,
		rbcr: 0,
		par: MachineNe2k.station,
		mar: List.repeat(0.U8, 8),
		page: 0,
		started: False,
	}

	prom : U64, List(U8) -> List(U8)
	prom = |i, mem|
		if i >= 32 {
			mem
		} else if i < 12 {
			MachineNe2k.prom(i + 1, List.set(mem, i, List.get(MachineNe2k.station, U64.div_trunc_by(i, 2)) ?? 0) ?? crash("MachineNe2k: the PROM is outside card memory"))
		} else {
			MachineNe2k.prom(i + 1, List.set(mem, i, 0xFF) ?? crash("MachineNe2k: the PROM is outside card memory"))
		}

	# The card as x86's boot leaves it (X86_64Boot's emit-nic-init): probed,
	# the ring at pages 70 to 128, the station address read out of the PROM by
	# remote DMA, CURR at the ring's start, and started. With it, the six
	# address bytes the boot copied out.
	booted : (MachineNe2k.Card, List(U8))
	booted = {
		probed = MachineNe2k.writes(MachineNe2k.reset, [(0x07, 0xFF), (0x00, 0x21), (0x0E, 0x49), (0x0A, 0), (0x0B, 0), (0x0C, 4), (0x0D, 2), (0x01, 70), (0x02, 128), (0x03, 70), (0x0F, 0), (0x08, 0), (0x09, 0), (0x0A, 32), (0x0B, 0), (0x00, 0x0A)])
		(read_out, address) = MachineNe2k.read_station(probed, 0, [])
		(MachineNe2k.writes(read_out, [(0x07, 0x40), (0x00, 0x61), (0x07, 70), (0x00, 0x22), (0x0D, 0)]), address)
	}

	writes : MachineNe2k.Card, List((U64, U64)) -> MachineNe2k.Card
	writes = |c, ops| MachineNe2k.writes_from(c, ops, 0)

	writes_from : MachineNe2k.Card, List((U64, U64)), U64 -> MachineNe2k.Card
	writes_from = |c, ops, i|
		match List.get(ops, i) {
			Err(_) => c
			Ok(op) => {
				(off, v) = op
				(next, _) = MachineNe2k.write(c, off, v, 1)
				MachineNe2k.writes_from(next, ops, i + 1)
			}
		}

	read_station : MachineNe2k.Card, U64, List(U8) -> (MachineNe2k.Card, List(U8))
	read_station = |c, i, acc|
		if i >= 6 {
			(c, acc)
		} else {
			(next, w) = MachineNe2k.read(c, 0x10, 2)
			MachineNe2k.read_station(next, i + 1, List.append(acc, U64.to_u8_wrap(w)))
		}

	# A byte (`size` 1) or a word (2) written at `off` from 0x300.
	write : MachineNe2k.Card, U64, U64, U64 -> (MachineNe2k.Card, MachineNe2k.Effect)
	write = |c, off, val, size| {
		v = U64.bitwise_and(val, 0xFF)
		if off == 0x1F {
			(MachineNe2k.reset, Nothing)
		} else if off == 0x10 {
			(MachineNe2k.dma_write(c, val, size), Nothing)
		} else if off == 0 {
			next = { ..c, page: U64.bitwise_and(U64.div_trunc_by(val, 64), 3), started: U64.bitwise_and(val, 2) != 0 }
			if U64.bitwise_and(val, 4) == 0 {
				(next, Nothing)
			} else {
				at = c.tpsr * 256
				frame = if at + c.tbcr <= MachineNe2k.mem_size and c.tbcr > 0 { List.sublist(c.mem, { start: at, len: c.tbcr }) } else { [] }
				({ ..next, isr: U64.bitwise_or(next.isr, 0x02) }, Transmit(frame))
			}
		} else if c.page == 0 {
			if off == 0x01 {
				({ ..c, pstart: v }, Nothing)
			} else if off == 0x02 {
				({ ..c, pstop: v }, Nothing)
			} else if off == 0x03 {
				({ ..c, bnry: v }, Inject)
			} else if off == 0x04 {
				({ ..c, tpsr: v }, Nothing)
			} else if off == 0x05 {
				({ ..c, tbcr: U64.bitwise_and(c.tbcr, 0xFF00) + v }, Nothing)
			} else if off == 0x06 {
				({ ..c, tbcr: U64.bitwise_and(c.tbcr, 0xFF) + v * 256 }, Nothing)
			} else if off == 0x07 {
				({ ..c, isr: U64.bitwise_and(c.isr, U64.bitwise_xor(v, 0xFF)) }, Nothing)
			} else if off == 0x08 {
				({ ..c, rsar: U64.bitwise_and(c.rsar, 0xFF00) + v }, Nothing)
			} else if off == 0x09 {
				({ ..c, rsar: U64.bitwise_and(c.rsar, 0xFF) + v * 256 }, Nothing)
			} else if off == 0x0A {
				({ ..c, rbcr: U64.bitwise_and(c.rbcr, 0xFF00) + v }, Nothing)
			} else if off == 0x0B {
				({ ..c, rbcr: U64.bitwise_and(c.rbcr, 0xFF) + v * 256 }, Nothing)
			} else if off == 0x0C {
				({ ..c, rcr: v }, Nothing)
			} else if off == 0x0D {
				({ ..c, tcr: v }, Nothing)
			} else if off == 0x0E {
				({ ..c, dcr: v }, Nothing)
			} else if off == 0x0F {
				({ ..c, imr: v }, Nothing)
			} else {
				(c, Nothing)
			}
		} else if c.page == 1 {
			if off >= 1 and off <= 6 {
				({ ..c, par: List.set(c.par, off - 1, U64.to_u8_wrap(v)) ?? crash("MachineNe2k: no such PAR register") }, Nothing)
			} else if off == 7 {
				({ ..c, curr: v }, Nothing)
			} else if off >= 8 and off <= 15 {
				({ ..c, mar: List.set(c.mar, off - 8, U64.to_u8_wrap(v)) ?? crash("MachineNe2k: no such MAR register") }, Nothing)
			} else {
				(c, Nothing)
			}
		} else {
			(c, Nothing)
		}
	}

	# A byte or a word read at `off` from 0x300.
	read : MachineNe2k.Card, U64, U64 -> (MachineNe2k.Card, U64)
	read = |c, off, size|
		if off == 0x1F {
			(MachineNe2k.reset, 0x80)
		} else if off == 0x10 {
			MachineNe2k.dma_read(c, size)
		} else if off == 0 {
			(c, c.page * 64 + (if c.started { 2 } else { 0 }))
		} else if c.page == 0 {
			(c, if off == 0x03 { c.bnry } else if off == 0x04 { 1 } else if off == 0x07 { c.isr } else { 0 })
		} else if c.page == 1 {
			(c, if off >= 1 and off <= 6 { MachineNe2k.byte(c.par, off - 1) } else if off == 7 { c.curr } else if off >= 8 and off <= 15 { MachineNe2k.byte(c.mar, off - 8) } else { 0 })
		} else {
			(c, 0)
		}

	byte : List(U8), U64 -> U64
	byte = |bytes, i| U8.to_u64(List.get(bytes, i) ?? 0)

	# Remote DMA into card memory: a byte, and for a word its high byte, while
	# the count lasts; the count running out raises RDC.
	dma_write : MachineNe2k.Card, U64, U64 -> MachineNe2k.Card
	dma_write = |c, val, size| {
		one = MachineNe2k.dma_put(c, U64.bitwise_and(val, 0xFF))
		two = if size >= 2 { MachineNe2k.dma_put(one, U64.bitwise_and(U64.div_trunc_by(val, 256), 0xFF)) } else { one }
		if two.rbcr == 0 { ({ ..two, isr: U64.bitwise_or(two.isr, 0x40) }) } else { two }
	}

	dma_put : MachineNe2k.Card, U64 -> MachineNe2k.Card
	dma_put = |c, b|
		if c.rbcr > 0 and c.rsar < MachineNe2k.mem_size {
			({ ..c, mem: List.set(c.mem, c.rsar, U64.to_u8_wrap(b)) ?? crash("MachineNe2k: remote DMA outside card memory"), rsar: c.rsar + 1, rbcr: c.rbcr - 1 })
		} else {
			c
		}

	# Remote DMA out of card memory, wrapping at the ring's end.
	dma_read : MachineNe2k.Card, U64 -> (MachineNe2k.Card, U64)
	dma_read = |c, size| {
		(one, lo, took) = MachineNe2k.dma_take(c)
		(two, hi, _) = if took and size >= 2 { MachineNe2k.dma_take(one) } else { (one, 0, False) }
		done = if two.rbcr == 0 { ({ ..two, isr: U64.bitwise_or(two.isr, 0x40) }) } else { two }
		(done, lo + hi * 256)
	}

	dma_take : MachineNe2k.Card -> (MachineNe2k.Card, U64, Bool)
	dma_take = |c|
		if c.rbcr > 0 and c.rsar < MachineNe2k.mem_size {
			b = MachineNe2k.byte(c.mem, c.rsar)
			at = c.rsar + 1
			wrapped = if at >= c.pstop * 256 and c.pstop > c.pstart { c.pstart * 256 } else { at }
			({ ..c, rsar: wrapped, rbcr: c.rbcr - 1 }, b, True)
		} else {
			(c, 0, False)
		}

	# Lay queued frames into the receive ring until one does not fit, and
	# answer the ones left. An odd frame is padded to even, since the guest
	# reads it back a word at a time.
	inject : MachineNe2k.Card, List(List(U8)) -> (MachineNe2k.Card, List(List(U8)))
	inject = |c, queue| {
		(card, laid) = MachineNe2k.inject_from(c, queue, 0)
		(card, List.sublist(queue, { start: laid, len: List.len(queue) - laid }))
	}

	# The card with frames `i` onward laid in, and how many were.
	inject_from : MachineNe2k.Card, List(List(U8)), U64 -> (MachineNe2k.Card, U64)
	inject_from = |c, queue, i|
		match List.get(queue, i) {
			Err(_) => (c, i)
			Ok(frame) => {
				len = List.len(frame)
				total = len + U64.bitwise_and(len, 1) + 4
				pages = U64.div_trunc_by(total + 255, 256)
				ring = U64.to_i64_wrap(c.pstop) - U64.to_i64_wrap(c.pstart)
				used = if ring <= 0 { 0 } else { I64.rem_by(U64.to_i64_wrap(c.curr) - U64.to_i64_wrap(c.bnry) + ring, ring) }
				if ring <= 0 or U64.to_i64_wrap(pages) > ring - used - 1 {
					(c, i)
				} else {
					after = c.curr + pages
					next = if after >= c.pstop { c.pstart + (after - c.pstop) } else { after }
					header = [0x01, U64.to_u8_wrap(next), U64.to_u8_wrap(total), U64.to_u8_wrap(U64.div_trunc_by(total, 256))]
					bytes = List.concat(List.concat(header, frame), List.repeat(0.U8, total - 4 - len))
					at = c.curr * 256
					first = if c.pstop * 256 > at { c.pstop * 256 - at } else { 0 }
					laid = MachineNe2k.lay(c.mem, bytes, 0, at, first, c.pstart * 256)
					MachineNe2k.inject_from({ ..c, mem: laid, curr: U64.bitwise_and(next, 0xFF), isr: U64.bitwise_or(c.isr, 0x01) }, queue, i + 1)
				}
			}
		}

	lay : List(U8), List(U8), U64, U64, U64, U64 -> List(U8)
	lay = |mem, bytes, i, at, first, start|
		match List.get(bytes, i) {
			Err(_) => mem
			Ok(b) => {
				to = if i < first { at + i } else { start + (i - first) }
				MachineNe2k.lay(List.set(mem, to, b) ?? crash("MachineNe2k: a received frame outside card memory"), bytes, i + 1, at, first, start)
			}
		}
}
