# TexArrayKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

TexArrayKernel :: [].{

	ta_width : I64
	ta_width = 1024

	ta_height : I64
	ta_height = 768

	ta_clamp01 : F64 -> F64
	ta_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	ta_pack : F64, F64, F64 -> I64
	ta_pack = |r, g, b| (((F64.to_i64_wrap((ta_clamp01(r) * 255.0)) * 65536) + (F64.to_i64_wrap((ta_clamp01(g) * 255.0)) * 256)) + F64.to_i64_wrap((ta_clamp01(b) * 255.0)))

	ta_layer : I64, I64, I64 -> F64
	ta_layer = |l, lx, ly| ({
		m = (l - (I64.div_trunc_by(l, 6) * 6))
		(if (m == 0) { (if (((I64.div_trunc_by(lx, 20) + I64.div_trunc_by(ly, 20)) - (I64.div_trunc_by((I64.div_trunc_by(lx, 20) + I64.div_trunc_by(ly, 20)), 2) * 2)) == 0) { 1.0 } else { 0.15 }) } else { (if (m == 1) { (if ((lx - (I64.div_trunc_by(lx, 24) * 24)) < 12) { 1.0 } else { 0.2 }) } else { (if (m == 2) { ({
			cx = ((lx - (I64.div_trunc_by(lx, 32) * 32)) - 16)
			cy = ((ly - (I64.div_trunc_by(ly, 32) * 32)) - 16)
			(if (((cx * cx) + (cy * cy)) < 90) { 1.0 } else { 0.18 })
		}) } else { (if (m == 3) { ({
			cx = (lx - 170)
			cy = (ly - 120)
			d = DeviceMath.real_sqrt(I64.to_f64(((cx * cx) + (cy * cy))))
			(if (DeviceMath.real_sin((d * 0.18)) > 0.0) { 0.95 } else { 0.2 })
		}) } else { (if (m == 4) { (if ((lx - (I64.div_trunc_by(lx, 22) * 22)) < 11) { (if ((ly - (I64.div_trunc_by(ly, 22) * 22)) < 11) { 0.9 } else { 0.3 }) } else { (if ((ly - (I64.div_trunc_by(ly, 22) * 22)) < 11) { 0.3 } else { 0.9 }) }) } else { ta_clamp01((I64.to_f64((lx + ly)) / 460.0)) }) }) }) }) })
	})

	texarray_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	texarray_step = |dev, outb, frame, gid| ({
		px = (gid - (I64.div_trunc_by(gid, ta_width) * ta_width))
		py = I64.div_trunc_by(gid, ta_width)
		col = I64.div_trunc_by(px, 342)
		row = I64.div_trunc_by(py, 384)
		panel = ((row * 3) + col)
		lx = (px - (col * 342))
		ly = (py - (row * 384))
		border = (if (lx < 3) { 1 } else { (if (lx > 338) { 1 } else { (if (ly < 3) { 1 } else { (if (ly > 380) { 1 } else { 0 }) }) }) })
		l = (panel + I64.div_trunc_by(frame, 30))
		v = ta_layer(l, lx, ly)
		m = (l - (I64.div_trunc_by(l, 6) * 6))
		tr = (if (m == 0) { 0.9 } else { (if (m == 1) { 0.4 } else { (if (m == 2) { 0.95 } else { (if (m == 3) { 0.5 } else { (if (m == 4) { 0.85 } else { 0.6 }) }) }) }) })
		tg = (if (m == 0) { 0.5 } else { (if (m == 1) { 0.85 } else { (if (m == 2) { 0.4 } else { (if (m == 3) { 0.7 } else { (if (m == 4) { 0.5 } else { 0.9 }) }) }) }) })
		tb = (if (m == 0) { 0.3 } else { (if (m == 1) { 0.5 } else { (if (m == 2) { 0.5 } else { (if (m == 3) { 0.95 } else { (if (m == 4) { 0.9 } else { 0.4 }) }) }) }) })
		({
			Device.store(dev, outb, gid, (if (border == 1) { (((20 * 65536) + (24 * 256)) + 34) } else { ta_pack((v * tr), (v * tg), (v * tb)) }))
		})
	})
}
