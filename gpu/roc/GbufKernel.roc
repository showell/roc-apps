# GbufKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

GbufKernel :: [].{

	gb_width : I32
	gb_width = 1024

	gb_half_w : I32
	gb_half_w = 512

	gb_half_h : I32
	gb_half_h = 384

	gb_count : I32
	gb_count = 8

	gb_miss : I32
	gb_miss = 8000000

	gb_cx : I32 -> F32
	gb_cx = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { 0.95 } else { (if (i == 2) { (0.0 - 0.85) } else { (if (i == 3) { 0.35 } else { (if (i == 4) { (0.0 - 0.45) } else { (if (i == 5) { 0.55 } else { (if (i == 6) { (0.0 - 0.6) } else { 0.15 }) }) }) }) }) }) })

	gb_cy : I32 -> F32
	gb_cy = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { 0.35 } else { (if (i == 2) { 0.25 } else { (if (i == 3) { (0.0 - 0.8) } else { (if (i == 4) { (0.0 - 0.6) } else { (if (i == 5) { 0.75 } else { (if (i == 6) { 0.7 } else { 0.1 }) }) }) }) }) }) })

	gb_cz : I32 -> F32
	gb_cz = |i| (if (i == 0) { 0.0 } else { (if (i == 1) { (0.0 - 0.2) } else { (if (i == 2) { 0.1 } else { (if (i == 3) { 0.2 } else { (if (i == 4) { (0.0 - 0.3) } else { (if (i == 5) { 0.3 } else { (if (i == 6) { (0.0 - 0.1) } else { 0.8 }) }) }) }) }) }) })

	gb_rad : I32 -> F32
	gb_rad = |i| (if (i == 0) { 0.9 } else { (if (i == 1) { 0.62 } else { (if (i == 2) { 0.6 } else { (if (i == 3) { 0.55 } else { (if (i == 4) { 0.5 } else { (if (i == 5) { 0.5 } else { (if (i == 6) { 0.46 } else { 0.5 }) }) }) }) }) }) })

	gb_cr : I32 -> F32
	gb_cr = |i| (if (i == 0) { 0.85 } else { (if (i == 1) { 0.9 } else { (if (i == 2) { 0.25 } else { (if (i == 3) { 0.7 } else { (if (i == 4) { 0.35 } else { (if (i == 5) { 0.3 } else { (if (i == 6) { 0.95 } else { 0.9 }) }) }) }) }) }) })

	gb_cg : I32 -> F32
	gb_cg = |i| (if (i == 0) { 0.75 } else { (if (i == 1) { 0.3 } else { (if (i == 2) { 0.8 } else { (if (i == 3) { 0.35 } else { (if (i == 4) { 0.8 } else { (if (i == 5) { 0.45 } else { (if (i == 6) { 0.55 } else { 0.45 }) }) }) }) }) }) })

	gb_cb : I32 -> F32
	gb_cb = |i| (if (i == 0) { 0.45 } else { (if (i == 1) { 0.28 } else { (if (i == 2) { 0.75 } else { (if (i == 3) { 0.9 } else { (if (i == 4) { 0.4 } else { (if (i == 5) { 0.9 } else { (if (i == 6) { 0.3 } else { 0.65 }) }) }) }) }) }) })

	gb_hit : F32, F32, F32, F32, F32, F32, I32 -> F32
	gb_hit = |ox, oy, oz, dx, dy, dz, i| ({
		lx : F32
		lx = (ox - gb_cx(i))
		ly : F32
		ly = (oy - gb_cy(i))
		lz : F32
		lz = (oz - gb_cz(i))
		b : F32
		b = (((dx * lx) + (dy * ly)) + (dz * lz))
		r : F32
		r = gb_rad(i)
		c : F32
		c = ((((lx * lx) + (ly * ly)) + (lz * lz)) - (r * r))
		disc : F32
		disc = ((b * b) - c)
		(if (disc < 0.0) { (0.0 - 1.0) } else { ({
			t : F32
			t = ((0.0 - b) - DeviceMath.real_sqrt(disc))
			(if (t > 0.001) { t } else { (0.0 - 1.0) })
		}) })
	})

	gb_nearest : F32, F32, F32, F32, F32, F32, I32, I32, F32 -> I32
	gb_nearest = |ox, oy, oz, dx, dy, dz, i, best_id, best_t| (if (i >= gb_count) { best_id } else { ({
		t : F32
		t = gb_hit(ox, oy, oz, dx, dy, dz, i)
		take : I32
		take = (if (t > 0.001) { (if (best_t < 0.0) { 1 } else { (if (t < best_t) { 1 } else { 0 }) }) } else { 0 })
		(if (take == 1) { gb_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), i, t) } else { gb_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), best_id, best_t) })
	}) })

	gb_nbyte : F32 -> I32
	gb_nbyte = |n| F32.to_i32_wrap(((n + 1.0) * 127.0))

	gbuf_step : Device.Device, I32, I32, I32, I32 -> (Device.Device, I32)
	gbuf_step = |dev, galb, gnrm, gdep, gid| ({
		px : I32
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, gb_width), gb_width))
		py : I32
		py = Device.div(gid, gb_width)
		fx : F32
		fx = (I32.to_f32(I32.minus_wrap(px, gb_half_w)) / 384.0)
		fy : F32
		fy = (I32.to_f32(I32.minus_wrap(gb_half_h, py)) / 384.0)
		rl : F32
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 3.24))
		dx : F32
		dx = (fx / rl)
		dy : F32
		dy = (fy / rl)
		dz : F32
		dz = (1.8 / rl)
		ox : F32
		ox = 0.0
		oy : F32
		oy = 0.0
		oz : F32
		oz = (0.0 - 5.0)
		id : I32
		id = gb_nearest(ox, oy, oz, dx, dy, dz, 0, I32.minus_wrap(0, 1), (0.0 - 1.0))
		t : F32
		t = (if (id < 0) { 0.0 } else { gb_hit(ox, oy, oz, dx, dy, dz, id) })
		hx : F32
		hx = (ox + (dx * t))
		hy : F32
		hy = (oy + (dy * t))
		hz : F32
		hz = (oz + (dz * t))
		nx : F32
		nx = (if (id < 0) { 0.0 } else { ((hx - gb_cx(id)) / gb_rad(id)) })
		ny : F32
		ny = (if (id < 0) { 1.0 } else { ((hy - gb_cy(id)) / gb_rad(id)) })
		nz : F32
		nz = (if (id < 0) { 0.0 } else { ((hz - gb_cz(id)) / gb_rad(id)) })
		albv : I32
		albv = (if (id < 0) { 0 } else { I32.plus_wrap(I32.plus_wrap(I32.times_wrap(F32.to_i32_wrap((gb_cr(id) * 255.0)), 65536), I32.times_wrap(F32.to_i32_wrap((gb_cg(id) * 255.0)), 256)), F32.to_i32_wrap((gb_cb(id) * 255.0))) })
		nrmv : I32
		nrmv = I32.plus_wrap(I32.plus_wrap(I32.times_wrap(gb_nbyte(nx), 65536), I32.times_wrap(gb_nbyte(ny), 256)), gb_nbyte(nz))
		depv : I32
		depv = (if (id < 0) { gb_miss } else { F32.to_i32_wrap((t * 256.0)) })
		({
			(dev1, _s0) = Device.store(dev, galb, gid, albv)
			(dev2, _s1) = Device.store(dev1, gnrm, gid, nrmv)
			Device.store(dev2, gdep, gid, depv)
		})
	})
}
