# GltfKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

GltfKernel :: [].{

	gl_width : I64
	gl_width = 1024

	gl_half_w : I64
	gl_half_w = 512

	gl_half_h : I64
	gl_half_h = 384

	gl_tris : I64
	gl_tris = 20

	gl_mt : F64, F64, F64, F64, F64, F64, F64, F64, F64, F64, F64, F64, F64, F64, F64 -> F64
	gl_mt = |ox, oy, oz, dx, dy, dz, v0x, v0y, v0z, v1x, v1y, v1z, v2x, v2y, v2z| ({
		e1x = (v1x - v0x)
		e1y = (v1y - v0y)
		e1z = (v1z - v0z)
		e2x = (v2x - v0x)
		e2y = (v2y - v0y)
		e2z = (v2z - v0z)
		pvx = ((dy * e2z) - (dz * e2y))
		pvy = ((dz * e2x) - (dx * e2z))
		pvz = ((dx * e2y) - (dy * e2x))
		det = (((e1x * pvx) + (e1y * pvy)) + (e1z * pvz))
		adet = (if (det < 0.0) { (0.0 - det) } else { det })
		(if (adet < F64.from_bits(4532020583610935537)) { (0.0 - 1.0) } else { ({
			inv = (1.0 / det)
			tvx = (ox - v0x)
			tvy = (oy - v0y)
			tvz = (oz - v0z)
			u = ((((tvx * pvx) + (tvy * pvy)) + (tvz * pvz)) * inv)
			(if (u < 0.0) { (0.0 - 1.0) } else { (if (u > 1.0) { (0.0 - 1.0) } else { ({
				qvx = ((tvy * e1z) - (tvz * e1y))
				qvy = ((tvz * e1x) - (tvx * e1z))
				qvz = ((tvx * e1y) - (tvy * e1x))
				vv = ((((dx * qvx) + (dy * qvy)) + (dz * qvz)) * inv)
				(if (vv < 0.0) { (0.0 - 1.0) } else { (if ((u + vv) > 1.0) { (0.0 - 1.0) } else { ({
					t = ((((e2x * qvx) + (e2y * qvy)) + (e2z * qvz)) * inv)
					(if (t > 0.001) { t } else { (0.0 - 1.0) })
				}) }) })
			}) }) })
		}) })
	})

	gl_nearest : Device.Device, I64, F64, F64, F64, F64, F64, F64, I64, I64, F64 -> (Device.Device, I64)
	gl_nearest = |dev, buf, ox, oy, oz, dx, dy, dz, i, best_id, best_t| (if (i >= gl_tris) { (dev, best_id) } else { ({
		(dev1, a0) = Device.load(dev, buf, (i * 9))
		(dev2, a1) = Device.load(dev1, buf, ((i * 9) + 1))
		(dev3, a2) = Device.load(dev2, buf, ((i * 9) + 2))
		(dev4, b0) = Device.load(dev3, buf, ((i * 9) + 3))
		(dev5, b1) = Device.load(dev4, buf, ((i * 9) + 4))
		(dev6, b2) = Device.load(dev5, buf, ((i * 9) + 5))
		(dev7, c0) = Device.load(dev6, buf, ((i * 9) + 6))
		(dev8, c1) = Device.load(dev7, buf, ((i * 9) + 7))
		(dev9, c2) = Device.load(dev8, buf, ((i * 9) + 8))
		({
			t = gl_mt(ox, oy, oz, dx, dy, dz, (I64.to_f64(a0) / 1024.0), (I64.to_f64(a1) / 1024.0), (I64.to_f64(a2) / 1024.0), (I64.to_f64(b0) / 1024.0), (I64.to_f64(b1) / 1024.0), (I64.to_f64(b2) / 1024.0), (I64.to_f64(c0) / 1024.0), (I64.to_f64(c1) / 1024.0), (I64.to_f64(c2) / 1024.0))
			take = (if (t > 0.001) { (if (best_t < 0.0) { 1 } else { (if (t < best_t) { 1 } else { 0 }) }) } else { 0 })
			nid = (if (take == 1) { i } else { best_id })
			nt = (if (take == 1) { t } else { best_t })
			gl_nearest(dev9, buf, ox, oy, oz, dx, dy, dz, (i + 1), nid, nt)
		})
	}) })

	gl_clamp01 : F64 -> F64
	gl_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	gl_pack : F64, F64, F64 -> I64
	gl_pack = |r, g, b| ({
		ri = F64.to_i64_wrap((gl_clamp01(r) * 255.0))
		gi = F64.to_i64_wrap((gl_clamp01(g) * 255.0))
		bi = F64.to_i64_wrap((gl_clamp01(b) * 255.0))
		(((ri * 65536) + (gi * 256)) + bi)
	})

	gl_bg : I64 -> I64
	gl_bg = |py| ({
		h = (I64.to_f64(py) / 768.0)
		gl_pack((0.04 + (h * 0.05)), (0.05 + (h * 0.09)), (0.09 + (h * 0.15)))
	})

	gl_col_r : I64 -> F64
	gl_col_r = |i| (0.45 + (I64.to_f64((i - (I64.div_trunc_by(i, 6) * 6))) * 0.09))

	gl_col_g : I64 -> F64
	gl_col_g = |i| (0.85 - (I64.to_f64((i - (I64.div_trunc_by(i, 5) * 5))) * 0.08))

	gl_col_b : I64 -> F64
	gl_col_b = |i| (0.55 + (I64.to_f64((i - (I64.div_trunc_by(i, 4) * 4))) * 0.1))

	gltf_step : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	gltf_step = |dev, meshbuf, outb, frame, gid| ({
		px = (gid - (I64.div_trunc_by(gid, gl_width) * gl_width))
		py = I64.div_trunc_by(gid, gl_width)
		fx = (I64.to_f64((px - gl_half_w)) / 384.0)
		fy = (I64.to_f64((gl_half_h - py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 2.56))
		dx0 = (fx / rl)
		dy0 = (fy / rl)
		dz0 = (1.6 / rl)
		ay = (I64.to_f64(frame) / 38.0)
		ax = (I64.to_f64(frame) / 57.0)
		cy = DeviceMath.real_cos(ay)
		sy = DeviceMath.real_sin(ay)
		cx = DeviceMath.real_cos(ax)
		sx = DeviceMath.real_sin(ax)
		oz0 = (0.0 - 3.2)
		oxa = (oz0 * sy)
		oza = (oz0 * cy)
		ox = oxa
		oy = (oza * sx)
		oz = (oza * cx)
		dxa = ((dx0 * cy) + (dz0 * sy))
		dza = ((0.0 - (dx0 * sy)) + (dz0 * cy))
		dx = dxa
		dy = ((dy0 * cx) + (dza * sx))
		dz = ((0.0 - (dy0 * sx)) + (dza * cx))
		({
			(dev1, id) = gl_nearest(dev, meshbuf, ox, oy, oz, dx, dy, dz, 0, (0 - 1), (0.0 - 1.0))
			({
				safe = (if (id < 0) { 0 } else { id })
				({
					(dev2, a0) = Device.load(dev1, meshbuf, (safe * 9))
					(dev3, a1) = Device.load(dev2, meshbuf, ((safe * 9) + 1))
					(dev4, a2) = Device.load(dev3, meshbuf, ((safe * 9) + 2))
					(dev5, b0) = Device.load(dev4, meshbuf, ((safe * 9) + 3))
					(dev6, b1) = Device.load(dev5, meshbuf, ((safe * 9) + 4))
					(dev7, b2) = Device.load(dev6, meshbuf, ((safe * 9) + 5))
					(dev8, c0) = Device.load(dev7, meshbuf, ((safe * 9) + 6))
					(dev9, c1) = Device.load(dev8, meshbuf, ((safe * 9) + 7))
					(dev10, c2) = Device.load(dev9, meshbuf, ((safe * 9) + 8))
					({
						v0x = (I64.to_f64(a0) / 1024.0)
						v0y = (I64.to_f64(a1) / 1024.0)
						v0z = (I64.to_f64(a2) / 1024.0)
						e1x = ((I64.to_f64(b0) / 1024.0) - v0x)
						e1y = ((I64.to_f64(b1) / 1024.0) - v0y)
						e1z = ((I64.to_f64(b2) / 1024.0) - v0z)
						e2x = ((I64.to_f64(c0) / 1024.0) - v0x)
						e2y = ((I64.to_f64(c1) / 1024.0) - v0y)
						e2z = ((I64.to_f64(c2) / 1024.0) - v0z)
						nx0 = ((e1y * e2z) - (e1z * e2y))
						ny0 = ((e1z * e2x) - (e1x * e2z))
						nz0 = ((e1x * e2y) - (e1y * e2x))
						nl = (DeviceMath.real_sqrt((((nx0 * nx0) + (ny0 * ny0)) + (nz0 * nz0))) + F64.from_bits(4532020583610935537))
						nx = (nx0 / nl)
						ny = (ny0 / nl)
						nz = (nz0 / nl)
						ndl = (((nx * 0.35) + (ny * 0.72)) + (nz * (0.0 - 0.6)))
						lit = (0.2 + ((if (ndl < 0.0) { (0.0 - ndl) } else { ndl }) * 0.85))
						out = (if (id < 0) { gl_bg(py) } else { gl_pack((gl_col_r(id) * lit), (gl_col_g(id) * lit), (gl_col_b(id) * lit)) })
						Device.store(dev10, outb, gid, out)
					})
				})
			})
		})
	})
}
