# Heap -- the program's memory, which the host keeps: 3 GB of RAM, zero
# wherever nothing has written. `load!` answers the `width` bytes at an
# address, low byte first; `store!` writes the low `width` bytes of a value
# there. An address at or past 3 GB, where a machine keeps its devices, stops
# the run, naming the address.
Heap := [].{
	load! : U64, U64 => U64
	store! : U64, U64, U64 => {}
}
