# SsaoKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

SsaoKernel :: [].{

	ss_width : I32
	ss_width = 1024

	ss_half_w : I32
	ss_half_w = 512

	ss_half_h : I32
	ss_half_h = 384

	ss_taps : I32
	ss_taps = 24

	ss_miss : I32
	ss_miss = 8000000

	ss_clampi : I32, I32, I32 -> I32
	ss_clampi = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	ss_gather : Device.Device, I32, I32, I32, I32, I32, I32 -> (Device.Device, I32)
	ss_gather = |dev, buf, px, py, mydep, k, acc| (if (k >= ss_taps) { (dev, acc) } else { ({
		ang = (I32.to_f32(k) * 2.399)
		rad = (DeviceMath.real_sqrt(I32.to_f32(k)) * 4.5)
		sx = ss_clampi(I32.plus_wrap(px, F32.to_i32_wrap((DeviceMath.real_cos(ang) * rad))), 0, 1023)
		sy = ss_clampi(I32.plus_wrap(py, F32.to_i32_wrap((DeviceMath.real_sin(ang) * rad))), 0, 767)
		idx = I32.plus_wrap(I32.times_wrap(sy, 1024), sx)
		({
			(dev1, ndep) = Device.load(dev, buf, idx)
			({
				diff = I32.minus_wrap(mydep, ndep)
				occ = (if (diff > 22) { (if (diff < 520) { 1 } else { 0 }) } else { 0 })
				ss_gather(dev1, buf, px, py, mydep, I32.plus_wrap(k, 1), I32.plus_wrap(acc, occ))
			})
		})
	}) })

	ssao_step : Device.Device, I32, I32, I32, I32, I32, I32 -> (Device.Device, I32)
	ssao_step = |dev, galb, gnrm, gdep, outb, frame, gid| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, ss_width), ss_width))
		py = Device.div(gid, ss_width)
		({
			(dev1, dep) = Device.load(dev, gdep, gid)
			(dev2, alb) = Device.load(dev1, galb, gid)
			(dev3, nrm) = Device.load(dev2, gnrm, gid)
			(dev4, occ) = ss_gather(dev3, gdep, px, py, dep, 0, 0)
			({
				ao = DeviceMath.real_max(0.18, (1.0 - (I32.to_f32(occ) * 0.075)))
				nx = ((I32.to_f32(Device.div(nrm, 65536)) / 127.0) - 1.0)
				ny = ((I32.to_f32(I32.minus_wrap(Device.div(nrm, 256), I32.times_wrap(Device.div(nrm, 65536), 256))) / 127.0) - 1.0)
				nz = ((I32.to_f32(I32.minus_wrap(nrm, I32.times_wrap(Device.div(nrm, 256), 256))) / 127.0) - 1.0)
				ang = (I32.to_f32(frame) / 30.0)
				lx = (DeviceMath.real_cos(ang) * 0.55)
				ly = 0.5
				lz = ((DeviceMath.real_sin(ang) * 0.55) - 0.55)
				ll = DeviceMath.real_sqrt((((lx * lx) + (ly * ly)) + (lz * lz)))
				ndl = DeviceMath.real_max(0.0, ((((nx * lx) / ll) + ((ny * ly) / ll)) + ((nz * lz) / ll)))
				sh = ((0.33 + (ndl * 0.52)) * ao)
				ar = Device.div(alb, 65536)
				ag = I32.minus_wrap(Device.div(alb, 256), I32.times_wrap(Device.div(alb, 65536), 256))
				ab = I32.minus_wrap(alb, I32.times_wrap(Device.div(alb, 256), 256))
				out = (if (dep >= ss_miss) { I32.plus_wrap(I32.times_wrap(16, 256), 26) } else { I32.plus_wrap(I32.plus_wrap(I32.times_wrap(ss_clampi(F32.to_i32_wrap((I32.to_f32(ar) * sh)), 0, 255), 65536), I32.times_wrap(ss_clampi(F32.to_i32_wrap((I32.to_f32(ag) * sh)), 0, 255), 256)), ss_clampi(F32.to_i32_wrap((I32.to_f32(ab) * sh)), 0, 255)) })
				Device.store(dev4, outb, gid, out)
			})
		})
	})
}
