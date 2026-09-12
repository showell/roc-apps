# SsaoKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

SsaoKernel :: [].{

	ss_width : I64
	ss_width = 1024

	ss_half_w : I64
	ss_half_w = 512

	ss_half_h : I64
	ss_half_h = 384

	ss_taps : I64
	ss_taps = 24

	ss_miss : I64
	ss_miss = 8000000

	ss_clampi : I64, I64, I64 -> I64
	ss_clampi = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	ss_gather : Device.Device, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	ss_gather = |dev, buf, px, py, mydep, k, acc| (if (k >= ss_taps) { (dev, acc) } else { ({
		ang = (I64.to_f64(k) * 2.399)
		rad = (DeviceMath.real_sqrt(I64.to_f64(k)) * 4.5)
		sx = ss_clampi((px + F64.to_i64_wrap((DeviceMath.real_cos(ang) * rad))), 0, 1023)
		sy = ss_clampi((py + F64.to_i64_wrap((DeviceMath.real_sin(ang) * rad))), 0, 767)
		idx = ((sy * 1024) + sx)
		({
			(dev1, ndep) = Device.load(dev, buf, idx)
			({
				diff = (mydep - ndep)
				occ = (if (diff > 22) { (if (diff < 520) { 1 } else { 0 }) } else { 0 })
				ss_gather(dev1, buf, px, py, mydep, (k + 1), (acc + occ))
			})
		})
	}) })

	ssao_step : Device.Device, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	ssao_step = |dev, galb, gnrm, gdep, outb, frame, gid| ({
		px = (gid - (I64.div_trunc_by(gid, ss_width) * ss_width))
		py = I64.div_trunc_by(gid, ss_width)
		({
			(dev1, dep) = Device.load(dev, gdep, gid)
			(dev2, alb) = Device.load(dev1, galb, gid)
			(dev3, nrm) = Device.load(dev2, gnrm, gid)
			(dev4, occ) = ss_gather(dev3, gdep, px, py, dep, 0, 0)
			({
				ao = DeviceMath.real_max(0.18, (1.0 - (I64.to_f64(occ) * 0.075)))
				nx = ((I64.to_f64(I64.div_trunc_by(nrm, 65536)) / 127.0) - 1.0)
				ny = ((I64.to_f64((I64.div_trunc_by(nrm, 256) - (I64.div_trunc_by(nrm, 65536) * 256))) / 127.0) - 1.0)
				nz = ((I64.to_f64((nrm - (I64.div_trunc_by(nrm, 256) * 256))) / 127.0) - 1.0)
				ang = (I64.to_f64(frame) / 30.0)
				lx = (DeviceMath.real_cos(ang) * 0.55)
				ly = 0.5
				lz = ((DeviceMath.real_sin(ang) * 0.55) - 0.55)
				ll = DeviceMath.real_sqrt((((lx * lx) + (ly * ly)) + (lz * lz)))
				ndl = DeviceMath.real_max(0.0, ((((nx * lx) / ll) + ((ny * ly) / ll)) + ((nz * lz) / ll)))
				sh = ((0.33 + (ndl * 0.52)) * ao)
				ar = I64.div_trunc_by(alb, 65536)
				ag = (I64.div_trunc_by(alb, 256) - (I64.div_trunc_by(alb, 65536) * 256))
				ab = (alb - (I64.div_trunc_by(alb, 256) * 256))
				out = (if (dep >= ss_miss) { ((16 * 256) + 26) } else { (((ss_clampi(F64.to_i64_wrap((I64.to_f64(ar) * sh)), 0, 255) * 65536) + (ss_clampi(F64.to_i64_wrap((I64.to_f64(ag) * sh)), 0, 255) * 256)) + ss_clampi(F64.to_i64_wrap((I64.to_f64(ab) * sh)), 0, 255)) })
				Device.store(dev4, outb, gid, out)
			})
		})
	})
}
