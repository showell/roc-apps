# DeferredKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

DeferredKernel :: [].{

	de_width : I32
	de_width = 1024

	de_half_w : I32
	de_half_w = 512

	de_half_h : I32
	de_half_h = 384

	de_lights : I32
	de_lights = 20

	de_miss : I32
	de_miss = 8000000

	de_lr : I32 -> F32
	de_lr = |k| ({
		m = I32.minus_wrap(k, I32.times_wrap(Device.div(k, 6), 6))
		(if (m == 0) { 1.0 } else { (if (m == 1) { 0.3 } else { (if (m == 2) { 0.35 } else { (if (m == 3) { 1.0 } else { (if (m == 4) { 0.9 } else { 0.4 }) }) }) }) })
	})

	de_lg : I32 -> F32
	de_lg = |k| ({
		m = I32.minus_wrap(k, I32.times_wrap(Device.div(k, 6), 6))
		(if (m == 0) { 0.4 } else { (if (m == 1) { 0.5 } else { (if (m == 2) { 0.85 } else { (if (m == 3) { 0.85 } else { (if (m == 4) { 0.35 } else { 0.9 }) }) }) }) })
	})

	de_lb : I32 -> F32
	de_lb = |k| ({
		m = I32.minus_wrap(k, I32.times_wrap(Device.div(k, 6), 6))
		(if (m == 0) { 0.3 } else { (if (m == 1) { 1.0 } else { (if (m == 2) { 0.6 } else { (if (m == 3) { 0.3 } else { (if (m == 4) { 0.9 } else { 0.9 }) }) }) }) })
	})

	de_accum : F32, F32, F32, F32, F32, F32, F32, I32, I32, I32 -> I32
	de_accum = |posx, posy, posz, nx, ny, nz, frame, ch, k, acc| (if (k >= de_lights) { acc } else { ({
		la = ((I32.to_f32(k) * 0.62) + frame)
		lx = (DeviceMath.real_cos(la) * 2.7)
		ly = (DeviceMath.real_sin((la * 0.6)) * 1.6)
		lz = ((DeviceMath.real_sin(la) * 2.7) - 0.4)
		ddx = (lx - posx)
		ddy = (ly - posy)
		ddz = (lz - posz)
		d2 = (((ddx * ddx) + (ddy * ddy)) + (ddz * ddz))
		dist = (DeviceMath.real_sqrt(d2) + 0.001)
		ndl = (DeviceMath.real_max(0.0, (((nx * ddx) + (ny * ddy)) + (nz * ddz))) / dist)
		atten = (4.2 / (0.5 + d2))
		lc = (if (ch == 0) { de_lr(k) } else { (if (ch == 1) { de_lg(k) } else { de_lb(k) }) })
		de_accum(posx, posy, posz, nx, ny, nz, frame, ch, I32.plus_wrap(k, 1), I32.plus_wrap(acc, F32.to_i32_wrap((((ndl * atten) * lc) * 300.0))))
	}) })

	de_clamp : I32, I32, I32 -> I32
	de_clamp = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	deferred_step : Device.Device, I32, I32, I32, I32, I32, I32 -> (Device.Device, I32)
	deferred_step = |dev, galb, gnrm, gdep, outb, frame, gid| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, de_width), de_width))
		py = Device.div(gid, de_width)
		fx = (I32.to_f32(I32.minus_wrap(px, de_half_w)) / 384.0)
		fy = (I32.to_f32(I32.minus_wrap(de_half_h, py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 3.24))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (1.8 / rl)
		({
			(dev1, alb) = Device.load(dev, galb, gid)
			(dev2, nrm) = Device.load(dev1, gnrm, gid)
			(dev3, dep) = Device.load(dev2, gdep, gid)
			({
				t = (I32.to_f32(dep) / 256.0)
				posx = (dx * t)
				posy = (dy * t)
				posz = ((0.0 - 5.0) + (dz * t))
				nx = ((I32.to_f32(Device.div(nrm, 65536)) / 127.0) - 1.0)
				ny = ((I32.to_f32(I32.minus_wrap(Device.div(nrm, 256), I32.times_wrap(Device.div(nrm, 65536), 256))) / 127.0) - 1.0)
				nz = ((I32.to_f32(I32.minus_wrap(nrm, I32.times_wrap(Device.div(nrm, 256), 256))) / 127.0) - 1.0)
				ar = Device.div(alb, 65536)
				ag = I32.minus_wrap(Device.div(alb, 256), I32.times_wrap(Device.div(alb, 65536), 256))
				ab = I32.minus_wrap(alb, I32.times_wrap(Device.div(alb, 256), 256))
				lr = de_accum(posx, posy, posz, nx, ny, nz, (I32.to_f32(frame) / 26.0), 0, 0, 0)
				lg = de_accum(posx, posy, posz, nx, ny, nz, (I32.to_f32(frame) / 26.0), 1, 0, 0)
				lb = de_accum(posx, posy, posz, nx, ny, nz, (I32.to_f32(frame) / 26.0), 2, 0, 0)
				fr = de_clamp(Device.div(I32.times_wrap(ar, I32.plus_wrap(26, lr)), 255), 0, 255)
				fg = de_clamp(Device.div(I32.times_wrap(ag, I32.plus_wrap(26, lg)), 255), 0, 255)
				fb = de_clamp(Device.div(I32.times_wrap(ab, I32.plus_wrap(26, lb)), 255), 0, 255)
				out = (if (dep >= de_miss) { I32.plus_wrap(I32.times_wrap(20, 256), 30) } else { I32.plus_wrap(I32.plus_wrap(I32.times_wrap(fr, 65536), I32.times_wrap(fg, 256)), fb) })
				Device.store(dev3, outb, gid, out)
			})
		})
	})
}
