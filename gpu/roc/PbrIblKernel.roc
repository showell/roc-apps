# PbrIblKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

PbrIblKernel :: [].{

	pi_width : I64
	pi_width = 1024

	pi_half_w : I64
	pi_half_w = 512

	pi_half_h : I64
	pi_half_h = 384

	pi_count : I64
	pi_count = 6

	pi_env_r : F64 -> F64
	pi_env_r = |dy| (if (dy > 0.0) { (0.22 + (dy * 0.25)) } else { (0.28 - (dy * 0.1)) })

	pi_env_g : F64 -> F64
	pi_env_g = |dy| (if (dy > 0.0) { (0.38 + (dy * 0.4)) } else { (0.24 - (dy * 0.06)) })

	pi_env_b : F64 -> F64
	pi_env_b = |dy| (if (dy > 0.0) { (0.62 + (dy * 0.35)) } else { (0.16 - (dy * 0.02)) })

	pi_sun : F64, F64, F64 -> F64
	pi_sun = |dx, dy, dz| ({
		d = (((dx * 0.6) + (dy * 0.68)) + (dz * (0.0 - 0.68)))
		(if (d > 0.0) { ({
			p = (d * d)
			(((p * p) * p) * p)
		}) } else { 0.0 })
	})

	pi_cx : I64 -> F64
	pi_cx = |i| ((I64.to_f64(i) * 1.15) - 2.9)

	pi_rough : I64 -> F64
	pi_rough = |i| (0.04 + (I64.to_f64(i) * 0.17))

	pi_hit : F64, F64, F64, F64, F64, F64, I64 -> F64
	pi_hit = |ox, oy, oz, dx, dy, dz, i| ({
		lx = (ox - pi_cx(i))
		b = (((dx * lx) + (dy * oy)) + (dz * oz))
		c = ((((lx * lx) + (oy * oy)) + (oz * oz)) - 0.2704)
		disc = ((b * b) - c)
		(if (disc < 0.0) { (0.0 - 1.0) } else { ({
			t = ((0.0 - b) - DeviceMath.real_sqrt(disc))
			(if (t > 0.001) { t } else { (0.0 - 1.0) })
		}) })
	})

	pi_nearest : F64, F64, F64, F64, F64, F64, I64, I64, F64 -> I64
	pi_nearest = |ox, oy, oz, dx, dy, dz, i, bid, bt| (if (i >= pi_count) { bid } else { ({
		t = pi_hit(ox, oy, oz, dx, dy, dz, i)
		take = (if (t > 0.001) { (if (bt < 0.0) { 1 } else { (if (t < bt) { 1 } else { 0 }) }) } else { 0 })
		(if (take == 1) { pi_nearest(ox, oy, oz, dx, dy, dz, (i + 1), i, t) } else { pi_nearest(ox, oy, oz, dx, dy, dz, (i + 1), bid, bt) })
	}) })

	pi_clamp01 : F64 -> F64
	pi_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	pi_pack : F64, F64, F64 -> I64
	pi_pack = |r, g, b| (((F64.to_i64_wrap((pi_clamp01(r) * 255.0)) * 65536) + (F64.to_i64_wrap((pi_clamp01(g) * 255.0)) * 256)) + F64.to_i64_wrap((pi_clamp01(b) * 255.0)))

	pi_render : I64, I64 -> I64
	pi_render = |gid, _frame| ({
		px = (gid - (I64.div_trunc_by(gid, pi_width) * pi_width))
		py = I64.div_trunc_by(gid, pi_width)
		fx = (I64.to_f64((px - pi_half_w)) / 384.0)
		fy = (I64.to_f64((pi_half_h - py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 4.0))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (2.0 / rl)
		oz = (0.0 - 5.0)
		id = pi_nearest(0.0, 0.0, oz, dx, dy, dz, 0, (0 - 1), (0.0 - 1.0))
		(if (id < 0) { pi_pack((pi_env_r(dy) + pi_sun(dx, dy, dz)), (pi_env_g(dy) + pi_sun(dx, dy, dz)), (pi_env_b(dy) + pi_sun(dx, dy, dz))) } else { ({
			t = pi_hit(0.0, 0.0, oz, dx, dy, dz, id)
			hx = (dx * t)
			hy = (dy * t)
			hz = (oz + (dz * t))
			nx = ((hx - pi_cx(id)) / 0.52)
			ny = (hy / 0.52)
			nz = (hz / 0.52)
			vd = (((dx * nx) + (dy * ny)) + (dz * nz))
			rx = (dx - ((2.0 * vd) * nx))
			ry = (dy - ((2.0 * vd) * ny))
			rz = (dz - ((2.0 * vd) * nz))
			rough = pi_rough(id)
			er = (pi_env_r(ry) + pi_sun(rx, ry, rz))
			eg = (pi_env_g(ry) + pi_sun(rx, ry, rz))
			eb = (pi_env_b(ry) + pi_sun(rx, ry, rz))
			mr = ((er * (1.0 - rough)) + (0.42 * rough))
			mg = ((eg * (1.0 - rough)) + (0.46 * rough))
			mb = ((eb * (1.0 - rough)) + (0.55 * rough))
			fres = (0.08 + ((0.92 * pi_clamp01((1.0 + vd))) * pi_clamp01((1.0 + vd))))
			tint_r = 0.95
			tint_g = 0.78
			tint_b = 0.45
			pi_pack(((mr * tint_r) * (0.5 + (fres * 0.6))), ((mg * tint_g) * (0.5 + (fres * 0.6))), ((mb * tint_b) * (0.5 + (fres * 0.6))))
		}) })
	})

	pbribl_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	pbribl_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, pi_render(gid, frame))
	})
}
