# Disk -- the block device the host keeps, addressed the way a real controller
# is: a transfer names a sector and an address, and the 512 bytes move inside
# the host, between its image and the page the address lands on. Nothing but
# integers crosses this door.
#
# `select!` chooses the position later doors address, as x86's block-select
# does: 0 the primary master, 1 the slave, 2 and above a channel nothing
# claims. The edges answer as codex-vm's IDE model does -- a position with
# nothing on it reads the floating bus, 255 in every byte; a read past the end
# of an image answers zeros; a write past the end changes nothing -- and the
# outcome says which of those happened, so a Roc layer above can notice what
# x86 itself ignores.
Disk := [].{
	# 0 the primary master, 1 the slave, 2 and above nothing.
	select! : U64 => {}

	# The selected position's size in sectors, 0 with nothing on it.
	sector_count! : () => U64

	# `read!(lba, addr)`: the sector at `lba` into the 512 bytes at `addr`.
	# `write!(lba, addr)`: the 512 bytes at `addr` become that sector.
	# Both answer an outcome: 0 done, 1 nothing on this position, 2 past the
	# end of the image, 3 refused by an injected fault, 4 the transfer was cut
	# short by one (a torn write, whose sector holds part of each).
	read! : U64, U64 => U64
	write! : U64, U64 => U64
}
