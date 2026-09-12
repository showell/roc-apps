# TexMipmapKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

TexMipmapKernel :: [].{

	tm_width : I32
	tm_width = 1024

	tm_half_w : I32
	tm_half_w = 512

	tm_horizon : I32
	tm_horizon = 300

	tm_focal : I32
	tm_focal = 420

	tm_scale : I32
	tm_scale = 52000

	tm_checker : I32, I32, I32 -> F32
	tm_checker = |u, v, cell| ({
		s = I32.plus_wrap(Device.div(u, cell), Device.div(v, cell))
		(if (I32.minus_wrap(s, I32.times_wrap(Device.div(s, 2), 2)) == 0) { 0.72 } else { 0.34 })
	})

	tm_clamp01 : F32 -> F32
	tm_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	tm_pack : F32, F32, F32 -> I32
	tm_pack = |r, g, b| I32.plus_wrap(I32.plus_wrap(I32.times_wrap(F32.to_i32_wrap((tm_clamp01(r) * 255.0)), 65536), I32.times_wrap(F32.to_i32_wrap((tm_clamp01(g) * 255.0)), 256)), F32.to_i32_wrap((tm_clamp01(b) * 255.0)))

	texmipmap_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	texmipmap_step = |dev, outb, frame, gid| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, tm_width), tm_width))
		py = Device.div(gid, tm_width)
		sy = I32.minus_wrap(py, tm_horizon)
		(if (sy <= 0) { ({
			Device.store(dev, outb, gid, I32.plus_wrap(I32.plus_wrap(I32.times_wrap(18, 65536), I32.times_wrap(26, 256)), 48))
		}) } else { ({
			d = Device.div(tm_scale, sy)
			wx = I32.plus_wrap(Device.div(I32.times_wrap(I32.minus_wrap(px, tm_half_w), d), tm_focal), I32.times_wrap(frame, 2))
			wz = d
			u = I32.minus_wrap(wx, I32.times_wrap(Device.div(wx, 4096), 4096))
			uu = (if (u < 0) { I32.plus_wrap(u, 4096) } else { u })
			vv = I32.minus_wrap(wz, I32.times_wrap(Device.div(wz, 4096), 4096))
			lod = (if (sy > 220) { 0 } else { (if (sy > 120) { 1 } else { (if (sy > 60) { 2 } else { (if (sy > 30) { 3 } else { 4 }) }) }) })
			cell = I32.times_wrap(32, I32.plus_wrap(lod, 1))
			base = tm_checker(uu, vv, cell)
			fade = (if (base > 0.5) { base } else { (base + (I32.to_f32(lod) * 0.02)) })
			tintr = (1.0 + (I32.to_f32(lod) * 0.0))
			tintg = (1.0 - (I32.to_f32(lod) * 0.06))
			tintb = (1.0 - (I32.to_f32(lod) * 0.11))
			({
				Device.store(dev, outb, gid, tm_pack((fade * tintr), (fade * tintg), (fade * tintb)))
			})
		}) })
	})
}
