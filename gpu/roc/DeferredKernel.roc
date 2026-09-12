# DeferredKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

DeferredKernel :: [].{

	de_width : I64
	de_width = 1024

	de_half_w : I64
	de_half_w = 512

	de_half_h : I64
	de_half_h = 384

	de_lights : I64
	de_lights = 20

	de_miss : I64
	de_miss = 8000000

	de_lr : I64 -> F64
	de_lr = |k| ({
		m = (k - (I64.div_trunc_by(k, 6) * 6))
		(if (m == 0) { 1.0 } else { (if (m == 1) { 0.3 } else { (if (m == 2) { 0.35 } else { (if (m == 3) { 1.0 } else { (if (m == 4) { 0.9 } else { 0.4 }) }) }) }) })
	})

	de_lg : I64 -> F64
	de_lg = |k| ({
		m = (k - (I64.div_trunc_by(k, 6) * 6))
		(if (m == 0) { 0.4 } else { (if (m == 1) { 0.5 } else { (if (m == 2) { 0.85 } else { (if (m == 3) { 0.85 } else { (if (m == 4) { 0.35 } else { 0.9 }) }) }) }) })
	})

	de_lb : I64 -> F64
	de_lb = |k| ({
		m = (k - (I64.div_trunc_by(k, 6) * 6))
		(if (m == 0) { 0.3 } else { (if (m == 1) { 1.0 } else { (if (m == 2) { 0.6 } else { (if (m == 3) { 0.3 } else { (if (m == 4) { 0.9 } else { 0.9 }) }) }) }) })
	})

	de_accum : F64, F64, F64, F64, F64, F64, F64, I64, I64, I64 -> I64
	de_accum = |posx, posy, posz, nx, ny, nz, frame, ch, k, acc| (if (k >= de_lights) { acc } else { ({
		la = ((I64.to_f64(k) * 0.62) + frame)
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
		de_accum(posx, posy, posz, nx, ny, nz, frame, ch, (k + 1), (acc + F64.to_i64_wrap((((ndl * atten) * lc) * 300.0))))
	}) })

	de_clamp : I64, I64, I64 -> I64
	de_clamp = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	deferred_step : Device.Device, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	deferred_step = |dev, galb, gnrm, gdep, outb, frame, gid| ({
		px = (gid - (I64.div_trunc_by(gid, de_width) * de_width))
		py = I64.div_trunc_by(gid, de_width)
		fx = (I64.to_f64((px - de_half_w)) / 384.0)
		fy = (I64.to_f64((de_half_h - py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 3.24))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (1.8 / rl)
		({
			(dev1, alb) = Device.load(dev, galb, gid)
			(dev2, nrm) = Device.load(dev1, gnrm, gid)
			(dev3, dep) = Device.load(dev2, gdep, gid)
			({
				t = (I64.to_f64(dep) / 256.0)
				posx = (dx * t)
				posy = (dy * t)
				posz = ((0.0 - 5.0) + (dz * t))
				nx = ((I64.to_f64(I64.div_trunc_by(nrm, 65536)) / 127.0) - 1.0)
				ny = ((I64.to_f64((I64.div_trunc_by(nrm, 256) - (I64.div_trunc_by(nrm, 65536) * 256))) / 127.0) - 1.0)
				nz = ((I64.to_f64((nrm - (I64.div_trunc_by(nrm, 256) * 256))) / 127.0) - 1.0)
				ar = I64.div_trunc_by(alb, 65536)
				ag = (I64.div_trunc_by(alb, 256) - (I64.div_trunc_by(alb, 65536) * 256))
				ab = (alb - (I64.div_trunc_by(alb, 256) * 256))
				lr = de_accum(posx, posy, posz, nx, ny, nz, (I64.to_f64(frame) / 26.0), 0, 0, 0)
				lg = de_accum(posx, posy, posz, nx, ny, nz, (I64.to_f64(frame) / 26.0), 1, 0, 0)
				lb = de_accum(posx, posy, posz, nx, ny, nz, (I64.to_f64(frame) / 26.0), 2, 0, 0)
				fr = de_clamp(I64.div_trunc_by((ar * (26 + lr)), 255), 0, 255)
				fg = de_clamp(I64.div_trunc_by((ag * (26 + lg)), 255), 0, 255)
				fb = de_clamp(I64.div_trunc_by((ab * (26 + lb)), 255), 0, 255)
				out = (if (dep >= de_miss) { ((20 * 256) + 30) } else { (((fr * 65536) + (fg * 256)) + fb) })
				Device.store(dev3, outb, gid, out)
			})
		})
	})
}
