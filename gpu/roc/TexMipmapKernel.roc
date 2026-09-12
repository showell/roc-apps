# TexMipmapKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

TexMipmapKernel :: [].{

	tm_width : I64
	tm_width = 1024

	tm_half_w : I64
	tm_half_w = 512

	tm_horizon : I64
	tm_horizon = 300

	tm_focal : I64
	tm_focal = 420

	tm_scale : I64
	tm_scale = 52000

	tm_checker : I64, I64, I64 -> F64
	tm_checker = |u, v, cell| ({
		s = (I64.div_trunc_by(u, cell) + I64.div_trunc_by(v, cell))
		(if ((s - (I64.div_trunc_by(s, 2) * 2)) == 0) { 0.72 } else { 0.34 })
	})

	tm_clamp01 : F64 -> F64
	tm_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	tm_pack : F64, F64, F64 -> I64
	tm_pack = |r, g, b| (((F64.to_i64_wrap((tm_clamp01(r) * 255.0)) * 65536) + (F64.to_i64_wrap((tm_clamp01(g) * 255.0)) * 256)) + F64.to_i64_wrap((tm_clamp01(b) * 255.0)))

	texmipmap_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	texmipmap_step = |dev, outb, frame, gid| ({
		px = (gid - (I64.div_trunc_by(gid, tm_width) * tm_width))
		py = I64.div_trunc_by(gid, tm_width)
		sy = (py - tm_horizon)
		(if (sy <= 0) { ({
			Device.store(dev, outb, gid, (((18 * 65536) + (26 * 256)) + 48))
		}) } else { ({
			d = I64.div_trunc_by(tm_scale, sy)
			wx = (I64.div_trunc_by(((px - tm_half_w) * d), tm_focal) + (frame * 2))
			wz = d
			u = (wx - (I64.div_trunc_by(wx, 4096) * 4096))
			uu = (if (u < 0) { (u + 4096) } else { u })
			vv = (wz - (I64.div_trunc_by(wz, 4096) * 4096))
			lod = (if (sy > 220) { 0 } else { (if (sy > 120) { 1 } else { (if (sy > 60) { 2 } else { (if (sy > 30) { 3 } else { 4 }) }) }) })
			cell = (32 * (lod + 1))
			base = tm_checker(uu, vv, cell)
			fade = (if (base > 0.5) { base } else { (base + (I64.to_f64(lod) * 0.02)) })
			tintr = (1.0 + (I64.to_f64(lod) * 0.0))
			tintg = (1.0 - (I64.to_f64(lod) * 0.06))
			tintb = (1.0 - (I64.to_f64(lod) * 0.11))
			({
				Device.store(dev, outb, gid, tm_pack((fade * tintr), (fade * tintg), (fade * tintb)))
			})
		}) })
	})
}
