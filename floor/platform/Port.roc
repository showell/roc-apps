# Port -- the machine's I/O ports, answered by the host (platform/core.zig):
# codex-vm's GPU at 0x400-0x417 and its keyboard controller at 0x60 and 0x64.
# `in!` answers `width` bytes from a port and `out!` writes the low `width`
# bytes of a value to one; a port no device here answers stops the run, naming
# the port.
Port := [].{
	in! : U64, U64 => U64
	out! : U64, U64, U64 => {}
}
