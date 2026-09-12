# D20Kernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

D20Kernel :: [].{

	d2_width : I64
	d2_width = 1024

	d2_half_w : I64
	d2_half_w = 512

	d2_half_h : I64
	d2_half_h = 384

	d2_tris : I64
	d2_tris = 20

	d2_mt : F64, F64, F64, F64, F64, F64, F64, F64, F64, F64, F64, F64, F64, F64, F64 -> F64
	d2_mt = |ox, oy, oz, dx, dy, dz, v0x, v0y, v0z, v1x, v1y, v1z, v2x, v2y, v2z| ({
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

	d2_nearest : Device.Device, I64, F64, F64, F64, F64, F64, F64, I64, I64, F64 -> (Device.Device, I64)
	d2_nearest = |dev, buf, ox, oy, oz, dx, dy, dz, i, best_id, best_t| (if (i >= d2_tris) { (dev, best_id) } else { ({
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
			t = d2_mt(ox, oy, oz, dx, dy, dz, (I64.to_f64(a0) / 1024.0), (I64.to_f64(a1) / 1024.0), (I64.to_f64(a2) / 1024.0), (I64.to_f64(b0) / 1024.0), (I64.to_f64(b1) / 1024.0), (I64.to_f64(b2) / 1024.0), (I64.to_f64(c0) / 1024.0), (I64.to_f64(c1) / 1024.0), (I64.to_f64(c2) / 1024.0))
			take = (if (t > 0.001) { (if (best_t < 0.0) { 1 } else { (if (t < best_t) { 1 } else { 0 }) }) } else { 0 })
			nid = (if (take == 1) { i } else { best_id })
			nt = (if (take == 1) { t } else { best_t })
			d2_nearest(dev9, buf, ox, oy, oz, dx, dy, dz, (i + 1), nid, nt)
		})
	}) })

	d2_glyph : I64 -> I64
	d2_glyph = |d| (if (d == 0) { 31599 } else { (if (d == 1) { 11415 } else { (if (d == 2) { 29671 } else { (if (d == 3) { 29647 } else { (if (d == 4) { 23497 } else { (if (d == 5) { 31183 } else { (if (d == 6) { 31215 } else { (if (d == 7) { 29266 } else { (if (d == 8) { 31727 } else { 31695 }) }) }) }) }) }) }) }) })

	d2_glyph_on : I64, I64, I64 -> I64
	d2_glyph_on = |d, col, row| (if (col < 0) { 0 } else { (if (col > 2) { 0 } else { (if (row < 0) { 0 } else { (if (row > 4) { 0 } else { ({
		g = d2_glyph(d)
		rowval = (I64.div_trunc_by(g, d2_pow8((4 - row))) - (I64.div_trunc_by(g, d2_pow8((5 - row))) * 8))
		bit = (I64.div_trunc_by(rowval, d2_pow2((2 - col))) - (I64.div_trunc_by(rowval, d2_pow2((3 - col))) * 2))
		bit
	}) }) }) }) })

	d2_pow8 : I64 -> I64
	d2_pow8 = |n| (if (n <= 0) { 1 } else { (if (n == 1) { 8 } else { (if (n == 2) { 64 } else { (if (n == 3) { 512 } else { (if (n == 4) { 4096 } else { 32768 }) }) }) }) })

	d2_pow2 : I64 -> I64
	d2_pow2 = |n| (if (n <= 0) { 1 } else { (if (n == 1) { 2 } else { (if (n == 2) { 4 } else { 8 }) }) })

	d2_on_number : I64, F64, F64 -> I64
	d2_on_number = |id, qx, qy| ({
		m = (id + 1)
		nd = (if (m < 10) { 1 } else { 2 })
		gw = 0.115
		tw = (I64.to_f64(nd) * gw)
		th = 0.21
		tx = ((qx + (tw * 0.5)) / tw)
		ty = (((th * 0.5) - qy) / th)
		(if (tx < 0.0) { 0 } else { (if (tx > 1.0) { 0 } else { (if (ty < 0.0) { 0 } else { (if (ty > 1.0) { 0 } else { ({
			totalcols = (nd * 3)
			gcol = F64.to_i64_wrap((tx * I64.to_f64(totalcols)))
			cell = I64.div_trunc_by(gcol, 3)
			col = (gcol - (cell * 3))
			row = F64.to_i64_wrap((ty * 5.0))
			digit = (if (nd == 1) { m } else { (if (cell == 0) { I64.div_trunc_by(m, 10) } else { (m - (I64.div_trunc_by(m, 10) * 10)) }) })
			d2_glyph_on(digit, col, row)
		}) }) }) }) })
	})

	d2_clamp01 : F64 -> F64
	d2_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	d2_pack : F64, F64, F64 -> I64
	d2_pack = |r, g, b| ({
		ri = F64.to_i64_wrap((d2_clamp01(r) * 255.0))
		gi = F64.to_i64_wrap((d2_clamp01(g) * 255.0))
		bi = F64.to_i64_wrap((d2_clamp01(b) * 255.0))
		(((ri * 65536) + (gi * 256)) + bi)
	})

	d2_bg : I64 -> I64
	d2_bg = |py| ({
		h = (I64.to_f64(py) / 768.0)
		d2_pack((0.03 + (h * 0.04)), (0.03 + (h * 0.05)), (0.05 + (h * 0.09)))
	})

	d20_step : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	d20_step = |dev, meshbuf, outb, frame, gid| ({
		px = (gid - (I64.div_trunc_by(gid, d2_width) * d2_width))
		py = I64.div_trunc_by(gid, d2_width)
		fx = (I64.to_f64((px - d2_half_w)) / 384.0)
		fy = (I64.to_f64((d2_half_h - py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 2.56))
		dx0 = (fx / rl)
		dy0 = (fy / rl)
		dz0 = (1.6 / rl)
		ay = (I64.to_f64(frame) / 46.0)
		ax = (I64.to_f64(frame) / 71.0)
		cyv = DeviceMath.real_cos(ay)
		syv = DeviceMath.real_sin(ay)
		cxv = DeviceMath.real_cos(ax)
		sxv = DeviceMath.real_sin(ax)
		oz0 = (0.0 - 3.2)
		ox = (oz0 * syv)
		oza = (oz0 * cyv)
		oy = (oza * sxv)
		oz = (oza * cxv)
		dxa = ((dx0 * cyv) + (dz0 * syv))
		dza = ((0.0 - (dx0 * syv)) + (dz0 * cyv))
		dx = dxa
		dy = ((dy0 * cxv) + (dza * sxv))
		dz = ((0.0 - (dy0 * sxv)) + (dza * cxv))
		({
			(dev1, id) = d2_nearest(dev, meshbuf, ox, oy, oz, dx, dy, dz, 0, (0 - 1), (0.0 - 1.0))
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
						v1x = (I64.to_f64(b0) / 1024.0)
						v1y = (I64.to_f64(b1) / 1024.0)
						v1z = (I64.to_f64(b2) / 1024.0)
						v2x = (I64.to_f64(c0) / 1024.0)
						v2y = (I64.to_f64(c1) / 1024.0)
						v2z = (I64.to_f64(c2) / 1024.0)
						e1x = (v1x - v0x)
						e1y = (v1y - v0y)
						e1z = (v1z - v0z)
						e2x = (v2x - v0x)
						e2y = (v2y - v0y)
						e2z = (v2z - v0z)
						nx0 = ((e1y * e2z) - (e1z * e2y))
						ny0 = ((e1z * e2x) - (e1x * e2z))
						nz0 = ((e1x * e2y) - (e1y * e2x))
						nl = (DeviceMath.real_sqrt((((nx0 * nx0) + (ny0 * ny0)) + (nz0 * nz0))) + F64.from_bits(4532020583610935537))
						nx = (nx0 / nl)
						ny = (ny0 / nl)
						nz = (nz0 / nl)
						t = d2_mt(ox, oy, oz, dx, dy, dz, v0x, v0y, v0z, v1x, v1y, v1z, v2x, v2y, v2z)
						hx = (ox + (dx * t))
						hy = (oy + (dy * t))
						hz = (oz + (dz * t))
						d00 = (((e1x * e1x) + (e1y * e1y)) + (e1z * e1z))
						d01 = (((e1x * e2x) + (e1y * e2y)) + (e1z * e2z))
						d11 = (((e2x * e2x) + (e2y * e2y)) + (e2z * e2z))
						vpx = (hx - v0x)
						vpy = (hy - v0y)
						vpz = (hz - v0z)
						d20 = (((vpx * e1x) + (vpy * e1y)) + (vpz * e1z))
						d21 = (((vpx * e2x) + (vpy * e2y)) + (vpz * e2z))
						denom = (((d00 * d11) - (d01 * d01)) + F64.from_bits(4532020583610935537))
						bv = (((d11 * d20) - (d01 * d21)) / denom)
						bw = (((d00 * d21) - (d01 * d20)) / denom)
						bu = ((1.0 - bv) - bw)
						qx = ((bv * (0.0 - 0.54)) + (bw * 0.54))
						qy = (((bu * 0.62) + (bv * (0.0 - 0.31))) + (bw * (0.0 - 0.31)))
						onnum = d2_on_number(safe, qx, qy)
						ndl = (((nx * 0.35) + (ny * 0.72)) + (nz * (0.0 - 0.6)))
						lit = (0.24 + ((if (ndl < 0.0) { (0.0 - ndl) } else { ndl }) * 0.82))
						facer = (0.72 * lit)
						faceg = (0.1 * lit)
						faceb = (0.12 * lit)
						numv = (0.55 + (lit * 0.5))
						out = (if (id < 0) { d2_bg(py) } else { (if (onnum == 1) { d2_pack(numv, numv, numv) } else { d2_pack(facer, faceg, faceb) }) })
						Device.store(dev10, outb, gid, out)
					})
				})
			})
		})
	})
}
