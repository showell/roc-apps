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
		ang : F32
		ang = (I32.to_f32(k) * 2.399)
		rad : F32
		rad = (DeviceMath.real_sqrt(I32.to_f32(k)) * 4.5)
		sx : I32
		sx = ss_clampi(I32.plus_wrap(px, F32.to_i32_wrap((DeviceMath.real_cos(ang) * rad))), 0, 1023)
		sy : I32
		sy = ss_clampi(I32.plus_wrap(py, F32.to_i32_wrap((DeviceMath.real_sin(ang) * rad))), 0, 767)
		idx : I32
		idx = I32.plus_wrap(I32.times_wrap(sy, 1024), sx)
		({
			(dev1, ndep) = Device.load(dev, buf, idx)
			({
				diff : I32
				diff = I32.minus_wrap(mydep, ndep)
				occ : I32
				occ = (if (diff > 22) { (if (diff < 520) { 1 } else { 0 }) } else { 0 })
				ss_gather(dev1, buf, px, py, mydep, I32.plus_wrap(k, 1), I32.plus_wrap(acc, occ))
			})
		})
	}) })

	ssao_step : Device.Device, I32, I32, I32, I32, I32, I32 -> (Device.Device, I32)
	ssao_step = |dev, galb, gnrm, gdep, outb, frame, gid| ({
		px : I32
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, ss_width), ss_width))
		py : I32
		py = Device.div(gid, ss_width)
		({
			(dev1, dep) = Device.load(dev, gdep, gid)
			(dev2, alb) = Device.load(dev1, galb, gid)
			(dev3, nrm) = Device.load(dev2, gnrm, gid)
			(dev4, occ) = ss_gather(dev3, gdep, px, py, dep, 0, 0)
			({
				ao : F32
				ao = DeviceMath.real_max(0.18, (1.0 - (I32.to_f32(occ) * 0.075)))
				nx : F32
				nx = ((I32.to_f32(Device.div(nrm, 65536)) / 127.0) - 1.0)
				ny : F32
				ny = ((I32.to_f32(I32.minus_wrap(Device.div(nrm, 256), I32.times_wrap(Device.div(nrm, 65536), 256))) / 127.0) - 1.0)
				nz : F32
				nz = ((I32.to_f32(I32.minus_wrap(nrm, I32.times_wrap(Device.div(nrm, 256), 256))) / 127.0) - 1.0)
				ang : F32
				ang = (I32.to_f32(frame) / 30.0)
				lx : F32
				lx = (DeviceMath.real_cos(ang) * 0.55)
				ly : F32
				ly = 0.5
				lz : F32
				lz = ((DeviceMath.real_sin(ang) * 0.55) - 0.55)
				ll : F32
				ll = DeviceMath.real_sqrt((((lx * lx) + (ly * ly)) + (lz * lz)))
				ndl : F32
				ndl = DeviceMath.real_max(0.0, ((((nx * lx) / ll) + ((ny * ly) / ll)) + ((nz * lz) / ll)))
				sh : F32
				sh = ((0.33 + (ndl * 0.52)) * ao)
				ar : I32
				ar = Device.div(alb, 65536)
				ag : I32
				ag = I32.minus_wrap(Device.div(alb, 256), I32.times_wrap(Device.div(alb, 65536), 256))
				ab : I32
				ab = I32.minus_wrap(alb, I32.times_wrap(Device.div(alb, 256), 256))
				out : I32
				out = (if (dep >= ss_miss) { I32.plus_wrap(I32.times_wrap(16, 256), 26) } else { I32.plus_wrap(I32.plus_wrap(I32.times_wrap(ss_clampi(F32.to_i32_wrap((I32.to_f32(ar) * sh)), 0, 255), 65536), I32.times_wrap(ss_clampi(F32.to_i32_wrap((I32.to_f32(ag) * sh)), 0, 255), 256)), ss_clampi(F32.to_i32_wrap((I32.to_f32(ab) * sh)), 0, 255)) })
				Device.store(dev4, outb, gid, out)
			})
		})
	})
}
