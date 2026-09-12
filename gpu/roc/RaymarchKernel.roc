# RaymarchKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

RaymarchKernel :: [].{

	rm_width : I64
	rm_width = 1024

	rm_half_w : I64
	rm_half_w = 512

	rm_half_h : I64
	rm_half_h = 384

	rm_steps : I64
	rm_steps = 80

	rm_sphere : F64, F64, F64 -> F64
	rm_sphere = |px, py, pz| (DeviceMath.real_sqrt((((px * px) + (py * py)) + (pz * pz))) - 1.0)

	rm_scene : F64, F64, F64 -> F64
	rm_scene = |px, py, pz| DeviceMath.real_min(rm_sphere(px, py, pz), (py + 1.1))

	rm_march : F64, F64, F64, F64, F64, F64, F64, I64 -> F64
	rm_march = |ox, oy, oz, dx, dy, dz, t, i| (if (i >= rm_steps) { (0.0 - 1.0) } else { ({
		px = (ox + (dx * t))
		py = (oy + (dy * t))
		pz = (oz + (dz * t))
		d = rm_scene(px, py, pz)
		(if (d < 0.002) { t } else { (if (t > 30.0) { (0.0 - 1.0) } else { rm_march(ox, oy, oz, dx, dy, dz, (t + d), (i + 1)) }) })
	}) })

	rm_clamp01 : F64 -> F64
	rm_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	rm_pack : F64, F64, F64 -> I64
	rm_pack = |r, g, b| ({
		ri = F64.to_i64_wrap((rm_clamp01(r) * 255.0))
		gi = F64.to_i64_wrap((rm_clamp01(g) * 255.0))
		bi = F64.to_i64_wrap((rm_clamp01(b) * 255.0))
		(((ri * 65536) + (gi * 256)) + bi)
	})

	rm_sky : F64 -> I64
	rm_sky = |fy| ({
		h = rm_clamp01(((fy * 0.5) + 0.5))
		rm_pack((0.1 + (h * 0.1)), (0.16 + (h * 0.24)), (0.36 + (h * 0.42)))
	})

	rm_render : I64, I64 -> I64
	rm_render = |gid, frame| ({
		px = (gid - (I64.div_trunc_by(gid, rm_width) * rm_width))
		py = I64.div_trunc_by(gid, rm_width)
		fx = (I64.to_f64((px - rm_half_w)) / 384.0)
		fy = (I64.to_f64((rm_half_h - py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 2.25))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (1.5 / rl)
		oz = (0.0 - 3.5)
		t = rm_march(0.0, 0.0, oz, dx, dy, dz, 0.0, 0)
		(if (t < 0.0) { rm_sky(fy) } else { ({
			hx = (dx * t)
			hy = (dy * t)
			hz = (oz + (dz * t))
			e = 0.002
			nx = (rm_scene((hx + e), hy, hz) - rm_scene((hx - e), hy, hz))
			ny = (rm_scene(hx, (hy + e), hz) - rm_scene(hx, (hy - e), hz))
			nz = (rm_scene(hx, hy, (hz + e)) - rm_scene(hx, hy, (hz - e)))
			nl = (DeviceMath.real_sqrt((((nx * nx) + (ny * ny)) + (nz * nz))) + 0.0001)
			ux = (nx / nl)
			uy = (ny / nl)
			uz = (nz / nl)
			ang = (I64.to_f64(frame) / 24.0)
			ldx = DeviceMath.real_cos(ang)
			ldy = 0.75
			ldz = DeviceMath.real_sin(ang)
			ll = DeviceMath.real_sqrt((((ldx * ldx) + (ldy * ldy)) + (ldz * ldz)))
			diff = DeviceMath.real_max(0.0, ((((ux * ldx) / ll) + ((uy * ldy) / ll)) + ((uz * ldz) / ll)))
			sh = ((diff * 0.85) + 0.15)
			(if (hy < (0.0 - 1.0)) { rm_pack((0.45 * sh), (0.47 * sh), (0.52 * sh)) } else { rm_pack((0.95 * sh), (0.55 * sh), (0.25 * sh)) })
		}) })
	})

	raymarch_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	raymarch_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, rm_render(gid, frame))
	})
}
