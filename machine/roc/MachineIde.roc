# The IDE channel as codex-vm's model answers it (tools/codex-vm.c,
# ide_bus_out and ide_handle_in): the primary channel's two positions behind
# the task-file registers at 0x1F0-0x1F7 and the alternate status at 0x3F6.
#
# A drive/head write lands on both positions, since the register also carries
# LBA bits 27:24, and its bit 4 selects the one the following accesses reach.
# A position with no medium ignores every other write and answers 0x00 from
# the two status registers and 0xFF from the rest, which a driver's detect
# reads as no drive. A present one reads back what was written.
#
# READ SECTORS (0x20) and WRITE SECTORS (0x30) move whole sectors of the image
# through the data register a 16-bit word at a time, loading and storing each
# through MachineDisk's doors; IDENTIFY DEVICE (0xEC) answers one sector
# naming the drive and its size. Any other command settles the drive ready.
# A position is present when an image of at least one sector is attached.

import MachineDisk

MachineIde :: [].{
	Phase : [Idle, Reading, Writing, Identifying]

	Position : {
		present : Bool,
		sectors : U64,
		sect_count : U64,
		lba_lo : U64,
		lba_mid : U64,
		lba_hi : U64,
		drive_head : U64,
		status : U64,
		error : U64,
		phase : MachineIde.Phase,
		# The sector in transfer, the address of the one after it, the bytes
		# left in this one, and the sectors left after it.
		buffer : List(U8),
		lba : U64,
		remaining : U64,
		sectors_left : U64,
	}

	Ide : { master : MachineIde.Position, slave : MachineIde.Position, selected : U64 }

	# ---- the doors -------------------------------------------------------

	# The channel as the machine boots it, over the drives it attached.
	attach! : MachineDisk.Drives => MachineIde.Ide
	attach! = |drives| {
		master = MachineIde.position(MachineDisk.sector_count!(MachineDisk.select(drives, 0)))
		slave = MachineIde.position(MachineDisk.sector_count!(MachineDisk.select(drives, 1)))
		{ master: master, slave: slave, selected: 0 }
	}

	# A byte or word written to one of the channel's ports.
	write! : MachineIde.Ide, MachineDisk.Drives, U64, U64 => (MachineIde.Ide, MachineDisk.Drives)
	write! = |ide, drives, p, v|
		if p == 0x1F6 {
			dh = U64.bitwise_and(v, 0xFF)
			selected = U64.bitwise_and(U64.div_trunc_by(v, 16), 1)
			({ master: { ..ide.master, drive_head: dh }, slave: { ..ide.slave, drive_head: dh }, selected: selected }, drives)
		} else {
			d = MachineIde.active(ide)
			b = U64.bitwise_and(v, 0xFF)
			if !d.present {
				(ide, drives)
			} else if p == 0x1F0 {
				(d2, drives2) = MachineIde.write_word!(d, drives, ide.selected, U64.bitwise_and(v, 0xFFFF))
				(MachineIde.with_active(ide, d2), drives2)
			} else if p == 0x1F2 {
				(MachineIde.with_active(ide, { ..d, sect_count: b }), drives)
			} else if p == 0x1F3 {
				(MachineIde.with_active(ide, { ..d, lba_lo: b }), drives)
			} else if p == 0x1F4 {
				(MachineIde.with_active(ide, { ..d, lba_mid: b }), drives)
			} else if p == 0x1F5 {
				(MachineIde.with_active(ide, { ..d, lba_hi: b }), drives)
			} else if p == 0x1F7 {
				(MachineIde.with_active(ide, MachineIde.command!(d, drives, ide.selected, b)), drives)
			} else {
				(ide, drives)
			}
		}

	# A byte or word read from one of the channel's ports.
	read! : MachineIde.Ide, MachineDisk.Drives, U64 => (MachineIde.Ide, U64)
	read! = |ide, drives, p| {
		d = MachineIde.active(ide)
		if !d.present {
			(ide, if p == 0x1F7 or p == 0x3F6 { 0x00 } else { 0xFF })
		} else if p == 0x1F7 or p == 0x3F6 {
			(ide, d.status)
		} else if p == 0x1F0 {
			(d2, w) = MachineIde.read_word!(d, drives, ide.selected)
			(MachineIde.with_active(ide, d2), w)
		} else if p == 0x1F1 {
			(ide, d.error)
		} else if p == 0x1F2 {
			(ide, d.sect_count)
		} else if p == 0x1F3 {
			(ide, d.lba_lo)
		} else if p == 0x1F4 {
			(ide, d.lba_mid)
		} else if p == 0x1F5 {
			(ide, d.lba_hi)
		} else {
			(ide, d.drive_head)
		}
	}

	# ---- the model -------------------------------------------------------

	new : MachineIde.Ide
	new = { master: MachineIde.position(0), slave: MachineIde.position(0), selected: 0 }

	position : U64 -> MachineIde.Position
	position = |sectors| {
		present: sectors > 0,
		sectors: sectors,
		sect_count: 0,
		lba_lo: 0,
		lba_mid: 0,
		lba_hi: 0,
		drive_head: 0,
		status: 0x50,
		error: 0,
		phase: Idle,
		buffer: [],
		lba: 0,
		remaining: 0,
		sectors_left: 0,
	}

	claims : U64 -> Bool
	claims = |p| (p >= 0x1F0 and p <= 0x1F7) or p == 0x3F6

	active : MachineIde.Ide -> MachineIde.Position
	active = |ide| if ide.selected == 1 { ide.slave } else { ide.master }

	with_active : MachineIde.Ide, MachineIde.Position -> MachineIde.Ide
	with_active = |ide, d| if ide.selected == 1 { ({ ..ide, slave: d }) } else { ({ ..ide, master: d }) }

	# LBA28: the three address registers and the drive/head register's low
	# nibble.
	lba_of : MachineIde.Position -> U64
	lba_of = |d| d.lba_lo + d.lba_mid * 0x100 + d.lba_hi * 0x10000 + U64.bitwise_and(d.drive_head, 15) * 0x1000000

	# A command written to 0x1F7. A read or write past the image's end is
	# refused with ERR and ID-not-found, and the transfer already under way,
	# if any, is left as it was.
	command! : MachineIde.Position, MachineDisk.Drives, U64, U64 => MachineIde.Position
	command! = |d, drives, pos, c| {
		lba = MachineIde.lba_of(d)
		count = if d.sect_count == 0 { 256 } else { d.sect_count }
		if (c == 0x20 or c == 0x30) and lba >= d.sectors {
			{ ..d, status: 0x51, error: 0x10 }
		} else if c == 0x20 {
			{ ..d, phase: Reading, buffer: MachineDisk.read!(MachineDisk.select(drives, pos), lba), lba: lba + 1, remaining: 512, sectors_left: count - 1, status: 0x58, error: 0 }
		} else if c == 0x30 {
			{ ..d, phase: Writing, buffer: [], lba: lba, remaining: 512, sectors_left: count - 1, status: 0x58, error: 0 }
		} else if c == 0xEC {
			{ ..d, phase: Identifying, buffer: MachineIde.identity(d.sectors), remaining: 512, sectors_left: 0, status: 0x58, error: 0 }
		} else {
			match d.phase {
				Reading => { ..d, status: 0x50 }
				_ => { ..d, phase: Idle, status: 0x50 }
			}
		}
	}

	# One word from the data register: nothing once the transfer is drained.
	# When a sector drains, the next one loads, or the drive settles ready.
	read_word! : MachineIde.Position, MachineDisk.Drives, U64 => (MachineIde.Position, U64)
	read_word! = |d, drives, pos|
		if d.remaining == 0 {
			(d, 0)
		} else {
			at = 512 - d.remaining
			w = MachineIde.byte(d.buffer, at) + MachineIde.byte(d.buffer, at + 1) * 256
			next = { ..d, remaining: d.remaining - 2 }
			if next.remaining != 0 {
				(next, w)
			} else if MachineIde.identifying(d) or d.sectors_left == 0 {
				({ ..next, phase: Idle, status: 0x50 }, w)
			} else {
				({ ..next, buffer: MachineDisk.read!(MachineDisk.select(drives, pos), d.lba), lba: d.lba + 1, remaining: 512, sectors_left: d.sectors_left - 1, status: 0x58 }, w)
			}
		}

	# One word into the data register during WRITE SECTORS. A completed sector
	# is stored, and the next one is taken, or the drive settles ready.
	write_word! : MachineIde.Position, MachineDisk.Drives, U64, U64 => (MachineIde.Position, MachineDisk.Drives)
	write_word! = |d, drives, pos, w|
		if d.remaining == 0 or !MachineIde.writing(d) {
			(d, drives)
		} else {
			buffer = List.concat(d.buffer, [U64.to_u8_wrap(w), U64.to_u8_wrap(U64.div_trunc_by(w, 256))])
			if d.remaining > 2 {
				({ ..d, buffer: buffer, remaining: d.remaining - 2 }, drives)
			} else {
				stored = MachineDisk.select(MachineDisk.write!(MachineDisk.select(drives, pos), d.lba, buffer), drives.selected)
				if d.sectors_left == 0 {
					({ ..d, buffer: [], remaining: 0, phase: Idle, status: 0x50 }, stored)
				} else {
					({ ..d, buffer: [], lba: d.lba + 1, remaining: 512, sectors_left: d.sectors_left - 1, status: 0x58 }, stored)
				}
			}
		}

	writing : MachineIde.Position -> Bool
	writing = |d|
		match d.phase {
			Writing => True
			_ => False
		}

	identifying : MachineIde.Position -> Bool
	identifying = |d|
		match d.phase {
			Identifying => True
			_ => False
		}

	byte : List(U8), U64 -> U64
	byte = |bytes, i| U8.to_u64(List.get(bytes, i) ?? 0)

	# IDENTIFY's sector: the model name at words 27-46, two characters a word
	# with the first in the high byte; the LBA28 sector count, clamped, at
	# words 60-61; the LBA48 count at words 100-103.
	identity : U64 -> List(U8)
	identity = |sectors| MachineIde.identity_go(sectors, 0, [])

	identity_go : U64, U64, List(U8) -> List(U8)
	identity_go = |sectors, i, acc|
		if i >= 512 {
			acc
		} else {
			MachineIde.identity_go(sectors, i + 1, List.append(acc, MachineIde.identity_byte(sectors, i)))
		}

	identity_byte : U64, U64 -> U8
	identity_byte = |sectors, i|
		if i >= 54 and i < 94 {
			k = i - 54
			c = if U64.bitwise_and(k, 1) == 0 { k + 1 } else { k - 1 }
			List.get(Str.to_utf8("CODEX VM IDE DISK"), c) ?? 32
		} else if i >= 120 and i < 124 {
			lba28 = if sectors > 0x0FFFFFFF { 0x0FFFFFFF } else { sectors }
			U64.to_u8_wrap(U64.div_trunc_by(lba28, U64.shl_wrap(1, U64.to_u8_wrap(8 * (i - 120)))))
		} else if i >= 200 and i < 208 {
			U64.to_u8_wrap(U64.div_trunc_by(sectors, U64.shl_wrap(1, U64.to_u8_wrap(8 * (i - 200)))))
		} else {
			0
		}
}
