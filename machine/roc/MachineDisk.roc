# The block device as codex-vm's IDE model answers it, modelled in Roc: the
# primary channel's master and slave, each an image or nothing. A request
# addresses the drive block-select last chose, a number whose low bit is the
# position and whose higher bits are the channel; codex-vm claims only the
# primary channel, so drive 2 and above has nothing on it.
#
# A position with nothing on it identifies as 0 sectors and reads the floating
# bus, 255 in every byte. On a present drive a read past the end answers zeros
# and a write past the end changes nothing: codex-vm refuses the command, and
# the transfer that follows moves no data.
#
# A write lands in an overlay of whole sectors, keyed by position and sector,
# so changing 512 bytes never copies a 16 MB image.
#
# The doors ending in `!` are the ones the machine calls, and
# machine/native/MachineDisk.roc answers the same doors from files on the host.
# The pure functions under them are this model, for the page.

import MachineMedia

MachineDisk :: [].{
	Drive : [Attached(List(U8)), Absent]

	Drives : { drives : List(MachineDisk.Drive), selected : U64, written : Dict(U64, List(U8)) }

	# ---- the doors -------------------------------------------------------

	# The drives a booted machine attaches: MachineMedia's images. A path from
	# the command line (-disk, -disk2) names a file on the host, which only the
	# native platform opens.
	boot! : List(Str) => MachineDisk.Drives
	boot! = |paths|
		if List.any(paths, |p| p != "") {
			crash("machine: -disk names a file on the host; the modelled disk attaches MachineMedia's images, and the native platform opens files")
		} else {
			MachineDisk.attach(MachineMedia.drives)
		}

	sector_count! : MachineDisk.Drives => U64
	sector_count! = |ds| MachineDisk.sector_count(ds)

	read! : MachineDisk.Drives, U64 => List(U8)
	read! = |ds, lba| MachineDisk.read(ds, lba)

	write! : MachineDisk.Drives, U64, List(U8) => MachineDisk.Drives
	write! = |ds, lba, sector| MachineDisk.write(ds, lba, sector)

	# ---- the model -------------------------------------------------------

	# No drives at all, for the machine's slot while a door holds the devices.
	none : MachineDisk.Drives
	none = { drives: [], selected: 0, written: Dict.empty() }

	attach : List(MachineDisk.Drive) -> MachineDisk.Drives
	attach = |drives| { drives: drives, selected: 0, written: Dict.empty() }

	select : MachineDisk.Drives, U64 -> MachineDisk.Drives
	select = |ds, n| { ..ds, selected: n }

	# The selected position, when it is on the primary channel.
	drive : MachineDisk.Drives -> MachineDisk.Drive
	drive = |ds| if ds.selected >= 2 { Absent } else { List.get(ds.drives, ds.selected) ?? Absent }

	sector_count : MachineDisk.Drives -> U64
	sector_count = |ds|
		match MachineDisk.drive(ds) {
			Attached(bytes) => U64.div_trunc_by(List.len(bytes), 512)
			Absent => 0
		}

	read : MachineDisk.Drives, U64 -> List(U8)
	read = |ds, lba|
		match MachineDisk.drive(ds) {
			Absent => List.repeat(255.U8, 512)
			Attached(bytes) =>
				if lba >= U64.div_trunc_by(List.len(bytes), 512) {
					List.repeat(0.U8, 512)
				} else {
					match Dict.get(ds.written, lba * 2 + ds.selected) {
						Ok(sector) => sector
						Err(_) => List.sublist(bytes, { start: lba * 512, len: 512 })
					}
				}
		}

	write : MachineDisk.Drives, U64, List(U8) -> MachineDisk.Drives
	write = |ds, lba, sector|
		match MachineDisk.drive(ds) {
			Attached(bytes) =>
				if lba >= U64.div_trunc_by(List.len(bytes), 512) {
					ds
				} else {
					{ ..ds, written: Dict.insert(ds.written, lba * 2 + ds.selected, sector) }
				}
			Absent => ds
		}
}
