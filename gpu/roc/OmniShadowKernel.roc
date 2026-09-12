# OmniShadowKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

OmniShadowKernel :: [].{

	om_width : I64
	om_width = 1024

	om_half_w : I64
	om_half_w = 512

	om_half_h : I64
	om_half_h = 384

	om_count : I64
	om_count = 5

	om_cx : I64 -> F64
	om_cx = |i| (DeviceMath.real_cos((I64.to_f64(i) * 1.2566)) * 1.7)

	om_cz : I64 -> F64
	om_cz = |i| (DeviceMath.real_sin((I64.to_f64(i) * 1.2566)) * 1.7)

	om_colr : I64 -> F64
	om_colr = |i| (if (i == 0) { 0.9 } else { (if (i == 1) { 0.35 } else { (if (i == 2) { 0.4 } else { (if (i == 3) { 0.9 } else { 0.6 }) }) }) })

	om_colg : I64 -> F64
	om_colg = |i| (if (i == 0) { 0.5 } else { (if (i == 1) { 0.8 } else { (if (i == 2) { 0.85 } else { (if (i == 3) { 0.8 } else { 0.5 }) }) }) })

	om_colb : I64 -> F64
	om_colb = |i| (if (i == 0) { 0.35 } else { (if (i == 1) { 0.55 } else { (if (i == 2) { 0.5 } else { (if (i == 3) { 0.35 } else { 0.9 }) }) }) })

	om_hit : F64, F64, F64, F64, F64, F64, I64 -> F64
	om_hit = |ox, oy, oz, dx, dy, dz, i| ({
		lx = (ox - om_cx(i))
		lz = (oz - om_cz(i))
		b = (((dx * lx) + (dy * (oy + 0.4))) + (dz * lz))
		c = ((((lx * lx) + ((oy + 0.4) * (oy + 0.4))) + (lz * lz)) - 0.36)
		disc = ((b * b) - c)
		(if (disc < 0.0) { (0.0 - 1.0) } else { ({
			t = ((0.0 - b) - DeviceMath.real_sqrt(disc))
			(if (t > 0.001) { t } else { (0.0 - 1.0) })
		}) })
	})

	om_nearest : F64, F64, F64, F64, F64, F64, I64, I64, F64 -> I64
	om_nearest = |ox, oy, oz, dx, dy, dz, i, bid, bt| (if (i >= om_count) { bid } else { ({
		t = om_hit(ox, oy, oz, dx, dy, dz, i)
		take = (if (t > 0.001) { (if (bt < 0.0) { 1 } else { (if (t < bt) { 1 } else { 0 }) }) } else { 0 })
		(if (take == 1) { om_nearest(ox, oy, oz, dx, dy, dz, (i + 1), i, t) } else { om_nearest(ox, oy, oz, dx, dy, dz, (i + 1), bid, bt) })
	}) })

	om_shadow : F64, F64, F64, F64, F64, F64, F64, I64 -> I64
	om_shadow = |ox, oy, oz, dx, dy, dz, maxt, i| (if (i >= om_count) { 0 } else { ({
		t = om_hit(ox, oy, oz, dx, dy, dz, i)
		(if (t > 0.02) { (if (t < maxt) { 1 } else { om_shadow(ox, oy, oz, dx, dy, dz, maxt, (i + 1)) }) } else { om_shadow(ox, oy, oz, dx, dy, dz, maxt, (i + 1)) })
	}) })

	om_checker : F64, F64 -> F64
	om_checker = |hx, hz| ({
		ix = F64.to_i64_wrap((hx + 64.0))
		iz = F64.to_i64_wrap((hz + 64.0))
		(if (((ix + iz) - (I64.div_trunc_by((ix + iz), 2) * 2)) == 0) { 0.35 } else { 0.6 })
	})

	om_pack : F64, F64, F64 -> I64
	om_pack = |r, g, b| (((F64.to_i64_wrap((DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, r)) * 255.0)) * 65536) + (F64.to_i64_wrap((DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, g)) * 255.0)) * 256)) + F64.to_i64_wrap((DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, b)) * 255.0)))

	omnishadow_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	omnishadow_step = |dev, outb, frame, gid| ({
		px = (gid - (I64.div_trunc_by(gid, om_width) * om_width))
		py = I64.div_trunc_by(gid, om_width)
		fx = (I64.to_f64((px - om_half_w)) / 384.0)
		fy = ((I64.to_f64((om_half_h - py)) / 384.0) - 0.28)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 2.56))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (1.6 / rl)
		oy = 2.4
		oz = (0.0 - 5.5)
		la = (I64.to_f64(frame) / 40.0)
		lgx = (DeviceMath.real_cos(la) * 0.8)
		lgy = 1.1
		lgz = (DeviceMath.real_sin(la) * 0.8)
		sid = om_nearest(0.0, oy, oz, dx, dy, dz, 0, (0 - 1), (0.0 - 1.0))
		st = (if (sid < 0) { 1000.0 } else { om_hit(0.0, oy, oz, dx, dy, dz, sid) })
		ft = (if (dy < (0.0 - 0.0001)) { (((0.0 - 1.0) - oy) / dy) } else { (0.0 - 1.0) })
		usefloor = (if (ft > 0.001) { (if (sid < 0) { 1 } else { (if (ft < st) { 1 } else { 0 }) }) } else { 0 })
		hitany = (if (usefloor == 1) { 1 } else { (if (sid >= 0) { 1 } else { 0 }) })
		(if (hitany == 0) { (dev, (((10 * 65536) + (12 * 256)) + 22)) } else { ({
			t = (if (usefloor == 1) { ft } else { st })
			hx = (dx * t)
			hy = (oy + (dy * t))
			hz = (oz + (dz * t))
			nx = (if (usefloor == 1) { 0.0 } else { ((hx - om_cx(sid)) / 0.6) })
			ny = (if (usefloor == 1) { 1.0 } else { ((hy + 0.4) / 0.6) })
			nz = (if (usefloor == 1) { 0.0 } else { ((hz - om_cz(sid)) / 0.6) })
			ldx = (lgx - hx)
			ldy = (lgy - hy)
			ldz = (lgz - hz)
			ldist = DeviceMath.real_sqrt((((ldx * ldx) + (ldy * ldy)) + (ldz * ldz)))
			ux = (ldx / ldist)
			uy = (ldy / ldist)
			uz = (ldz / ldist)
			sh = om_shadow((hx + (ux * 0.02)), (hy + (uy * 0.02)), (hz + (uz * 0.02)), ux, uy, uz, (ldist - 0.1), 0)
			ndl = DeviceMath.real_max(0.0, (((nx * ux) + (ny * uy)) + (nz * uz)))
			atten = (3.5 / (0.6 + (ldist * ldist)))
			vis = (if (sh == 1) { 0.12 } else { 1.0 })
			lit = (0.14 + (((ndl * atten) * vis) * 2.2))
			chk = (if (usefloor == 1) { om_checker(hx, hz) } else { 0.0 })
			ar = (if (usefloor == 1) { chk } else { om_colr(sid) })
			ag = (if (usefloor == 1) { chk } else { om_colg(sid) })
			ab = (if (usefloor == 1) { chk } else { om_colb(sid) })
			({
				Device.store(dev, outb, gid, om_pack((ar * lit), (ag * lit), (ab * lit)))
			})
		}) })
	})
}
