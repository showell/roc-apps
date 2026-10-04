# OmniShadowKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

OmniShadowKernel :: [].{

	om_width : I32
	om_width = 1024

	om_half_w : I32
	om_half_w = 512

	om_half_h : I32
	om_half_h = 384

	om_count : I32
	om_count = 5

	om_cx : I32 -> F32
	om_cx = |i| (DeviceMath.real_cos((I32.to_f32(i) * 1.2566)) * 1.7)

	om_cz : I32 -> F32
	om_cz = |i| (DeviceMath.real_sin((I32.to_f32(i) * 1.2566)) * 1.7)

	om_colr : I32 -> F32
	om_colr = |i| (if (i == 0) { 0.9 } else { (if (i == 1) { 0.35 } else { (if (i == 2) { 0.4 } else { (if (i == 3) { 0.9 } else { 0.6 }) }) }) })

	om_colg : I32 -> F32
	om_colg = |i| (if (i == 0) { 0.5 } else { (if (i == 1) { 0.8 } else { (if (i == 2) { 0.85 } else { (if (i == 3) { 0.8 } else { 0.5 }) }) }) })

	om_colb : I32 -> F32
	om_colb = |i| (if (i == 0) { 0.35 } else { (if (i == 1) { 0.55 } else { (if (i == 2) { 0.5 } else { (if (i == 3) { 0.35 } else { 0.9 }) }) }) })

	om_hit : F32, F32, F32, F32, F32, F32, I32 -> F32
	om_hit = |ox, oy, oz, dx, dy, dz, i| ({
		lx : F32
		lx = (ox - om_cx(i))
		lz : F32
		lz = (oz - om_cz(i))
		b : F32
		b = (((dx * lx) + (dy * (oy + 0.4))) + (dz * lz))
		c : F32
		c = ((((lx * lx) + ((oy + 0.4) * (oy + 0.4))) + (lz * lz)) - 0.36)
		disc : F32
		disc = ((b * b) - c)
		(if (disc < 0.0) { (0.0 - 1.0) } else { ({
			t : F32
			t = ((0.0 - b) - DeviceMath.real_sqrt(disc))
			(if (t > 0.001) { t } else { (0.0 - 1.0) })
		}) })
	})

	om_nearest : F32, F32, F32, F32, F32, F32, I32, I32, F32 -> I32
	om_nearest = |ox, oy, oz, dx, dy, dz, i, bid, bt| (if (i >= om_count) { bid } else { ({
		t : F32
		t = om_hit(ox, oy, oz, dx, dy, dz, i)
		take : I32
		take = (if (t > 0.001) { (if (bt < 0.0) { 1 } else { (if (t < bt) { 1 } else { 0 }) }) } else { 0 })
		(if (take == 1) { om_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), i, t) } else { om_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), bid, bt) })
	}) })

	om_shadow : F32, F32, F32, F32, F32, F32, F32, I32 -> I32
	om_shadow = |ox, oy, oz, dx, dy, dz, maxt, i| (if (i >= om_count) { 0 } else { ({
		t : F32
		t = om_hit(ox, oy, oz, dx, dy, dz, i)
		(if (t > 0.02) { (if (t < maxt) { 1 } else { om_shadow(ox, oy, oz, dx, dy, dz, maxt, I32.plus_wrap(i, 1)) }) } else { om_shadow(ox, oy, oz, dx, dy, dz, maxt, I32.plus_wrap(i, 1)) })
	}) })

	om_checker : F32, F32 -> F32
	om_checker = |hx, hz| ({
		ix : I32
		ix = F32.to_i32_wrap((hx + 64.0))
		iz : I32
		iz = F32.to_i32_wrap((hz + 64.0))
		(if (I32.minus_wrap(I32.plus_wrap(ix, iz), I32.times_wrap(Device.div(I32.plus_wrap(ix, iz), 2), 2)) == 0) { 0.35 } else { 0.6 })
	})

	om_pack : F32, F32, F32 -> I32
	om_pack = |r, g, b| I32.plus_wrap(I32.plus_wrap(I32.times_wrap(F32.to_i32_wrap((DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, r)) * 255.0)), 65536), I32.times_wrap(F32.to_i32_wrap((DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, g)) * 255.0)), 256)), F32.to_i32_wrap((DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, b)) * 255.0)))

	omnishadow_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	omnishadow_step = |dev, outb, frame, gid| ({
		px : I32
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, om_width), om_width))
		py : I32
		py = Device.div(gid, om_width)
		fx : F32
		fx = (I32.to_f32(I32.minus_wrap(px, om_half_w)) / 384.0)
		fy : F32
		fy = ((I32.to_f32(I32.minus_wrap(om_half_h, py)) / 384.0) - 0.28)
		rl : F32
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 2.56))
		dx : F32
		dx = (fx / rl)
		dy : F32
		dy = (fy / rl)
		dz : F32
		dz = (1.6 / rl)
		oy : F32
		oy = 2.4
		oz : F32
		oz = (0.0 - 5.5)
		la : F32
		la = (I32.to_f32(frame) / 40.0)
		lgx : F32
		lgx = (DeviceMath.real_cos(la) * 0.8)
		lgy : F32
		lgy = 1.1
		lgz : F32
		lgz = (DeviceMath.real_sin(la) * 0.8)
		sid : I32
		sid = om_nearest(0.0, oy, oz, dx, dy, dz, 0, I32.minus_wrap(0, 1), (0.0 - 1.0))
		st : F32
		st = (if (sid < 0) { 1000.0 } else { om_hit(0.0, oy, oz, dx, dy, dz, sid) })
		ft : F32
		ft = (if (dy < (0.0 - 0.0001)) { (((0.0 - 1.0) - oy) / dy) } else { (0.0 - 1.0) })
		usefloor : I32
		usefloor = (if (ft > 0.001) { (if (sid < 0) { 1 } else { (if (ft < st) { 1 } else { 0 }) }) } else { 0 })
		hitany : I32
		hitany = (if (usefloor == 1) { 1 } else { (if (sid >= 0) { 1 } else { 0 }) })
		(if (hitany == 0) { (dev, I32.plus_wrap(I32.plus_wrap(I32.times_wrap(10, 65536), I32.times_wrap(12, 256)), 22)) } else { ({
			t : F32
			t = (if (usefloor == 1) { ft } else { st })
			hx : F32
			hx = (dx * t)
			hy : F32
			hy = (oy + (dy * t))
			hz : F32
			hz = (oz + (dz * t))
			nx : F32
			nx = (if (usefloor == 1) { 0.0 } else { ((hx - om_cx(sid)) / 0.6) })
			ny : F32
			ny = (if (usefloor == 1) { 1.0 } else { ((hy + 0.4) / 0.6) })
			nz : F32
			nz = (if (usefloor == 1) { 0.0 } else { ((hz - om_cz(sid)) / 0.6) })
			ldx : F32
			ldx = (lgx - hx)
			ldy : F32
			ldy = (lgy - hy)
			ldz : F32
			ldz = (lgz - hz)
			ldist : F32
			ldist = DeviceMath.real_sqrt((((ldx * ldx) + (ldy * ldy)) + (ldz * ldz)))
			ux : F32
			ux = (ldx / ldist)
			uy : F32
			uy = (ldy / ldist)
			uz : F32
			uz = (ldz / ldist)
			sh : I32
			sh = om_shadow((hx + (ux * 0.02)), (hy + (uy * 0.02)), (hz + (uz * 0.02)), ux, uy, uz, (ldist - 0.1), 0)
			ndl : F32
			ndl = DeviceMath.real_max(0.0, (((nx * ux) + (ny * uy)) + (nz * uz)))
			atten : F32
			atten = (3.5 / (0.6 + (ldist * ldist)))
			vis : F32
			vis = (if (sh == 1) { 0.12 } else { 1.0 })
			lit : F32
			lit = (0.14 + (((ndl * atten) * vis) * 2.2))
			chk : F32
			chk = (if (usefloor == 1) { om_checker(hx, hz) } else { 0.0 })
			ar : F32
			ar = (if (usefloor == 1) { chk } else { om_colr(sid) })
			ag : F32
			ag = (if (usefloor == 1) { chk } else { om_colg(sid) })
			ab : F32
			ab = (if (usefloor == 1) { chk } else { om_colb(sid) })
			({
				Device.store(dev, outb, gid, om_pack((ar * lit), (ag * lit), (ab * lit)))
			})
		}) })
	})
}
