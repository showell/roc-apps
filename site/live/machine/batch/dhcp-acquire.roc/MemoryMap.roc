# MemoryMap -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

MemoryMap :: [].{

	bare_metal_ram_size : I64
	bare_metal_ram_size = 3221225472

	bare_metal_pd_count : I64
	bare_metal_pd_count = I64.div_trunc_by((bare_metal_ram_size + 1073741823), 1073741824)

	bare_metal_device_window_lo : I64
	bare_metal_device_window_lo = (bare_metal_pd_count * 1073741824)

	bare_metal_device_window_hi : I64
	bare_metal_device_window_hi = ((bare_metal_pd_count + 1) * 1073741824)
}
