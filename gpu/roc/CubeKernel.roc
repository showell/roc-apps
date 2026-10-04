# CubeKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

CubeKernel :: [].{

	cu_width : I32
	cu_width = 1024

	cu_half_w : I32
	cu_half_w = 512

	cu_half_h : I32
	cu_half_h = 384

	cu_clamp01 : F32 -> F32
	cu_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	cu_pack : F32, F32, F32 -> I32
	cu_pack = |r, g, b| ({
		ri : I32
		ri = F32.to_i32_wrap((cu_clamp01(r) * 255.0))
		gi : I32
		gi = F32.to_i32_wrap((cu_clamp01(g) * 255.0))
		bi : I32
		bi = F32.to_i32_wrap((cu_clamp01(b) * 255.0))
		I32.plus_wrap(I32.plus_wrap(I32.times_wrap(ri, 65536), I32.times_wrap(gi, 256)), bi)
	})

	cu_bg : I32 -> I32
	cu_bg = |py| ({
		h : F32
		h = (I32.to_f32(py) / 768.0)
		cu_pack((0.04 + (h * 0.05)), (0.05 + (h * 0.08)), (0.09 + (h * 0.16)))
	})

	cu_render : I32, I32 -> I32
	cu_render = |gid, frame| ({
		px : I32
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, cu_width), cu_width))
		py : I32
		py = Device.div(gid, cu_width)
		fx : F32
		fx = (I32.to_f32(I32.minus_wrap(px, cu_half_w)) / 384.0)
		fy : F32
		fy = (I32.to_f32(I32.minus_wrap(cu_half_h, py)) / 384.0)
		rl : F32
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 2.56))
		dx : F32
		dx = (fx / rl)
		dy : F32
		dy = (fy / rl)
		dz : F32
		dz = (1.6 / rl)
		ay : F32
		ay = (I32.to_f32(frame) / 34.0)
		ax : F32
		ax = (I32.to_f32(frame) / 51.0)
		cy : F32
		cy = DeviceMath.real_cos(ay)
		sy : F32
		sy = DeviceMath.real_sin(ay)
		cx : F32
		cx = DeviceMath.real_cos(ax)
		sx : F32
		sx = DeviceMath.real_sin(ax)
		oz0 : F32
		oz0 = (0.0 - 3.4)
		oxa : F32
		oxa = (oz0 * sy)
		oza : F32
		oza = (oz0 * cy)
		oxb : F32
		oxb = oxa
		oyb : F32
		oyb = (oza * sx)
		ozb : F32
		ozb = (oza * cx)
		dxa : F32
		dxa = ((dx * cy) + (dz * sy))
		dza : F32
		dza = ((0.0 - (dx * sy)) + (dz * cy))
		dxb : F32
		dxb = dxa
		dyb : F32
		dyb = ((dy * cx) + (dza * sx))
		dzb : F32
		dzb = ((0.0 - (dy * sx)) + (dza * cx))
		t1x : F32
		t1x = (((0.0 - 1.0) - oxb) / dxb)
		t2x : F32
		t2x = ((1.0 - oxb) / dxb)
		nxr : F32
		nxr = DeviceMath.real_min(t1x, t2x)
		fxr : F32
		fxr = DeviceMath.real_max(t1x, t2x)
		t1y : F32
		t1y = (((0.0 - 1.0) - oyb) / dyb)
		t2y : F32
		t2y = ((1.0 - oyb) / dyb)
		nyr : F32
		nyr = DeviceMath.real_min(t1y, t2y)
		fyr : F32
		fyr = DeviceMath.real_max(t1y, t2y)
		t1z : F32
		t1z = (((0.0 - 1.0) - ozb) / dzb)
		t2z : F32
		t2z = ((1.0 - ozb) / dzb)
		nzr : F32
		nzr = DeviceMath.real_min(t1z, t2z)
		fzr : F32
		fzr = DeviceMath.real_max(t1z, t2z)
		tmin : F32
		tmin = DeviceMath.real_max(nxr, DeviceMath.real_max(nyr, nzr))
		tmax : F32
		tmax = DeviceMath.real_min(fxr, DeviceMath.real_min(fyr, fzr))
		(if (tmin > tmax) { cu_bg(py) } else { (if (tmax < 0.001) { cu_bg(py) } else { ({
			nlx : F32
			nlx = (if ((nxr >= nyr) and (nxr >= nzr)) { (if (dxb > 0.0) { (0.0 - 1.0) } else { 1.0 }) } else { 0.0 })
			nly : F32
			nly = (if ((nyr >= nxr) and (nyr >= nzr)) { (if (dyb > 0.0) { (0.0 - 1.0) } else { 1.0 }) } else { 0.0 })
			nlz : F32
			nlz = (if ((nzr >= nxr) and (nzr >= nyr)) { (if (dzb > 0.0) { (0.0 - 1.0) } else { 1.0 }) } else { 0.0 })
			br : F32
			br = (if (nlx > 0.5) { 0.95 } else { (if (nlx < (0.0 - 0.5)) { 0.85 } else { (if (nly > 0.5) { 0.35 } else { (if (nly < (0.0 - 0.5)) { 0.3 } else { (if (nlz > 0.5) { 0.25 } else { 0.9 }) }) }) }) })
			bg : F32
			bg = (if (nlx > 0.5) { 0.35 } else { (if (nlx < (0.0 - 0.5)) { 0.75 } else { (if (nly > 0.5) { 0.85 } else { (if (nly < (0.0 - 0.5)) { 0.55 } else { (if (nlz > 0.5) { 0.55 } else { 0.8 }) }) }) }) })
			bb : F32
			bb = (if (nlx > 0.5) { 0.3 } else { (if (nlx < (0.0 - 0.5)) { 0.35 } else { (if (nly > 0.5) { 0.45 } else { (if (nly < (0.0 - 0.5)) { 0.85 } else { (if (nlz > 0.5) { 0.9 } else { 0.3 }) }) }) }) })
			lx : F32
			lx = 0.4
			ly : F32
			ly = 0.72
			lz : F32
			lz = (0.0 - 0.56)
			ndl : F32
			ndl = DeviceMath.real_max(0.0, (((nlx * lx) + (nly * ly)) + (nlz * lz)))
			sh : F32
			sh = (0.25 + (ndl * 0.85))
			cu_pack((br * sh), (bg * sh), (bb * sh))
		}) }) })
	})

	cube_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	cube_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, cu_render(gid, frame))
	})
}
