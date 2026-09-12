# ShadowMapKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

ShadowMapKernel :: [].{

	sm_res : I64
	sm_res = 1024

	sm_count : I64
	sm_count = 3

	sm_far : I64
	sm_far = 8000000

	sm_size : F64
	sm_size = 7.0

	sm_dist : F64
	sm_dist = 7.0

	sm_cx : I64 -> F64
	sm_cx = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { (0.0 - 1.5) } else { 1.4 }) })

	sm_cy : I64 -> F64
	sm_cy = |i| (if (i == 0) { 1.05 } else { (if (i == 1) { 0.6 } else { 0.75 }) })

	sm_cz : I64 -> F64
	sm_cz = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { 0.6 } else { (0.0 - 0.5) }) })

	sm_rad : I64 -> F64
	sm_rad = |i| (if (i == 0) { 0.85 } else { (if (i == 1) { 0.6 } else { 0.65 }) })

	sm_hit : F64, F64, F64, F64, F64, F64, I64 -> F64
	sm_hit = |ox, oy, oz, dx, dy, dz, i| ({
		lx = (ox - sm_cx(i))
		ly = (oy - sm_cy(i))
		lz = (oz - sm_cz(i))
		b = (((dx * lx) + (dy * ly)) + (dz * lz))
		r = sm_rad(i)
		c = ((((lx * lx) + (ly * ly)) + (lz * lz)) - (r * r))
		disc = ((b * b) - c)
		(if (disc < 0.0) { (0.0 - 1.0) } else { ({
			t = ((0.0 - b) - DeviceMath.real_sqrt(disc))
			(if (t > 0.0) { t } else { (0.0 - 1.0) })
		}) })
	})

	sm_nearest : F64, F64, F64, F64, F64, F64, I64, F64 -> F64
	sm_nearest = |ox, oy, oz, dx, dy, dz, i, best| (if (i >= sm_count) { best } else { ({
		t = sm_hit(ox, oy, oz, dx, dy, dz, i)
		nb = (if (t > 0.0) { (if (best < 0.0) { t } else { (if (t < best) { t } else { best }) }) } else { best })
		sm_nearest(ox, oy, oz, dx, dy, dz, (i + 1), nb)
	}) })

	shadowmap_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	shadowmap_step = |dev, shadowbuf, frame, gid| ({
		tu = (I64.to_f64((gid - (I64.div_trunc_by(gid, sm_res) * sm_res))) / 1024.0)
		tv = (I64.to_f64(I64.div_trunc_by(gid, sm_res)) / 1024.0)
		la = (I64.to_f64(frame) / 40.0)
		rlx = (DeviceMath.real_cos(la) * 0.62)
		rlz = (DeviceMath.real_sin(la) * 0.62)
		ll = DeviceMath.real_sqrt((((rlx * rlx) + 0.6084) + (rlz * rlz)))
		lx = (rlx / ll)
		ly = ((0.0 - 0.78) / ll)
		lz = (rlz / ll)
		rgl = DeviceMath.real_sqrt(((lz * lz) + (lx * lx)))
		rx = (lz / rgl)
		ry = 0.0
		rz = (0.0 - (lx / rgl))
		ux = ((ly * rz) - (lz * ry))
		uy = ((lz * rx) - (lx * rz))
		uz = ((lx * ry) - (ly * rx))
		ox = (((0.0 - (lx * sm_dist)) + (((tu - 0.5) * sm_size) * rx)) + (((tv - 0.5) * sm_size) * ux))
		oy = (((0.35 - (ly * sm_dist)) + (((tu - 0.5) * sm_size) * ry)) + (((tv - 0.5) * sm_size) * uy))
		oz = (((0.0 - (lz * sm_dist)) + (((tu - 0.5) * sm_size) * rz)) + (((tv - 0.5) * sm_size) * uz))
		t = sm_nearest(ox, oy, oz, lx, ly, lz, 0, (0.0 - 1.0))
		depv = (if (t < 0.0) { sm_far } else { F64.to_i64_wrap((t * 256.0)) })
		({
			Device.store(dev, shadowbuf, gid, depv)
		})
	})
}
