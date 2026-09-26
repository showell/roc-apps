# Warp -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Warp :: [].{
	WarpMask := { wm_bits : I64 }.{
		is_eq : Warp.WarpMask, Warp.WarpMask -> Bool
		is_eq = |a, b| eq_WarpMask(a, b)
	}

	warp_full_mask : Warp.WarpMask
	warp_full_mask = Warp.WarpMask.{ wm_bits: 4294967295 }

	eq_WarpMask : Warp.WarpMask, Warp.WarpMask -> Bool
	eq_WarpMask = |ex, ey| (ex.wm_bits == ey.wm_bits)
}
