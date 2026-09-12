# TextKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

TextKernel :: [].{

	tx_width : I64
	tx_width = 1024

	tx_cellw : I64
	tx_cellw = 104

	tx_rowh : I64
	tx_rowh = 22

	tx_nchar : I64
	tx_nchar = 9

	tx_row : I64, I64 -> I64
	tx_row = |ch, row| (if (ch == 0) { (if (row == 0) { 14 } else { (if (row == 1) { 17 } else { (if (row == 5) { 17 } else { (if (row == 6) { 14 } else { 16 }) }) }) }) } else { (if (ch == 1) { (if (row == 0) { 14 } else { (if (row == 6) { 14 } else { 17 }) }) } else { (if (ch == 2) { (if (row == 0) { 30 } else { (if (row == 6) { 30 } else { 17 }) }) } else { (if (ch == 3) { (if (row == 0) { 31 } else { (if (row == 3) { 30 } else { (if (row == 6) { 31 } else { 16 }) }) }) } else { (if (ch == 4) { (if (row == 2) { 10 } else { (if (row == 3) { 4 } else { (if (row == 4) { 10 } else { 17 }) }) }) } else { (if (ch == 6) { (if (row == 0) { 14 } else { (if (row == 1) { 17 } else { (if (row == 2) { 16 } else { (if (row == 3) { 23 } else { (if (row == 6) { 15 } else { 17 }) }) }) }) }) } else { (if (ch == 7) { (if (row == 0) { 30 } else { (if (row == 1) { 17 } else { (if (row == 2) { 17 } else { (if (row == 3) { 30 } else { 16 }) }) }) }) } else { (if (ch == 8) { (if (row == 6) { 14 } else { 17 }) } else { 0 }) }) }) }) }) }) }) })

	tx_bit : I64, I64, I64 -> I64
	tx_bit = |ch, col, row| (if (col < 0) { 0 } else { (if (col > 4) { 0 } else { (if (row < 0) { 0 } else { (if (row > 6) { 0 } else { ({
		rv = tx_row(ch, row)
		(I64.div_trunc_by(rv, tx_pow2((4 - col))) - (I64.div_trunc_by(rv, tx_pow2((5 - col))) * 2))
	}) }) }) }) })

	tx_pow2 : I64 -> I64
	tx_pow2 = |n| (if (n <= 0) { 1 } else { (if (n == 1) { 2 } else { (if (n == 2) { 4 } else { (if (n == 3) { 8 } else { (if (n == 4) { 16 } else { 32 }) }) }) }) })

	tx_char : I64 -> I64
	tx_char = |i| ({
		m = (i - (I64.div_trunc_by(i, tx_nchar) * tx_nchar))
		(if (m == 0) { 0 } else { (if (m == 1) { 1 } else { (if (m == 2) { 2 } else { (if (m == 3) { 3 } else { (if (m == 4) { 4 } else { (if (m == 5) { 5 } else { (if (m == 6) { 6 } else { (if (m == 7) { 7 } else { 8 }) }) }) }) }) }) }) })
	})

	tx_ison : I64, I64, I64 -> I64
	tx_ison = |px, py, frame| ({
		sx = (px + (frame * 2))
		ci = I64.div_trunc_by(sx, tx_cellw)
		cx = (sx - (ci * tx_cellw))
		col = I64.div_trunc_by((cx - 12), 16)
		ry = (py - 250)
		row = I64.div_trunc_by(ry, tx_rowh)
		(if (cx < 12) { 0 } else { (if (cx > 92) { 0 } else { (if (ry < 0) { 0 } else { (if (row > 6) { 0 } else { tx_bit(tx_char(ci), col, row) }) }) }) })
	})

	text_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	text_step = |dev, outb, frame, gid| ({
		px = (gid - (I64.div_trunc_by(gid, tx_width) * tx_width))
		py = I64.div_trunc_by(gid, tx_width)
		on = tx_ison(px, py, frame)
		shadow = tx_ison((px - 4), (py - 4), frame)
		bgb = (30 + I64.div_trunc_by(py, 12))
		({
			Device.store(dev, outb, gid, (if (on == 1) { (((255 * 65536) + (245 * 256)) + 200) } else { (if (shadow == 1) { (((8 * 65536) + (10 * 256)) + 16) } else { (((22 * 65536) + (26 * 256)) + bgb) }) }))
		})
	})
}
