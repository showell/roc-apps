# MachineCaps -- the capability word, as the x86 kernel keeps it: one word per
# process at offset 56 of its 256-byte entry in the process table at 20480, the
# boot program's being entry 0. x86's boot writes the opening's grant there
# before the program runs (X86_64Chapter's emit-start), expanding the effects
# the opening declares through the table in foreword/core/Capability.codex,
# and the syscalls read it back. The table and the expansion here are that
# chapter's, row for row.

MachineCaps :: [].{
	# The boot program's capability word.
	word_addr : I64
	word_addr = 20536

	# The filesystem servicer's block-authority cell (X86_64Boot's
	# fs-elevated-addr): non-zero while it drives the disk for a process that
	# holds FileSystem and not Device.Block.
	fs_elevated_addr : I64
	fs_elevated_addr = 36232

	block_device : I64
	block_device = 10

	gpu_memory : I64
	gpu_memory = 18

	# A row names its base bit, its read and write bits if the family has a
	# direction, and any further bits the family implies; -1 is no such bit.
	Row : { name : Str, base : I64, read : I64, write : I64, extra : List(I64) }

	table : List(MachineCaps.Row)
	table = [
		{ name: "Console", base: 0, read: 4, write: 5, extra: [] },
		{ name: "FileSystem", base: -1, read: 6, write: 7, extra: [] },
		{ name: "Network", base: -1, read: 8, write: 9, extra: [] },
		{ name: "Concurrent", base: 3, read: -1, write: -1, extra: [11, 12] },
		{ name: "Device", base: 10, read: -1, write: -1, extra: [16] },
		{ name: "Gpu.Compute", base: 17, read: -1, write: -1, extra: [] },
		{ name: "Gpu.Memory", base: 18, read: -1, write: -1, extra: [] },
		{ name: "Identity", base: 15, read: -1, write: -1, extra: [] },
		{ name: "Capability", base: 14, read: -1, write: -1, extra: [] },
		{ name: "Gpu", base: -1, read: -1, write: -1, extra: [17, 18] },
		{ name: "Camera", base: 19, read: -1, write: -1, extra: [] },
		{ name: "Microphone", base: 20, read: -1, write: -1, extra: [] },
		{ name: "Location", base: 21, read: -1, write: -1, extra: [] },
		{ name: "Sensors", base: 22, read: -1, write: -1, extra: [] },
		{ name: "Display", base: 23, read: -1, write: -1, extra: [] },
		{ name: "Flash", base: 24, read: -1, write: -1, extra: [] },
		{ name: "Audio", base: 25, read: -1, write: -1, extra: [] },
		{ name: "Process", base: 26, read: -1, write: -1, extra: [] },
		{ name: "Gpio", base: 27, read: -1, write: -1, extra: [] },
		{ name: "Uart", base: 28, read: -1, write: -1, extra: [] },
		{ name: "Spi", base: 29, read: -1, write: -1, extra: [] },
		{ name: "I2c", base: 1, read: -1, write: -1, extra: [] },
		{ name: "Adc", base: 2, read: -1, write: -1, extra: [] },
		{ name: "Power", base: 13, read: -1, write: -1, extra: [] },
		{ name: "Rng", base: 30, read: -1, write: -1, extra: [] },
	]

	# The grant for an opening that declares `effects` (X86_64Chapter's
	# boot-cap-mask over manifest-cap-names): each effect names its row, or its
	# base's when the dotted name has none (`Device.Block` is Device's), and
	# each row grants its bits in the direction the effects ask of it.
	grant : List(Str) -> U64
	grant = |effects| MachineCaps.grant_rows(effects, MachineCaps.rows(effects, 0, []), 0, 0)

	grant_rows : List(Str), List(Str), U64, U64 -> U64
	grant_rows = |effects, names, i, acc|
		match List.get(names, i) {
			Err(_) => acc
			Ok(n) => MachineCaps.grant_rows(effects, names, i + 1, U64.bitwise_or(acc, MachineCaps.bits(n, MachineCaps.direction(effects, n, 0, 0))))
		}

	rows : List(Str), U64, List(Str) -> List(Str)
	rows = |effects, i, acc|
		match List.get(effects, i) {
			Err(_) => acc
			Ok(e) => {
				cover = if MachineCaps.has_row(e) { e } else { MachineCaps.base(e) }
				next = if MachineCaps.has_row(cover) and !List.contains(acc, cover) { List.append(acc, cover) } else { acc }
				MachineCaps.rows(effects, i + 1, next)
			}
		}

	# The direction the effects ask of a row: its bare name asks both ways, as
	# does a member other than Read or Write, and Read with Write is both.
	direction : List(Str), Str, U64, U64 -> [Read, Write, Both]
	direction = |effects, cap, i, flags|
		match List.get(effects, i) {
			Err(_) =>
				if U64.bitwise_and(flags, 4) != 0 or flags == 3 {
					Both
				} else if flags == 1 {
					Read
				} else if flags == 2 {
					Write
				} else {
					Both
				}
			Ok(e) => {
				f =
					if MachineCaps.base(e) != cap {
						0
					} else if e == cap {
						4
					} else if MachineCaps.member(e) == "Read" {
						1
					} else if MachineCaps.member(e) == "Write" {
						2
					} else {
						4
					}
				MachineCaps.direction(effects, cap, i + 1, U64.bitwise_or(flags, f))
			}
		}

	bits : Str, [Read, Write, Both] -> U64
	bits = |name, dir|
		match MachineCaps.row(name, 0) {
			Err(_) => 0
			Ok(r) => {
				dirb =
					if r.read < 0 {
						0
					} else {
						match dir {
							Read => MachineCaps.bit(r.read)
							Write => MachineCaps.bit(r.write)
							Both => U64.bitwise_or(MachineCaps.bit(r.read), MachineCaps.bit(r.write))
						}
					}
				U64.bitwise_or(U64.bitwise_or(MachineCaps.bit(r.base), dirb), MachineCaps.extra(r.extra, 0, 0))
			}
		}

	extra : List(I64), U64, U64 -> U64
	extra = |bs, i, acc|
		match List.get(bs, i) {
			Err(_) => acc
			Ok(b) => MachineCaps.extra(bs, i + 1, U64.bitwise_or(acc, MachineCaps.bit(b)))
		}

	bit : I64 -> U64
	bit = |n| if n < 0 { 0 } else { U64.shl_wrap(1, U64.to_u8_wrap(I64.to_u64_wrap(n))) }

	row : Str, U64 -> Try(MachineCaps.Row, [NoRow])
	row = |name, i|
		match List.get(MachineCaps.table, i) {
			Err(_) => Err(NoRow)
			Ok(r) => if r.name == name { Ok(r) } else { MachineCaps.row(name, i + 1) }
		}

	has_row : Str -> Bool
	has_row = |name|
		match MachineCaps.row(name, 0) {
			Ok(_) => True
			Err(_) => False
		}

	# Before the first dot, or the whole name.
	base : Str -> Str
	base = |e|
		match Str.split_first(e, ".") {
			Ok(parts) => parts.before
			Err(_) => e
		}

	# After the first dot, or nothing.
	member : Str -> Str
	member = |e|
		match Str.split_first(e, ".") {
			Ok(parts) => parts.after
			Err(_) => ""
		}
}
