# PbrKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

PbrKernel :: [].{

	pb_width : I32
	pb_width = 1024

	pb_half_w : I32
	pb_half_w = 512

	pb_half_h : I32
	pb_half_h = 384

	pb_count : I32
	pb_count = 7

	pb_cx : I32 -> F32
	pb_cx = |i| ((I32.to_f32(i) * 1.15) - 3.45)

	pb_rough : I32 -> F32
	pb_rough = |i| (0.06 + (I32.to_f32(i) * 0.145))

	pb_rad : F32
	pb_rad = 0.52

	pb_sphere_hit : F32, F32, F32, F32, F32, F32, I32 -> F32
	pb_sphere_hit = |ox, oy, oz, dx, dy, dz, i| ({
		lx = (ox - pb_cx(i))
		ly = oy
		lz = oz
		b = (((dx * lx) + (dy * ly)) + (dz * lz))
		c = ((((lx * lx) + (ly * ly)) + (lz * lz)) - (pb_rad * pb_rad))
		disc = ((b * b) - c)
		(if (disc < 0.0) { (0.0 - 1.0) } else { ({
			t = ((0.0 - b) - DeviceMath.real_sqrt(disc))
			(if (t > 0.001) { t } else { (0.0 - 1.0) })
		}) })
	})

	pb_nearest : F32, F32, F32, F32, F32, F32, I32, I32, F32 -> I32
	pb_nearest = |ox, oy, oz, dx, dy, dz, i, best_id, best_t| (if (i >= pb_count) { best_id } else { ({
		t = pb_sphere_hit(ox, oy, oz, dx, dy, dz, i)
		take = (if (t > 0.001) { (if (best_t < 0.0) { 1 } else { (if (t < best_t) { 1 } else { 0 }) }) } else { 0 })
		(if (take == 1) { pb_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), i, t) } else { pb_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), best_id, best_t) })
	}) })

	pb_clamp01 : F32 -> F32
	pb_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	pb_pow5 : F32 -> F32
	pb_pow5 = |x| ({
		x2 = (x * x)
		((x2 * x2) * x)
	})

	pb_ggx : F32, F32 -> F32
	pb_ggx = |ndh, a| ({
		a2 = (a * a)
		d = (((ndh * ndh) * (a2 - 1.0)) + 1.0)
		(a2 / ((d * d) + 0.0001))
	})

	pb_g1 : F32, F32 -> F32
	pb_g1 = |nx, k| (nx / (((nx * (1.0 - k)) + k) + 0.0001))

	pb_pack : F32, F32, F32 -> I32
	pb_pack = |r, g, b| ({
		ri = F32.to_i32_wrap((pb_clamp01(r) * 255.0))
		gi = F32.to_i32_wrap((pb_clamp01(g) * 255.0))
		bi = F32.to_i32_wrap((pb_clamp01(b) * 255.0))
		I32.plus_wrap(I32.plus_wrap(I32.times_wrap(ri, 65536), I32.times_wrap(gi, 256)), bi)
	})

	pb_bg : I32 -> I32
	pb_bg = |py| ({
		h = (I32.to_f32(py) / 768.0)
		pb_pack((0.03 + (h * 0.05)), (0.04 + (h * 0.06)), (0.06 + (h * 0.1)))
	})

	pb_render : I32, I32 -> I32
	pb_render = |gid, frame| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, pb_width), pb_width))
		py = Device.div(gid, pb_width)
		fx = (I32.to_f32(I32.minus_wrap(px, pb_half_w)) / 384.0)
		fy = (I32.to_f32(I32.minus_wrap(pb_half_h, py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 4.0))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (2.0 / rl)
		ox = 0.0
		oy = 0.0
		oz = (0.0 - 5.0)
		id = pb_nearest(ox, oy, oz, dx, dy, dz, 0, I32.minus_wrap(0, 1), (0.0 - 1.0))
		(if (id < 0) { pb_bg(py) } else { ({
			t = pb_sphere_hit(ox, oy, oz, dx, dy, dz, id)
			hx = (ox + (dx * t))
			hy = (oy + (dy * t))
			hz = (oz + (dz * t))
			nx = ((hx - pb_cx(id)) / pb_rad)
			ny = (hy / pb_rad)
			nz = (hz / pb_rad)
			ang = (I32.to_f32(frame) / 40.0)
			lx0 = ((DeviceMath.real_cos(ang) * 0.5) + 0.3)
			ly0 = 0.7
			lz0 = ((DeviceMath.real_sin(ang) * 0.5) - 0.5)
			ll = DeviceMath.real_sqrt((((lx0 * lx0) + (ly0 * ly0)) + (lz0 * lz0)))
			lx = (lx0 / ll)
			ly = (ly0 / ll)
			lz = (lz0 / ll)
			vx = (0.0 - dx)
			vy = (0.0 - dy)
			vz = (0.0 - dz)
			hlx = (lx + vx)
			hly = (ly + vy)
			hlz = (lz + vz)
			hl = (DeviceMath.real_sqrt((((hlx * hlx) + (hly * hly)) + (hlz * hlz))) + 0.0001)
			hnx = (hlx / hl)
			hny = (hly / hl)
			hnz = (hlz / hl)
			ndl = DeviceMath.real_max(0.0, (((nx * lx) + (ny * ly)) + (nz * lz)))
			ndv = DeviceMath.real_max(0.0, (((nx * vx) + (ny * vy)) + (nz * vz)))
			ndh = DeviceMath.real_max(0.0, (((nx * hnx) + (ny * hny)) + (nz * hnz)))
			vdh = DeviceMath.real_max(0.0, (((vx * hnx) + (vy * hny)) + (vz * hnz)))
			rough = pb_rough(id)
			a = (rough * rough)
			k = (a * 0.5)
			dggx = pb_ggx(ndh, a)
			gsm = (pb_g1(ndv, k) * pb_g1(ndl, k))
			fres = (0.04 + (0.96 * pb_pow5((1.0 - vdh))))
			spec = (((dggx * gsm) * fres) / (((4.0 * ndv) * ndl) + 0.01))
			kd = (1.0 - fres)
			dr = (0.9 * kd)
			dg = (0.72 * kd)
			db = (0.3 * kd)
			sr = (((dr + spec) * ndl) + 0.05)
			sg = (((dg + spec) * ndl) + 0.06)
			sb = (((db + spec) * ndl) + 0.08)
			pb_pack(sr, sg, sb)
		}) })
	})

	pbr_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	pbr_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, pb_render(gid, frame))
	})
}
