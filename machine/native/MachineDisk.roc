# MachineDisk -- the block device answered by the host: the native platform's
# Drive, over the files codex-vm's -disk and -disk2 name, read and written in
# place. The doors are the modelled disk's (machine/roc/MachineDisk.roc), and
# so are the answers at the edges: 255 from a position with nothing on it,
# zeros past the end of a file, writes past the end ignored. Drive 2 and above
# is on the secondary channel, which nothing claims.

import pf.Drive

MachineDisk :: [].{
	Drives : { selected : U64 }

	# Attach each named file to its position; a file that will not open stops
	# the run by name.
	boot! : List(Str) => MachineDisk.Drives
	boot! = |paths| {
		MachineDisk.open!(paths, 0)
		{ selected: 0 }
	}

	open! : List(Str), U64 => {}
	open! = |paths, i|
		match List.get(paths, i) {
			Err(_) => {}
			Ok(p) =>
				if p == "" or Drive.open!(i, p) {
					MachineDisk.open!(paths, i + 1)
				} else {
					crash("machine: cannot open ${p} as drive ${U64.to_str(i)}")
				}
		}

	select : MachineDisk.Drives, U64 -> MachineDisk.Drives
	select = |ds, n| { ..ds, selected: n }

	sector_count! : MachineDisk.Drives => U64
	sector_count! = |ds| if ds.selected >= 2 { 0 } else { Drive.sector_count!(ds.selected) }

	read! : MachineDisk.Drives, U64 => List(U8)
	read! = |ds, lba| if ds.selected >= 2 { List.repeat(255.U8, 512) } else { Drive.read!(ds.selected, lba) }

	write! : MachineDisk.Drives, U64, List(U8) => MachineDisk.Drives
	write! = |ds, lba, sector|
		if ds.selected >= 2 {
			ds
		} else {
			Drive.write!(ds.selected, lba, sector)
			ds
		}
}
