# Drive -- the primary IDE channel's two positions, answered by the host from
# files: position 0 is the master, 1 the slave.
#
# `open!` attaches a file to a position and answers whether it opened. A read
# is one 512-byte sector: 255 in every byte from a position with nothing on
# it, zeros past the end of a file. A write past the end changes nothing.
# What is written reaches the file before the write answers.
Drive := [].{
	open! : U64, Str => Bool
	read! : U64, U64 => List(U8)
	sector_count! : U64 => U64
	write! : U64, U64, List(U8) => {}
}
