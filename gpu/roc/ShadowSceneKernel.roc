# ShadowSceneKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

ShadowSceneKernel :: [].{

	sc_width : I64
	sc_width = 1024

	sc_half_w : I64
	sc_half_w = 512

	sc_half_h : I64
	sc_half_h = 384

	sc_count : I64
	sc_count = 3

	sc_far : I64
	sc_far = 8000000

	sc_size : F64
	sc_size = 7.0

	sc_dist : F64
	sc_dist = 7.0

	sc_cx : I64 -> F64
	sc_cx = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { (0.0 - 1.5) } else { 1.4 }) })

	sc_cy : I64 -> F64
	sc_cy = |i| (if (i == 0) { 1.05 } else { (if (i == 1) { 0.6 } else { 0.75 }) })

	sc_cz : I64 -> F64
	sc_cz = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { 0.6 } else { (0.0 - 0.5) }) })

	sc_rad : I64 -> F64
	sc_rad = |i| (if (i == 0) { 0.85 } else { (if (i == 1) { 0.6 } else { 0.65 }) })

	sc_colr : I64 -> F64
	sc_colr = |i| (if (i == 0) { 0.9 } else { (if (i == 1) { 0.35 } else { 0.75 }) })

	sc_colg : I64 -> F64
	sc_colg = |i| (if (i == 0) { 0.55 } else { (if (i == 1) { 0.75 } else { 0.4 }) })

	sc_colb : I64 -> F64
	sc_colb = |i| (if (i == 0) { 0.3 } else { (if (i == 1) { 0.55 } else { 0.95 }) })

	sc_hit : F64, F64, F64, F64, F64, F64, I64 -> F64
	sc_hit = |ox, oy, oz, dx, dy, dz, i| ({
		lx = (ox - sc_cx(i))
		ly = (oy - sc_cy(i))
		lz = (oz - sc_cz(i))
		b = (((dx * lx) + (dy * ly)) + (dz * lz))
		r = sc_rad(i)
		c = ((((lx * lx) + (ly * ly)) + (lz * lz)) - (r * r))
		disc = ((b * b) - c)
		(if (disc < 0.0) { (0.0 - 1.0) } else { ({
			t = ((0.0 - b) - DeviceMath.real_sqrt(disc))
			(if (t > 0.001) { t } else { (0.0 - 1.0) })
		}) })
	})

	sc_nearest : F64, F64, F64, F64, F64, F64, I64, I64, F64 -> I64
	sc_nearest = |ox, oy, oz, dx, dy, dz, i, bid, bt| (if (i >= sc_count) { bid } else { ({
		t = sc_hit(ox, oy, oz, dx, dy, dz, i)
		take = (if (t > 0.001) { (if (bt < 0.0) { 1 } else { (if (t < bt) { 1 } else { 0 }) }) } else { 0 })
		(if (take == 1) { sc_nearest(ox, oy, oz, dx, dy, dz, (i + 1), i, t) } else { sc_nearest(ox, oy, oz, dx, dy, dz, (i + 1), bid, bt) })
	}) })

	sc_clampi : I64, I64, I64 -> I64
	sc_clampi = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	sc_pack : F64, F64, F64 -> I64
	sc_pack = |r, g, b| ({
		ri = sc_clampi(F64.to_i64_wrap((r * 255.0)), 0, 255)
		gi = sc_clampi(F64.to_i64_wrap((g * 255.0)), 0, 255)
		bi = sc_clampi(F64.to_i64_wrap((b * 255.0)), 0, 255)
		(((ri * 65536) + (gi * 256)) + bi)
	})

	sc_checker : F64, F64 -> F64
	sc_checker = |x, z| ({
		ix = F64.to_i64_wrap((x + 64.0))
		iz = F64.to_i64_wrap((z + 64.0))
		s = (ix + iz)
		(if ((s - (I64.div_trunc_by(s, 2) * 2)) == 0) { 0.3 } else { 0.55 })
	})

	shadowmain_step : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	shadowmain_step = |dev, shadowbuf, outb, frame, gid| ({
		px = (gid - (I64.div_trunc_by(gid, sc_width) * sc_width))
		py = I64.div_trunc_by(gid, sc_width)
		fx = (I64.to_f64((px - sc_half_w)) / 384.0)
		fy = ((I64.to_f64((sc_half_h - py)) / 384.0) - 0.12)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 2.56))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (1.6 / rl)
		ox = 0.0
		oy = 1.7
		oz = (0.0 - 6.0)
		sid = sc_nearest(ox, oy, oz, dx, dy, dz, 0, (0 - 1), (0.0 - 1.0))
		st = (if (sid < 0) { 1000.0 } else { sc_hit(ox, oy, oz, dx, dy, dz, sid) })
		ft = (if (dy < (0.0 - 0.0001)) { (((0.0 - 1.0) - oy) / dy) } else { (0.0 - 1.0) })
		usefloor = (if (ft > 0.001) { (if (sid < 0) { 1 } else { (if (ft < st) { 1 } else { 0 }) }) } else { 0 })
		hitany = (if (usefloor == 1) { 1 } else { (if (sid >= 0) { 1 } else { 0 }) })
		(if (hitany == 0) { (dev, (((6 * 65536) + (10 * 256)) + 20)) } else { ({
			t = (if (usefloor == 1) { ft } else { st })
			hx = (ox + (dx * t))
			hy = (oy + (dy * t))
			hz = (oz + (dz * t))
			nx = (if (usefloor == 1) { 0.0 } else { ((hx - sc_cx(sid)) / sc_rad(sid)) })
			ny = (if (usefloor == 1) { 1.0 } else { ((hy - sc_cy(sid)) / sc_rad(sid)) })
			nz = (if (usefloor == 1) { 0.0 } else { ((hz - sc_cz(sid)) / sc_rad(sid)) })
			ar = (if (usefloor == 1) { sc_checker(hx, hz) } else { sc_colr(sid) })
			ag = (if (usefloor == 1) { sc_checker(hx, hz) } else { sc_colg(sid) })
			ab = (if (usefloor == 1) { sc_checker(hx, hz) } else { sc_colb(sid) })
			la = (I64.to_f64(frame) / 40.0)
			rlx = (DeviceMath.real_cos(la) * 0.62)
			rlz = (DeviceMath.real_sin(la) * 0.62)
			ll = DeviceMath.real_sqrt((((rlx * rlx) + 0.6084) + (rlz * rlz)))
			lx = (rlx / ll)
			ly = ((0.0 - 0.78) / ll)
			lz = (rlz / ll)
			rgl = DeviceMath.real_sqrt(((lz * lz) + (lx * lx)))
			rx = (lz / rgl)
			rz = (0.0 - (lx / rgl))
			ux = (ly * rz)
			uy = ((lz * rx) - (lx * rz))
			uz = (0.0 - (ly * rx))
			rcx = (hx - 0.0)
			rcy = (hy - 0.35)
			rcz = (hz - 0.0)
			lu = ((((rcx * rx) + (rcz * rz)) / sc_size) + 0.5)
			lv = (((((rcx * ux) + (rcy * uy)) + (rcz * uz)) / sc_size) + 0.5)
			ld = ((((rcx * lx) + (rcy * ly)) + (rcz * lz)) + sc_dist)
			({
				(dev1, stored) = Device.load(dev, shadowbuf, ((sc_clampi(F64.to_i64_wrap((lv * 1024.0)), 0, 1023) * 1024) + sc_clampi(F64.to_i64_wrap((lu * 1024.0)), 0, 1023)))
				({
					inmap = (if (lu > 0.0) { (if (lu < 1.0) { (if (lv > 0.0) { (if (lv < 1.0) { 1 } else { 0 }) } else { 0 }) } else { 0 }) } else { 0 })
					shadowed = (if (inmap == 1) { (if (stored < sc_far) { (if (F64.to_i64_wrap((ld * 256.0)) > (stored + 500)) { 1 } else { 0 }) } else { 0 }) } else { 0 })
					ndl = DeviceMath.real_max(0.0, (0.0 - (((nx * lx) + (ny * ly)) + (nz * lz))))
					vis = (if (shadowed == 1) { 0.18 } else { 1.0 })
					sh = (0.2 + ((ndl * 0.85) * vis))
					Device.store(dev1, outb, gid, sc_pack((ar * sh), (ag * sh), (ab * sh)))
				})
			})
		}) })
	})
}
