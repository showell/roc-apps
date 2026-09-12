# StencilKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

StencilKernel :: [].{

	st_width : I32
	st_width = 1024

	st_half_w : I32
	st_half_w = 512

	st_half_h : I32
	st_half_h = 384

	st_atan2 : F32, F32 -> F32
	st_atan2 = |y, x| ({
		ax = (if (x < 0.0) { (0.0 - x) } else { x })
		ay = (if (y < 0.0) { (0.0 - y) } else { y })
		mn = DeviceMath.real_min(ax, ay)
		mx = DeviceMath.real_max(ax, ay)
		a = (if (mx > 0.0) { (mn / mx) } else { 0.0 })
		a2 = (a * a)
		base = ((a * (105.0 + (55.0 * a2))) / (105.0 + (a2 * (90.0 + (9.0 * a2)))))
		r1 = (if (ay > ax) { (1.5707963 - base) } else { base })
		r2 = (if (x < 0.0) { (3.1415925 - r1) } else { r1 })
		(if (y < 0.0) { (0.0 - r2) } else { r2 })
	})

	st_clamp01 : F32 -> F32
	st_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	st_pack : F32, F32, F32 -> I32
	st_pack = |r, g, b| I32.plus_wrap(I32.plus_wrap(I32.times_wrap(F32.to_i32_wrap((st_clamp01(r) * 255.0)), 65536), I32.times_wrap(F32.to_i32_wrap((st_clamp01(g) * 255.0)), 256)), F32.to_i32_wrap((st_clamp01(b) * 255.0)))

	st_render : I32, I32 -> I32
	st_render = |gid, frame| ({
		px = I32.to_f32(I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, st_width), st_width)))
		py = I32.to_f32(Device.div(gid, st_width))
		dx = (px - 512.0)
		dy = (py - 384.0)
		r = DeviceMath.real_sqrt(((dx * dx) + (dy * dy)))
		spin = (I32.to_f32(frame) / 35.0)
		a = (st_atan2(dy, dx) + spin)
		rb = (215.0 + (85.0 * DeviceMath.real_cos((a * 5.0))))
		d = (r - rb)
		(if (d > 6.0) { st_pack((0.04 + (py / 4000.0)), 0.05, 0.08) } else { (if (d > (0.0 - 6.0)) { st_pack(0.6, 0.95, 1.0) } else { ({
			t = (I32.to_f32(frame) / 20.0)
			sr = (0.5 + (0.5 * DeviceMath.real_sin(((r * 0.05) + t))))
			sg = (0.5 + (0.5 * DeviceMath.real_sin((((a * 3.0) + (r * 0.03)) + (t * 1.3)))))
			sb = (0.5 + (0.5 * DeviceMath.real_sin(((a * 5.0) - t))))
			st_pack(sr, sg, sb)
		}) }) })
	})

	stencil_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	stencil_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, st_render(gid, frame))
	})
}
