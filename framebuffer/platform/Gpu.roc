# Gpu -- the GPU codex-vm models behind ports 0x400-0x417, kept by the host
# (platform/gpu.zig) and drawing into the program's memory. `out!` writes a
# port and `in!` reads one; a port the host does not model stops the run,
# naming it.
Gpu := [].{
	in! : U64 => U64
	out! : U64, U64 => {}
}
