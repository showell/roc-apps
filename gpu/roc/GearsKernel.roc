# GearsKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

GearsKernel :: [].{

	gr_width : I32
	gr_width = 1024

	gr_half_h : I32
	gr_half_h = 384

	gr_atan2 : F32, F32 -> F32
	gr_atan2 = |y, x| ({
		ax : F32
		ax = (if (x < 0.0) { (0.0 - x) } else { x })
		ay : F32
		ay = (if (y < 0.0) { (0.0 - y) } else { y })
		mn : F32
		mn = DeviceMath.real_min(ax, ay)
		mx : F32
		mx = DeviceMath.real_max(ax, ay)
		a : F32
		a = (if (mx > 0.0) { (mn / mx) } else { 0.0 })
		a2 : F32
		a2 = (a * a)
		base : F32
		base = ((a * (105.0 + (55.0 * a2))) / (105.0 + (a2 * (90.0 + (9.0 * a2)))))
		r1 : F32
		r1 = (if (ay > ax) { (1.5707963 - base) } else { base })
		r2 : F32
		r2 = (if (x < 0.0) { (3.1415925 - r1) } else { r1 })
		(if (y < 0.0) { (0.0 - r2) } else { r2 })
	})

	gr_gear : F32, F32, F32, F32, F32, F32, F32 -> F32
	gr_gear = |px, py, cx, cy, teeth, rtip, spin| ({
		dx : F32
		dx = (px - cx)
		dy : F32
		dy = (py - cy)
		r : F32
		r = DeviceMath.real_sqrt(((dx * dx) + (dy * dy)))
		(if (r > rtip) { (0.0 - 1.0) } else { (if (r < (rtip * 0.22)) { (0.0 - 1.0) } else { ({
			a : F32
			a = (gr_atan2(dy, dx) + spin)
			k : I32
			k = F32.to_i32_wrap((((a * teeth) / 3.1415925) + 2000.0))
			toothon : I32
			toothon = I32.minus_wrap(k, I32.times_wrap(Device.div(k, 2), 2))
			rroot : F32
			rroot = (rtip * 0.8)
			outer : F32
			outer = (if (toothon == 0) { rtip } else { rroot })
			(if (r > outer) { (0.0 - 1.0) } else { (if (r < (rtip * 0.34)) { 0.62 } else { (if (r < (rtip * 0.42)) { 0.3 } else { (0.55 + ((r / rtip) * 0.45)) }) }) })
		}) }) })
	})

	gr_render : I32, I32 -> I32
	gr_render = |gid, frame| ({
		px : F32
		px = I32.to_f32(I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, gr_width), gr_width)))
		py : F32
		py = I32.to_f32(Device.div(gid, gr_width))
		f : F32
		f = (I32.to_f32(frame) / 30.0)
		g0 : F32
		g0 = gr_gear(px, py, 410.0, 384.0, 12.0, 160.0, f)
		g1 : F32
		g1 = gr_gear(px, py, 654.0, 300.0, 8.0, 108.0, (0.0 - (f * 1.5)))
		g2 : F32
		g2 = gr_gear(px, py, 470.0, 156.0, 10.0, 128.0, (0.0 - (f * 1.2)))
		(if (g2 >= 0.0) { gr_pack(g2, 0.55, 0.72, 0.95) } else { (if (g1 >= 0.0) { gr_pack(g1, 0.95, 0.75, 0.35) } else { (if (g0 >= 0.0) { gr_pack(g0, 0.85, 0.35, 0.3) } else { ({
			h : F32
			h = (py / 768.0)
			gr_pack(1.0, (0.04 + (h * 0.04)), (0.05 + (h * 0.06)), (0.09 + (h * 0.1)))
		}) }) }) })
	})

	gr_pack : F32, F32, F32, F32 -> I32
	gr_pack = |lit, r, g, b| ({
		ri : I32
		ri = F32.to_i32_wrap(DeviceMath.real_min(255.0, ((lit * r) * 255.0)))
		gi : I32
		gi = F32.to_i32_wrap(DeviceMath.real_min(255.0, ((lit * g) * 255.0)))
		bi : I32
		bi = F32.to_i32_wrap(DeviceMath.real_min(255.0, ((lit * b) * 255.0)))
		I32.plus_wrap(I32.plus_wrap(I32.times_wrap(ri, 65536), I32.times_wrap(gi, 256)), bi)
	})

	gears_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	gears_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, gr_render(gid, frame))
	})
}
