# GbufKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

GbufKernel :: [].{

	gb_width : I64
	gb_width = 1024

	gb_half_w : I64
	gb_half_w = 512

	gb_half_h : I64
	gb_half_h = 384

	gb_count : I64
	gb_count = 8

	gb_miss : I64
	gb_miss = 8000000

	gb_cx : I64 -> F64
	gb_cx = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { 0.95 } else { (if (i == 2) { (0.0 - 0.85) } else { (if (i == 3) { 0.35 } else { (if (i == 4) { (0.0 - 0.45) } else { (if (i == 5) { 0.55 } else { (if (i == 6) { (0.0 - 0.6) } else { 0.15 }) }) }) }) }) }) })

	gb_cy : I64 -> F64
	gb_cy = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { 0.35 } else { (if (i == 2) { 0.25 } else { (if (i == 3) { (0.0 - 0.8) } else { (if (i == 4) { (0.0 - 0.6) } else { (if (i == 5) { 0.75 } else { (if (i == 6) { 0.7 } else { 0.1 }) }) }) }) }) }) })

	gb_cz : I64 -> F64
	gb_cz = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { (0.0 - 0.2) } else { (if (i == 2) { 0.1 } else { (if (i == 3) { 0.2 } else { (if (i == 4) { (0.0 - 0.3) } else { (if (i == 5) { 0.3 } else { (if (i == 6) { (0.0 - 0.1) } else { 0.8 }) }) }) }) }) }) })

	gb_rad : I64 -> F64
	gb_rad = |i| (if (i == 0) { 0.9 } else { (if (i == 1) { 0.62 } else { (if (i == 2) { 0.6 } else { (if (i == 3) { 0.55 } else { (if (i == 4) { 0.5 } else { (if (i == 5) { 0.5 } else { (if (i == 6) { 0.46 } else { 0.5 }) }) }) }) }) }) })

	gb_cr : I64 -> F64
	gb_cr = |i| (if (i == 0) { 0.85 } else { (if (i == 1) { 0.9 } else { (if (i == 2) { 0.25 } else { (if (i == 3) { 0.7 } else { (if (i == 4) { 0.35 } else { (if (i == 5) { 0.3 } else { (if (i == 6) { 0.95 } else { 0.9 }) }) }) }) }) }) })

	gb_cg : I64 -> F64
	gb_cg = |i| (if (i == 0) { 0.75 } else { (if (i == 1) { 0.3 } else { (if (i == 2) { 0.8 } else { (if (i == 3) { 0.35 } else { (if (i == 4) { 0.8 } else { (if (i == 5) { 0.45 } else { (if (i == 6) { 0.55 } else { 0.45 }) }) }) }) }) }) })

	gb_cb : I64 -> F64
	gb_cb = |i| (if (i == 0) { 0.45 } else { (if (i == 1) { 0.28 } else { (if (i == 2) { 0.75 } else { (if (i == 3) { 0.9 } else { (if (i == 4) { 0.4 } else { (if (i == 5) { 0.9 } else { (if (i == 6) { 0.3 } else { 0.65 }) }) }) }) }) }) })

	gb_hit : F64, F64, F64, F64, F64, F64, I64 -> F64
	gb_hit = |ox, oy, oz, dx, dy, dz, i| ({
		lx = (ox - gb_cx(i))
		ly = (oy - gb_cy(i))
		lz = (oz - gb_cz(i))
		b = (((dx * lx) + (dy * ly)) + (dz * lz))
		r = gb_rad(i)
		c = ((((lx * lx) + (ly * ly)) + (lz * lz)) - (r * r))
		disc = ((b * b) - c)
		(if (disc < 0.0) { (0.0 - 1.0) } else { ({
			t = ((0.0 - b) - DeviceMath.real_sqrt(disc))
			(if (t > 0.001) { t } else { (0.0 - 1.0) })
		}) })
	})

	gb_nearest : F64, F64, F64, F64, F64, F64, I64, I64, F64 -> I64
	gb_nearest = |ox, oy, oz, dx, dy, dz, i, best_id, best_t| (if (i >= gb_count) { best_id } else { ({
		t = gb_hit(ox, oy, oz, dx, dy, dz, i)
		take = (if (t > 0.001) { (if (best_t < 0.0) { 1 } else { (if (t < best_t) { 1 } else { 0 }) }) } else { 0 })
		(if (take == 1) { gb_nearest(ox, oy, oz, dx, dy, dz, (i + 1), i, t) } else { gb_nearest(ox, oy, oz, dx, dy, dz, (i + 1), best_id, best_t) })
	}) })

	gb_nbyte : F64 -> I64
	gb_nbyte = |n| F64.to_i64_wrap(((n + 1.0) * 127.0))

	gbuf_step : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	gbuf_step = |dev, galb, gnrm, gdep, gid| ({
		px = (gid - (I64.div_trunc_by(gid, gb_width) * gb_width))
		py = I64.div_trunc_by(gid, gb_width)
		fx = (I64.to_f64((px - gb_half_w)) / 384.0)
		fy = (I64.to_f64((gb_half_h - py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 3.24))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (1.8 / rl)
		ox = 0.0
		oy = 0.0
		oz = (0.0 - 5.0)
		id = gb_nearest(ox, oy, oz, dx, dy, dz, 0, (0 - 1), (0.0 - 1.0))
		t = (if (id < 0) { 0.0 } else { gb_hit(ox, oy, oz, dx, dy, dz, id) })
		hx = (ox + (dx * t))
		hy = (oy + (dy * t))
		hz = (oz + (dz * t))
		nx = (if (id < 0) { 0.0 } else { ((hx - gb_cx(id)) / gb_rad(id)) })
		ny = (if (id < 0) { 1.0 } else { ((hy - gb_cy(id)) / gb_rad(id)) })
		nz = (if (id < 0) { 0.0 } else { ((hz - gb_cz(id)) / gb_rad(id)) })
		albv = (if (id < 0) { 0 } else { (((F64.to_i64_wrap((gb_cr(id) * 255.0)) * 65536) + (F64.to_i64_wrap((gb_cg(id) * 255.0)) * 256)) + F64.to_i64_wrap((gb_cb(id) * 255.0))) })
		nrmv = (((gb_nbyte(nx) * 65536) + (gb_nbyte(ny) * 256)) + gb_nbyte(nz))
		depv = (if (id < 0) { gb_miss } else { F64.to_i64_wrap((t * 256.0)) })
		({
			(dev1, _s0) = Device.store(dev, galb, gid, albv)
			(dev2, _s1) = Device.store(dev1, gnrm, gid, nrmv)
			Device.store(dev2, gdep, gid, depv)
		})
	})
}
