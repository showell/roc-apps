# ShadowMapKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

ShadowMapKernel :: [].{

	sm_res : I32
	sm_res = 1024

	sm_count : I32
	sm_count = 3

	sm_far : I32
	sm_far = 8000000

	sm_size : F32
	sm_size = 7.0

	sm_dist : F32
	sm_dist = 7.0

	sm_cx : I32 -> F32
	sm_cx = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { (0.0 - 1.5) } else { 1.4 }) })

	sm_cy : I32 -> F32
	sm_cy = |i| (if (i == 0) { 1.05 } else { (if (i == 1) { 0.6 } else { 0.75 }) })

	sm_cz : I32 -> F32
	sm_cz = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { 0.6 } else { (0.0 - 0.5) }) })

	sm_rad : I32 -> F32
	sm_rad = |i| (if (i == 0) { 0.85 } else { (if (i == 1) { 0.6 } else { 0.65 }) })

	sm_hit : F32, F32, F32, F32, F32, F32, I32 -> F32
	sm_hit = |ox, oy, oz, dx, dy, dz, i| ({
		lx : F32
		lx = (ox - sm_cx(i))
		ly : F32
		ly = (oy - sm_cy(i))
		lz : F32
		lz = (oz - sm_cz(i))
		b : F32
		b = (((dx * lx) + (dy * ly)) + (dz * lz))
		r : F32
		r = sm_rad(i)
		c : F32
		c = ((((lx * lx) + (ly * ly)) + (lz * lz)) - (r * r))
		disc : F32
		disc = ((b * b) - c)
		(if (disc < 0.0) { (0.0 - 1.0) } else { ({
			t : F32
			t = ((0.0 - b) - DeviceMath.real_sqrt(disc))
			(if (t > 0.0) { t } else { (0.0 - 1.0) })
		}) })
	})

	sm_nearest : F32, F32, F32, F32, F32, F32, I32, F32 -> F32
	sm_nearest = |ox, oy, oz, dx, dy, dz, i, best| (if (i >= sm_count) { best } else { ({
		t : F32
		t = sm_hit(ox, oy, oz, dx, dy, dz, i)
		nb : F32
		nb = (if (t > 0.0) { (if (best < 0.0) { t } else { (if (t < best) { t } else { best }) }) } else { best })
		sm_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), nb)
	}) })

	shadowmap_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	shadowmap_step = |dev, shadowbuf, frame, gid| ({
		tu : F32
		tu = (I32.to_f32(I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, sm_res), sm_res))) / 1024.0)
		tv : F32
		tv = (I32.to_f32(Device.div(gid, sm_res)) / 1024.0)
		la : F32
		la = (I32.to_f32(frame) / 40.0)
		rlx : F32
		rlx = (DeviceMath.real_cos(la) * 0.62)
		rlz : F32
		rlz = (DeviceMath.real_sin(la) * 0.62)
		ll : F32
		ll = DeviceMath.real_sqrt((((rlx * rlx) + 0.6084) + (rlz * rlz)))
		lx : F32
		lx = (rlx / ll)
		ly : F32
		ly = ((0.0 - 0.78) / ll)
		lz : F32
		lz = (rlz / ll)
		rgl : F32
		rgl = DeviceMath.real_sqrt(((lz * lz) + (lx * lx)))
		rx : F32
		rx = (lz / rgl)
		ry : F32
		ry = 0.0
		rz : F32
		rz = (0.0 - (lx / rgl))
		ux : F32
		ux = ((ly * rz) - (lz * ry))
		uy : F32
		uy = ((lz * rx) - (lx * rz))
		uz : F32
		uz = ((lx * ry) - (ly * rx))
		ox : F32
		ox = (((0.0 - (lx * sm_dist)) + (((tu - 0.5) * sm_size) * rx)) + (((tv - 0.5) * sm_size) * ux))
		oy : F32
		oy = (((0.35 - (ly * sm_dist)) + (((tu - 0.5) * sm_size) * ry)) + (((tv - 0.5) * sm_size) * uy))
		oz : F32
		oz = (((0.0 - (lz * sm_dist)) + (((tu - 0.5) * sm_size) * rz)) + (((tv - 0.5) * sm_size) * uz))
		t : F32
		t = sm_nearest(ox, oy, oz, lx, ly, lz, 0, (0.0 - 1.0))
		depv : I32
		depv = (if (t < 0.0) { sm_far } else { F32.to_i32_wrap((t * 256.0)) })
		({
			Device.store(dev, shadowbuf, gid, depv)
		})
	})
}
