# Heap -- the program's memory, which the host keeps: 32 bits of address,
# zero wherever nothing has written. `load!` answers the `width` bytes at an
# address, low byte first; `store!` writes the low `width` bytes of a value
# there. An address past 4 GB stops the run, naming the address.
Heap := [].{
	load! : U64, U64 => U64
	store! : U64, U64, U64 => {}
}
