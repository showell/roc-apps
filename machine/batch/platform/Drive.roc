# Drive -- the primary IDE channel's two positions, answered by the host from
# buffers the page fills: position 0 is the master, 1 the slave.
#
# `open!` answers whether the page gave the position a buffer; the name is
# the command line's and is not read. A read is one 512-byte sector: 255 in
# every byte from a position with nothing on it, zeros past the end of its
# buffer. A write past the end changes nothing.
Drive := [].{
	open! : U64, Str => Bool
	read! : U64, U64 => List(U8)
	sector_count! : U64 => U64
	write! : U64, U64, List(U8) => {}
}
