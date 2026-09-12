# AlphaCoverageKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

AlphaCoverageKernel :: [].{

	ac_width : I64
	ac_width = 1024

	ac_half_w : I64
	ac_half_w = 512

	ac_in : I64, I64 -> I64
	ac_in = |px, py| ({
		rx = (I64.div_trunc_by(((px * 222) - (py * 128)), 256) + 4096)
		ry = (I64.div_trunc_by(((px * 128) + (py * 222)), 256) + 4096)
		(if ((rx - (I64.div_trunc_by(rx, 20) * 20)) < 6) { 1 } else { (if ((ry - (I64.div_trunc_by(ry, 20) * 20)) < 6) { 1 } else { 0 }) })
	})

	ac_in4 : I64, I64 -> I64
	ac_in4 = |px, py| ({
		rx = (I64.div_trunc_by(((px * 222) - (py * 128)), 256) + 16384)
		ry = (I64.div_trunc_by(((px * 128) + (py * 222)), 256) + 16384)
		(if ((rx - (I64.div_trunc_by(rx, 80) * 80)) < 24) { 1 } else { (if ((ry - (I64.div_trunc_by(ry, 80) * 80)) < 24) { 1 } else { 0 }) })
	})

	ac_super : I64, I64, I64, I64 -> I64
	ac_super = |px, py, s, acc| (if (s >= 16) { acc } else { ({
		dx = (s - (I64.div_trunc_by(s, 4) * 4))
		dy = I64.div_trunc_by(s, 4)
		ac_super(px, py, (s + 1), (acc + ac_in4(((px * 4) + dx), ((py * 4) + dy))))
	}) })

	alphacov_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	alphacov_step = |dev, outb, _frame, gid| ({
		px = (gid - (I64.div_trunc_by(gid, ac_width) * ac_width))
		py = I64.div_trunc_by(gid, ac_width)
		tcx = I64.div_trunc_by(px, 34)
		tcy = I64.div_trunc_by(py, 34)
		hue = ((tcx * 3) + (tcy * 5))
		hm = (hue - (I64.div_trunc_by(hue, 6) * 6))
		fr = (if (hm == 0) { 240 } else { (if (hm == 1) { 90 } else { (if (hm == 2) { 250 } else { (if (hm == 3) { 120 } else { (if (hm == 4) { 250 } else { 80 }) }) }) }) })
		fg = (if (hm == 0) { 120 } else { (if (hm == 1) { 220 } else { (if (hm == 2) { 90 } else { (if (hm == 3) { 200 } else { (if (hm == 4) { 210 } else { 200 }) }) }) }) })
		fb = (if (hm == 0) { 70 } else { (if (hm == 1) { 120 } else { (if (hm == 2) { 200 } else { (if (hm == 3) { 240 } else { (if (hm == 4) { 90 } else { 240 }) }) }) }) })
		cov256 = (if (px < ac_half_w) { (ac_in(px, py) * 256) } else { (ac_super(px, py, 0, 0) * 16) })
		bgr = (20 + I64.div_trunc_by(py, 24))
		bgb = (40 + I64.div_trunc_by(px, 24))
		ored = I64.div_trunc_by(((fr * cov256) + (bgr * (256 - cov256))), 256)
		ogreen = I64.div_trunc_by(((fg * cov256) + (24 * (256 - cov256))), 256)
		oblue = I64.div_trunc_by(((fb * cov256) + (bgb * (256 - cov256))), 256)
		({
			Device.store(dev, outb, gid, (((ored * 65536) + (ogreen * 256)) + oblue))
		})
	})
}
