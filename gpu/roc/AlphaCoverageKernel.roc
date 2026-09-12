# AlphaCoverageKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

AlphaCoverageKernel :: [].{

	ac_width : I32
	ac_width = 1024

	ac_half_w : I32
	ac_half_w = 512

	ac_in : I32, I32 -> I32
	ac_in = |px, py| ({
		rx = I32.plus_wrap(Device.div(I32.minus_wrap(I32.times_wrap(px, 222), I32.times_wrap(py, 128)), 256), 4096)
		ry = I32.plus_wrap(Device.div(I32.plus_wrap(I32.times_wrap(px, 128), I32.times_wrap(py, 222)), 256), 4096)
		(if (I32.minus_wrap(rx, I32.times_wrap(Device.div(rx, 20), 20)) < 6) { 1 } else { (if (I32.minus_wrap(ry, I32.times_wrap(Device.div(ry, 20), 20)) < 6) { 1 } else { 0 }) })
	})

	ac_in4 : I32, I32 -> I32
	ac_in4 = |px, py| ({
		rx = I32.plus_wrap(Device.div(I32.minus_wrap(I32.times_wrap(px, 222), I32.times_wrap(py, 128)), 256), 16384)
		ry = I32.plus_wrap(Device.div(I32.plus_wrap(I32.times_wrap(px, 128), I32.times_wrap(py, 222)), 256), 16384)
		(if (I32.minus_wrap(rx, I32.times_wrap(Device.div(rx, 80), 80)) < 24) { 1 } else { (if (I32.minus_wrap(ry, I32.times_wrap(Device.div(ry, 80), 80)) < 24) { 1 } else { 0 }) })
	})

	ac_super : I32, I32, I32, I32 -> I32
	ac_super = |px, py, s, acc| (if (s >= 16) { acc } else { ({
		dx = I32.minus_wrap(s, I32.times_wrap(Device.div(s, 4), 4))
		dy = Device.div(s, 4)
		ac_super(px, py, I32.plus_wrap(s, 1), I32.plus_wrap(acc, ac_in4(I32.plus_wrap(I32.times_wrap(px, 4), dx), I32.plus_wrap(I32.times_wrap(py, 4), dy))))
	}) })

	alphacov_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	alphacov_step = |dev, outb, _frame, gid| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, ac_width), ac_width))
		py = Device.div(gid, ac_width)
		tcx = Device.div(px, 34)
		tcy = Device.div(py, 34)
		hue = I32.plus_wrap(I32.times_wrap(tcx, 3), I32.times_wrap(tcy, 5))
		hm = I32.minus_wrap(hue, I32.times_wrap(Device.div(hue, 6), 6))
		fr = (if (hm == 0) { 240 } else { (if (hm == 1) { 90 } else { (if (hm == 2) { 250 } else { (if (hm == 3) { 120 } else { (if (hm == 4) { 250 } else { 80 }) }) }) }) })
		fg = (if (hm == 0) { 120 } else { (if (hm == 1) { 220 } else { (if (hm == 2) { 90 } else { (if (hm == 3) { 200 } else { (if (hm == 4) { 210 } else { 200 }) }) }) }) })
		fb = (if (hm == 0) { 70 } else { (if (hm == 1) { 120 } else { (if (hm == 2) { 200 } else { (if (hm == 3) { 240 } else { (if (hm == 4) { 90 } else { 240 }) }) }) }) })
		cov256 = (if (px < ac_half_w) { I32.times_wrap(ac_in(px, py), 256) } else { I32.times_wrap(ac_super(px, py, 0, 0), 16) })
		bgr = I32.plus_wrap(20, Device.div(py, 24))
		bgb = I32.plus_wrap(40, Device.div(px, 24))
		ored = Device.div(I32.plus_wrap(I32.times_wrap(fr, cov256), I32.times_wrap(bgr, I32.minus_wrap(256, cov256))), 256)
		ogreen = Device.div(I32.plus_wrap(I32.times_wrap(fg, cov256), I32.times_wrap(24, I32.minus_wrap(256, cov256))), 256)
		oblue = Device.div(I32.plus_wrap(I32.times_wrap(fb, cov256), I32.times_wrap(bgb, I32.minus_wrap(256, cov256))), 256)
		({
			Device.store(dev, outb, gid, I32.plus_wrap(I32.plus_wrap(I32.times_wrap(ored, 65536), I32.times_wrap(ogreen, 256)), oblue))
		})
	})
}
