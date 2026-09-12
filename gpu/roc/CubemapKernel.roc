# CubemapKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

CubemapKernel :: [].{

	cm_width : I64
	cm_width = 1024

	cm_half_w : I64
	cm_half_w = 512

	cm_half_h : I64
	cm_half_h = 384

	cm_clamp01 : F64 -> F64
	cm_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	cm_pack : F64, F64, F64 -> I64
	cm_pack = |r, g, b| (((F64.to_i64_wrap((cm_clamp01(r) * 255.0)) * 65536) + (F64.to_i64_wrap((cm_clamp01(g) * 255.0)) * 256)) + F64.to_i64_wrap((cm_clamp01(b) * 255.0)))

	cm_noise : F64, F64 -> F64
	cm_noise = |x, z| (((DeviceMath.real_sin((x * 0.9)) * DeviceMath.real_cos((z * 0.8))) + ((DeviceMath.real_sin(((x * 1.9) + 1.3)) * DeviceMath.real_cos((z * 2.1))) * 0.5)) + (DeviceMath.real_sin(((x * 3.3) - (z * 1.4))) * 0.25))

	cm_cloud : F64, F64, F64, I64 -> F64
	cm_cloud = |dx, dz, dy, frame| ({
		t = (1.3 / dy)
		cx = (((dx * t) * 1.4) + (I64.to_f64(frame) / 42.0))
		cz = ((dz * t) * 1.4)
		n = cm_noise(cx, cz)
		(cm_clamp01(((n - 0.12) * 1.3)) * cm_clamp01((dy * 5.0)))
	})

	cm_sun : F64 -> F64
	cm_sun = |d| (if (d <= 0.0) { 0.0 } else { ({
		d2 = (d * d)
		d4 = (d2 * d2)
		(((d4 * d4) * d4) * d2)
	}) })

	cm_render : I64, I64 -> I64
	cm_render = |gid, frame| ({
		px = (gid - (I64.div_trunc_by(gid, cm_width) * cm_width))
		py = I64.div_trunc_by(gid, cm_width)
		fx = (I64.to_f64((px - cm_half_w)) / 512.0)
		fy = (I64.to_f64((cm_half_h - py)) / 384.0)
		yaw = (I64.to_f64(frame) / 60.0)
		ca = DeviceMath.real_cos(yaw)
		sa = DeviceMath.real_sin(yaw)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 1.0))
		dx0 = (fx / rl)
		dy = (fy / rl)
		dz0 = (1.0 / rl)
		dx = ((dx0 * ca) + (dz0 * sa))
		dz = ((0.0 - (dx0 * sa)) + (dz0 * ca))
		sund = (((dx * 0.42) + (dy * 0.34)) - (dz * 0.84))
		glow = (cm_sun(sund) * 0.7)
		disk = (if (sund > 0.9965) { 1.6 } else { 0.0 })
		(if (dy < (0.0 - 0.02)) { cm_pack((0.1 - (dy * 0.05)), (0.09 - (dy * 0.04)), 0.08) } else { ({
			cloudv = (if (dy > 0.03) { cm_cloud(dx, dz, dy, frame) } else { 0.0 })
			base_r = (0.3 + (dy * 0.1))
			base_g = (0.5 + (dy * 0.3))
			base_b = (0.82 + (dy * 0.15))
			skr = ((base_r + (glow * 0.9)) + disk)
			skg = ((base_g + (glow * 0.78)) + disk)
			skb = ((base_b + (glow * 0.45)) + disk)
			cm_pack(((skr * (1.0 - cloudv)) + cloudv), ((skg * (1.0 - cloudv)) + cloudv), ((skb * (1.0 - cloudv)) + cloudv))
		}) })
	})

	cubemap_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	cubemap_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, cm_render(gid, frame))
	})
}
