# TexArrayKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

TexArrayKernel :: [].{

	ta_width : I32
	ta_width = 1024

	ta_height : I32
	ta_height = 768

	ta_clamp01 : F32 -> F32
	ta_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	ta_pack : F32, F32, F32 -> I32
	ta_pack = |r, g, b| I32.plus_wrap(I32.plus_wrap(I32.times_wrap(F32.to_i32_wrap((ta_clamp01(r) * 255.0)), 65536), I32.times_wrap(F32.to_i32_wrap((ta_clamp01(g) * 255.0)), 256)), F32.to_i32_wrap((ta_clamp01(b) * 255.0)))

	ta_layer : I32, I32, I32 -> F32
	ta_layer = |l, lx, ly| ({
		m = I32.minus_wrap(l, I32.times_wrap(Device.div(l, 6), 6))
		(if (m == 0) { (if (I32.minus_wrap(I32.plus_wrap(Device.div(lx, 20), Device.div(ly, 20)), I32.times_wrap(Device.div(I32.plus_wrap(Device.div(lx, 20), Device.div(ly, 20)), 2), 2)) == 0) { 1.0 } else { 0.15 }) } else { (if (m == 1) { (if (I32.minus_wrap(lx, I32.times_wrap(Device.div(lx, 24), 24)) < 12) { 1.0 } else { 0.2 }) } else { (if (m == 2) { ({
			cx = I32.minus_wrap(I32.minus_wrap(lx, I32.times_wrap(Device.div(lx, 32), 32)), 16)
			cy = I32.minus_wrap(I32.minus_wrap(ly, I32.times_wrap(Device.div(ly, 32), 32)), 16)
			(if (I32.plus_wrap(I32.times_wrap(cx, cx), I32.times_wrap(cy, cy)) < 90) { 1.0 } else { 0.18 })
		}) } else { (if (m == 3) { ({
			cx = I32.minus_wrap(lx, 170)
			cy = I32.minus_wrap(ly, 120)
			d = DeviceMath.real_sqrt(I32.to_f32(I32.plus_wrap(I32.times_wrap(cx, cx), I32.times_wrap(cy, cy))))
			(if (DeviceMath.real_sin((d * 0.18)) > 0.0) { 0.95 } else { 0.2 })
		}) } else { (if (m == 4) { (if (I32.minus_wrap(lx, I32.times_wrap(Device.div(lx, 22), 22)) < 11) { (if (I32.minus_wrap(ly, I32.times_wrap(Device.div(ly, 22), 22)) < 11) { 0.9 } else { 0.3 }) } else { (if (I32.minus_wrap(ly, I32.times_wrap(Device.div(ly, 22), 22)) < 11) { 0.3 } else { 0.9 }) }) } else { ta_clamp01((I32.to_f32(I32.plus_wrap(lx, ly)) / 460.0)) }) }) }) }) })
	})

	texarray_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	texarray_step = |dev, outb, frame, gid| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, ta_width), ta_width))
		py = Device.div(gid, ta_width)
		col = Device.div(px, 342)
		row = Device.div(py, 384)
		panel = I32.plus_wrap(I32.times_wrap(row, 3), col)
		lx = I32.minus_wrap(px, I32.times_wrap(col, 342))
		ly = I32.minus_wrap(py, I32.times_wrap(row, 384))
		border = (if (lx < 3) { 1 } else { (if (lx > 338) { 1 } else { (if (ly < 3) { 1 } else { (if (ly > 380) { 1 } else { 0 }) }) }) })
		l = I32.plus_wrap(panel, Device.div(frame, 30))
		v = ta_layer(l, lx, ly)
		m = I32.minus_wrap(l, I32.times_wrap(Device.div(l, 6), 6))
		tr = (if (m == 0) { 0.9 } else { (if (m == 1) { 0.4 } else { (if (m == 2) { 0.95 } else { (if (m == 3) { 0.5 } else { (if (m == 4) { 0.85 } else { 0.6 }) }) }) }) })
		tg = (if (m == 0) { 0.5 } else { (if (m == 1) { 0.85 } else { (if (m == 2) { 0.4 } else { (if (m == 3) { 0.7 } else { (if (m == 4) { 0.5 } else { 0.9 }) }) }) }) })
		tb = (if (m == 0) { 0.3 } else { (if (m == 1) { 0.5 } else { (if (m == 2) { 0.5 } else { (if (m == 3) { 0.95 } else { (if (m == 4) { 0.9 } else { 0.4 }) }) }) }) })
		({
			Device.store(dev, outb, gid, (if (border == 1) { I32.plus_wrap(I32.plus_wrap(I32.times_wrap(20, 65536), I32.times_wrap(24, 256)), 34) } else { ta_pack((v * tr), (v * tg), (v * tb)) }))
		})
	})
}
