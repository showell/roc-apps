# TextKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

TextKernel :: [].{

	tx_width : I32
	tx_width = 1024

	tx_cellw : I32
	tx_cellw = 104

	tx_rowh : I32
	tx_rowh = 22

	tx_nchar : I32
	tx_nchar = 9

	tx_row : I32, I32 -> I32
	tx_row = |ch, row| (if (ch == 0) { (if (row == 0) { 14 } else { (if (row == 1) { 17 } else { (if (row == 5) { 17 } else { (if (row == 6) { 14 } else { 16 }) }) }) }) } else { (if (ch == 1) { (if (row == 0) { 14 } else { (if (row == 6) { 14 } else { 17 }) }) } else { (if (ch == 2) { (if (row == 0) { 30 } else { (if (row == 6) { 30 } else { 17 }) }) } else { (if (ch == 3) { (if (row == 0) { 31 } else { (if (row == 3) { 30 } else { (if (row == 6) { 31 } else { 16 }) }) }) } else { (if (ch == 4) { (if (row == 2) { 10 } else { (if (row == 3) { 4 } else { (if (row == 4) { 10 } else { 17 }) }) }) } else { (if (ch == 6) { (if (row == 0) { 14 } else { (if (row == 1) { 17 } else { (if (row == 2) { 16 } else { (if (row == 3) { 23 } else { (if (row == 6) { 15 } else { 17 }) }) }) }) }) } else { (if (ch == 7) { (if (row == 0) { 30 } else { (if (row == 1) { 17 } else { (if (row == 2) { 17 } else { (if (row == 3) { 30 } else { 16 }) }) }) }) } else { (if (ch == 8) { (if (row == 6) { 14 } else { 17 }) } else { 0 }) }) }) }) }) }) }) })

	tx_bit : I32, I32, I32 -> I32
	tx_bit = |ch, col, row| (if (col < 0) { 0 } else { (if (col > 4) { 0 } else { (if (row < 0) { 0 } else { (if (row > 6) { 0 } else { ({
		rv = tx_row(ch, row)
		I32.minus_wrap(Device.div(rv, tx_pow2(I32.minus_wrap(4, col))), I32.times_wrap(Device.div(rv, tx_pow2(I32.minus_wrap(5, col))), 2))
	}) }) }) }) })

	tx_pow2 : I32 -> I32
	tx_pow2 = |n| (if (n <= 0) { 1 } else { (if (n == 1) { 2 } else { (if (n == 2) { 4 } else { (if (n == 3) { 8 } else { (if (n == 4) { 16 } else { 32 }) }) }) }) })

	tx_char : I32 -> I32
	tx_char = |i| ({
		m = I32.minus_wrap(i, I32.times_wrap(Device.div(i, tx_nchar), tx_nchar))
		(if (m == 0) { 0 } else { (if (m == 1) { 1 } else { (if (m == 2) { 2 } else { (if (m == 3) { 3 } else { (if (m == 4) { 4 } else { (if (m == 5) { 5 } else { (if (m == 6) { 6 } else { (if (m == 7) { 7 } else { 8 }) }) }) }) }) }) }) })
	})

	tx_ison : I32, I32, I32 -> I32
	tx_ison = |px, py, frame| ({
		sx = I32.plus_wrap(px, I32.times_wrap(frame, 2))
		ci = Device.div(sx, tx_cellw)
		cx = I32.minus_wrap(sx, I32.times_wrap(ci, tx_cellw))
		col = Device.div(I32.minus_wrap(cx, 12), 16)
		ry = I32.minus_wrap(py, 250)
		row = Device.div(ry, tx_rowh)
		(if (cx < 12) { 0 } else { (if (cx > 92) { 0 } else { (if (ry < 0) { 0 } else { (if (row > 6) { 0 } else { tx_bit(tx_char(ci), col, row) }) }) }) })
	})

	text_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	text_step = |dev, outb, frame, gid| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, tx_width), tx_width))
		py = Device.div(gid, tx_width)
		on = tx_ison(px, py, frame)
		shadow = tx_ison(I32.minus_wrap(px, 4), I32.minus_wrap(py, 4), frame)
		bgb = I32.plus_wrap(30, Device.div(py, 12))
		({
			Device.store(dev, outb, gid, (if (on == 1) { I32.plus_wrap(I32.plus_wrap(I32.times_wrap(255, 65536), I32.times_wrap(245, 256)), 200) } else { (if (shadow == 1) { I32.plus_wrap(I32.plus_wrap(I32.times_wrap(8, 65536), I32.times_wrap(10, 256)), 16) } else { I32.plus_wrap(I32.plus_wrap(I32.times_wrap(22, 65536), I32.times_wrap(26, 256)), bgb) }) }))
		})
	})
}
