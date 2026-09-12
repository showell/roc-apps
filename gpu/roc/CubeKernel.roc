# CubeKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

CubeKernel :: [].{

	cu_width : I64
	cu_width = 1024

	cu_half_w : I64
	cu_half_w = 512

	cu_half_h : I64
	cu_half_h = 384

	cu_clamp01 : F64 -> F64
	cu_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	cu_pack : F64, F64, F64 -> I64
	cu_pack = |r, g, b| ({
		ri = F64.to_i64_wrap((cu_clamp01(r) * 255.0))
		gi = F64.to_i64_wrap((cu_clamp01(g) * 255.0))
		bi = F64.to_i64_wrap((cu_clamp01(b) * 255.0))
		(((ri * 65536) + (gi * 256)) + bi)
	})

	cu_bg : I64 -> I64
	cu_bg = |py| ({
		h = (I64.to_f64(py) / 768.0)
		cu_pack((0.04 + (h * 0.05)), (0.05 + (h * 0.08)), (0.09 + (h * 0.16)))
	})

	cu_render : I64, I64 -> I64
	cu_render = |gid, frame| ({
		px = (gid - (I64.div_trunc_by(gid, cu_width) * cu_width))
		py = I64.div_trunc_by(gid, cu_width)
		fx = (I64.to_f64((px - cu_half_w)) / 384.0)
		fy = (I64.to_f64((cu_half_h - py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 2.56))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (1.6 / rl)
		ay = (I64.to_f64(frame) / 34.0)
		ax = (I64.to_f64(frame) / 51.0)
		cy = DeviceMath.real_cos(ay)
		sy = DeviceMath.real_sin(ay)
		cx = DeviceMath.real_cos(ax)
		sx = DeviceMath.real_sin(ax)
		oz0 = (0.0 - 3.4)
		oxa = (oz0 * sy)
		oza = (oz0 * cy)
		oxb = oxa
		oyb = (oza * sx)
		ozb = (oza * cx)
		dxa = ((dx * cy) + (dz * sy))
		dza = ((0.0 - (dx * sy)) + (dz * cy))
		dxb = dxa
		dyb = ((dy * cx) + (dza * sx))
		dzb = ((0.0 - (dy * sx)) + (dza * cx))
		t1x = (((0.0 - 1.0) - oxb) / dxb)
		t2x = ((1.0 - oxb) / dxb)
		nxr = DeviceMath.real_min(t1x, t2x)
		fxr = DeviceMath.real_max(t1x, t2x)
		t1y = (((0.0 - 1.0) - oyb) / dyb)
		t2y = ((1.0 - oyb) / dyb)
		nyr = DeviceMath.real_min(t1y, t2y)
		fyr = DeviceMath.real_max(t1y, t2y)
		t1z = (((0.0 - 1.0) - ozb) / dzb)
		t2z = ((1.0 - ozb) / dzb)
		nzr = DeviceMath.real_min(t1z, t2z)
		fzr = DeviceMath.real_max(t1z, t2z)
		tmin = DeviceMath.real_max(nxr, DeviceMath.real_max(nyr, nzr))
		tmax = DeviceMath.real_min(fxr, DeviceMath.real_min(fyr, fzr))
		(if (tmin > tmax) { cu_bg(py) } else { (if (tmax < 0.001) { cu_bg(py) } else { ({
			nlx = (if ((nxr >= nyr) and (nxr >= nzr)) { (if (dxb > 0.0) { (0.0 - 1.0) } else { 1.0 }) } else { 0.0 })
			nly = (if ((nyr >= nxr) and (nyr >= nzr)) { (if (dyb > 0.0) { (0.0 - 1.0) } else { 1.0 }) } else { 0.0 })
			nlz = (if ((nzr >= nxr) and (nzr >= nyr)) { (if (dzb > 0.0) { (0.0 - 1.0) } else { 1.0 }) } else { 0.0 })
			br = (if (nlx > 0.5) { 0.95 } else { (if (nlx < (0.0 - 0.5)) { 0.85 } else { (if (nly > 0.5) { 0.35 } else { (if (nly < (0.0 - 0.5)) { 0.3 } else { (if (nlz > 0.5) { 0.25 } else { 0.9 }) }) }) }) })
			bg = (if (nlx > 0.5) { 0.35 } else { (if (nlx < (0.0 - 0.5)) { 0.75 } else { (if (nly > 0.5) { 0.85 } else { (if (nly < (0.0 - 0.5)) { 0.55 } else { (if (nlz > 0.5) { 0.55 } else { 0.8 }) }) }) }) })
			bb = (if (nlx > 0.5) { 0.3 } else { (if (nlx < (0.0 - 0.5)) { 0.35 } else { (if (nly > 0.5) { 0.45 } else { (if (nly < (0.0 - 0.5)) { 0.85 } else { (if (nlz > 0.5) { 0.9 } else { 0.3 }) }) }) }) })
			lx = 0.4
			ly = 0.72
			lz = (0.0 - 0.56)
			ndl = DeviceMath.real_max(0.0, (((nlx * lx) + (nly * ly)) + (nlz * lz)))
			sh = (0.25 + (ndl * 0.85))
			cu_pack((br * sh), (bg * sh), (bb * sh))
		}) }) })
	})

	cube_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	cube_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, cu_render(gid, frame))
	})
}
