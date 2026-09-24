# Warp -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Warp :: [].{
	WarpMask := { wm_bits : I64 }.{
		is_eq : Warp.WarpMask, Warp.WarpMask -> Bool
		is_eq = |a, b| a.wm_bits == b.wm_bits
	}

	warp_full_mask : Warp.WarpMask
	warp_full_mask = Warp.WarpMask.{ wm_bits: 4294967295 }
}
