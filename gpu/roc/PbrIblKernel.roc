# PbrIblKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

PbrIblKernel :: [].{

	pi_width : I32
	pi_width = 1024

	pi_half_w : I32
	pi_half_w = 512

	pi_half_h : I32
	pi_half_h = 384

	pi_count : I32
	pi_count = 6

	pi_env_r : F32 -> F32
	pi_env_r = |dy| (if (dy > 0.0) { (0.22 + (dy * 0.25)) } else { (0.28 - (dy * 0.1)) })

	pi_env_g : F32 -> F32
	pi_env_g = |dy| (if (dy > 0.0) { (0.38 + (dy * 0.4)) } else { (0.24 - (dy * 0.06)) })

	pi_env_b : F32 -> F32
	pi_env_b = |dy| (if (dy > 0.0) { (0.62 + (dy * 0.35)) } else { (0.16 - (dy * 0.02)) })

	pi_sun : F32, F32, F32 -> F32
	pi_sun = |dx, dy, dz| ({
		d : F32
		d = (((dx * 0.6) + (dy * 0.68)) + (dz * (0.0 - 0.68)))
		(if (d > 0.0) { ({
			p : F32
			p = (d * d)
			(((p * p) * p) * p)
		}) } else { 0.0 })
	})

	pi_cx : I32 -> F32
	pi_cx = |i| ((I32.to_f32(i) * 1.15) - 2.9)

	pi_rough : I32 -> F32
	pi_rough = |i| (0.04 + (I32.to_f32(i) * 0.17))

	pi_hit : F32, F32, F32, F32, F32, F32, I32 -> F32
	pi_hit = |ox, oy, oz, dx, dy, dz, i| ({
		lx : F32
		lx = (ox - pi_cx(i))
		b : F32
		b = (((dx * lx) + (dy * oy)) + (dz * oz))
		c : F32
		c = ((((lx * lx) + (oy * oy)) + (oz * oz)) - 0.2704)
		disc : F32
		disc = ((b * b) - c)
		(if (disc < 0.0) { (0.0 - 1.0) } else { ({
			t : F32
			t = ((0.0 - b) - DeviceMath.real_sqrt(disc))
			(if (t > 0.001) { t } else { (0.0 - 1.0) })
		}) })
	})

	pi_nearest : F32, F32, F32, F32, F32, F32, I32, I32, F32 -> I32
	pi_nearest = |ox, oy, oz, dx, dy, dz, i, bid, bt| (if (i >= pi_count) { bid } else { ({
		t : F32
		t = pi_hit(ox, oy, oz, dx, dy, dz, i)
		take : I32
		take = (if (t > 0.001) { (if (bt < 0.0) { 1 } else { (if (t < bt) { 1 } else { 0 }) }) } else { 0 })
		(if (take == 1) { pi_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), i, t) } else { pi_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), bid, bt) })
	}) })

	pi_clamp01 : F32 -> F32
	pi_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	pi_pack : F32, F32, F32 -> I32
	pi_pack = |r, g, b| I32.plus_wrap(I32.plus_wrap(I32.times_wrap(F32.to_i32_wrap((pi_clamp01(r) * 255.0)), 65536), I32.times_wrap(F32.to_i32_wrap((pi_clamp01(g) * 255.0)), 256)), F32.to_i32_wrap((pi_clamp01(b) * 255.0)))

	pi_render : I32, I32 -> I32
	pi_render = |gid, _frame| ({
		px : I32
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, pi_width), pi_width))
		py : I32
		py = Device.div(gid, pi_width)
		fx : F32
		fx = (I32.to_f32(I32.minus_wrap(px, pi_half_w)) / 384.0)
		fy : F32
		fy = (I32.to_f32(I32.minus_wrap(pi_half_h, py)) / 384.0)
		rl : F32
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 4.0))
		dx : F32
		dx = (fx / rl)
		dy : F32
		dy = (fy / rl)
		dz : F32
		dz = (2.0 / rl)
		oz : F32
		oz = (0.0 - 5.0)
		id : I32
		id = pi_nearest(0.0, 0.0, oz, dx, dy, dz, 0, I32.minus_wrap(0, 1), (0.0 - 1.0))
		(if (id < 0) { pi_pack((pi_env_r(dy) + pi_sun(dx, dy, dz)), (pi_env_g(dy) + pi_sun(dx, dy, dz)), (pi_env_b(dy) + pi_sun(dx, dy, dz))) } else { ({
			t : F32
			t = pi_hit(0.0, 0.0, oz, dx, dy, dz, id)
			hx : F32
			hx = (dx * t)
			hy : F32
			hy = (dy * t)
			hz : F32
			hz = (oz + (dz * t))
			nx : F32
			nx = ((hx - pi_cx(id)) / 0.52)
			ny : F32
			ny = (hy / 0.52)
			nz : F32
			nz = (hz / 0.52)
			vd : F32
			vd = (((dx * nx) + (dy * ny)) + (dz * nz))
			rx : F32
			rx = (dx - ((2.0 * vd) * nx))
			ry : F32
			ry = (dy - ((2.0 * vd) * ny))
			rz : F32
			rz = (dz - ((2.0 * vd) * nz))
			rough : F32
			rough = pi_rough(id)
			er : F32
			er = (pi_env_r(ry) + pi_sun(rx, ry, rz))
			eg : F32
			eg = (pi_env_g(ry) + pi_sun(rx, ry, rz))
			eb : F32
			eb = (pi_env_b(ry) + pi_sun(rx, ry, rz))
			mr : F32
			mr = ((er * (1.0 - rough)) + (0.42 * rough))
			mg : F32
			mg = ((eg * (1.0 - rough)) + (0.46 * rough))
			mb : F32
			mb = ((eb * (1.0 - rough)) + (0.55 * rough))
			fres : F32
			fres = (0.08 + ((0.92 * pi_clamp01((1.0 + vd))) * pi_clamp01((1.0 + vd))))
			tint_r : F32
			tint_r = 0.95
			tint_g : F32
			tint_g = 0.78
			tint_b : F32
			tint_b = 0.45
			pi_pack(((mr * tint_r) * (0.5 + (fres * 0.6))), ((mg * tint_g) * (0.5 + (fres * 0.6))), ((mb * tint_b) * (0.5 + (fres * 0.6))))
		}) })
	})

	pbribl_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	pbribl_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, pi_render(gid, frame))
	})
}
