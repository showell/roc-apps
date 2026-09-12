# ParallaxKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

ParallaxKernel :: [].{

	pa_width : I32
	pa_width = 1024

	pa_half_w : I32
	pa_half_w = 512

	pa_half_h : I32
	pa_half_h = 384

	pa_height : F32, F32 -> F32
	pa_height = |u, v| ({
		iv = F32.to_i32_wrap((v / 70.0))
		off = (if (I32.minus_wrap(iv, I32.times_wrap(Device.div(iv, 2), 2)) == 0) { 0.0 } else { 65.0 })
		uu = (u + off)
		iu = F32.to_i32_wrap((uu / 130.0))
		fu = (uu - (I32.to_f32(iu) * 130.0))
		fv = (v - (I32.to_f32(iv) * 70.0))
		du = DeviceMath.real_min(fu, (130.0 - fu))
		dv = DeviceMath.real_min(fv, (70.0 - fv))
		d = DeviceMath.real_min(du, dv)
		DeviceMath.real_min(1.0, DeviceMath.real_max(0.0, ((d - 4.0) / 9.0)))
	})

	pa_clamp01 : F32 -> F32
	pa_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	pa_pack : F32, F32, F32 -> I32
	pa_pack = |r, g, b| ({
		ri = F32.to_i32_wrap((pa_clamp01(r) * 255.0))
		gi = F32.to_i32_wrap((pa_clamp01(g) * 255.0))
		bi = F32.to_i32_wrap((pa_clamp01(b) * 255.0))
		I32.plus_wrap(I32.plus_wrap(I32.times_wrap(ri, 65536), I32.times_wrap(gi, 256)), bi)
	})

	pa_render : I32, I32 -> I32
	pa_render = |gid, frame| ({
		px = I32.to_f32(I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, pa_width), pa_width)))
		py = I32.to_f32(Device.div(gid, pa_width))
		vdx = ((px - I32.to_f32(pa_half_w)) / 850.0)
		vdy = ((py - I32.to_f32(pa_half_h)) / 850.0)
		h0 = pa_height(px, py)
		up = (px + ((vdx * h0) * 36.0))
		vp = (py + ((vdy * h0) * 36.0))
		h = pa_height(up, vp)
		hu1 = pa_height((up + 2.0), vp)
		hu0 = pa_height((up - 2.0), vp)
		hv1 = pa_height(up, (vp + 2.0))
		hv0 = pa_height(up, (vp - 2.0))
		nx = ((hu0 - hu1) * 7.0)
		ny = ((hv0 - hv1) * 7.0)
		nl = DeviceMath.real_sqrt((((nx * nx) + (ny * ny)) + 1.0))
		ux = (nx / nl)
		uy = (ny / nl)
		uz = (1.0 / nl)
		ang = (I32.to_f32(frame) / 28.0)
		lx = (DeviceMath.real_cos(ang) * 0.6)
		ly = (DeviceMath.real_sin(ang) * 0.6)
		lz = 0.62
		ll = DeviceMath.real_sqrt((((lx * lx) + (ly * ly)) + (lz * lz)))
		ndl = DeviceMath.real_max(0.0, ((((ux * lx) / ll) + ((uy * ly) / ll)) + ((uz * lz) / ll)))
		ivp = F32.to_i32_wrap((vp / 70.0))
		offp = (if (I32.minus_wrap(ivp, I32.times_wrap(Device.div(ivp, 2), 2)) == 0) { 0.0 } else { 65.0 })
		iup = F32.to_i32_wrap(((up + offp) / 130.0))
		hue = I32.plus_wrap(I32.times_wrap(iup, 2), I32.times_wrap(ivp, 3))
		hm = I32.minus_wrap(hue, I32.times_wrap(Device.div(hue, 3), 3))
		br = (if (h < 0.25) { 0.34 } else { (0.58 + (I32.to_f32(hm) * 0.06)) })
		bg = (if (h < 0.25) { 0.33 } else { 0.26 })
		bb = (if (h < 0.25) { 0.32 } else { 0.2 })
		sh = (0.22 + (ndl * 0.92))
		pa_pack((br * sh), (bg * sh), (bb * sh))
	})

	parallax_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	parallax_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, pa_render(gid, frame))
	})
}
