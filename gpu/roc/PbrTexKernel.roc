# PbrTexKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

PbrTexKernel :: [].{

	pt_width : I32
	pt_width = 1024

	pt_half_w : I32
	pt_half_w = 512

	pt_half_h : I32
	pt_half_h = 384

	pt_tex_r : I32, I32 -> F32
	pt_tex_r = |iu, iv| ({
		m = I32.minus_wrap(I32.plus_wrap(I32.times_wrap(iu, 3), I32.times_wrap(iv, 5)), I32.times_wrap(Device.div(I32.plus_wrap(I32.times_wrap(iu, 3), I32.times_wrap(iv, 5)), 4), 4))
		(0.45 + (I32.to_f32(m) * 0.12))
	})

	pt_tex_g : I32, I32 -> F32
	pt_tex_g = |iu, iv| ({
		m = I32.minus_wrap(I32.plus_wrap(iu, I32.times_wrap(iv, 2)), I32.times_wrap(Device.div(I32.plus_wrap(iu, I32.times_wrap(iv, 2)), 3), 3))
		(0.4 + (I32.to_f32(m) * 0.16))
	})

	pt_clamp01 : F32 -> F32
	pt_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	pt_pack : F32, F32, F32 -> I32
	pt_pack = |r, g, b| I32.plus_wrap(I32.plus_wrap(I32.times_wrap(F32.to_i32_wrap((pt_clamp01(r) * 255.0)), 65536), I32.times_wrap(F32.to_i32_wrap((pt_clamp01(g) * 255.0)), 256)), F32.to_i32_wrap((pt_clamp01(b) * 255.0)))

	pt_pow5 : F32 -> F32
	pt_pow5 = |x| ({
		x2 = (x * x)
		((x2 * x2) * x)
	})

	pt_render : I32, I32 -> I32
	pt_render = |gid, frame| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, pt_width), pt_width))
		py = Device.div(gid, pt_width)
		fx = (I32.to_f32(I32.minus_wrap(px, pt_half_w)) / 384.0)
		fy = (I32.to_f32(I32.minus_wrap(pt_half_h, py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 4.0))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (2.0 / rl)
		oz = (0.0 - 4.0)
		b = (dz * oz)
		c = ((oz * oz) - 1.6)
		disc = ((b * b) - c)
		(if (disc < 0.0) { ({
			h = pt_clamp01(((dy * 0.5) + 0.5))
			pt_pack((0.05 + (h * 0.05)), (0.06 + (h * 0.08)), (0.1 + (h * 0.15)))
		}) } else { ({
			t = ((0.0 - b) - DeviceMath.real_sqrt(disc))
			hx = (dx * t)
			hy = (dy * t)
			hz = (oz + (dz * t))
			nx = (hx / 1.265)
			ny = (hy / 1.265)
			nz = (hz / 1.265)
			spin = (I32.to_f32(frame) / 40.0)
			u = ((((DeviceMath.real_cos(spin) * nx) + (DeviceMath.real_sin(spin) * nz)) * 0.5) + 0.5)
			v = ((ny * 0.5) + 0.5)
			iu = F32.to_i32_wrap((u * 12.0))
			iv = F32.to_i32_wrap((v * 8.0))
			fu = ((u * 12.0) - I32.to_f32(iu))
			fv = ((v * 8.0) - I32.to_f32(iv))
			grout = (if (fu < 0.08) { 1 } else { (if (fv < 0.08) { 1 } else { 0 }) })
			ar = (if (grout == 1) { 0.14 } else { pt_tex_r(iu, iv) })
			ag = (if (grout == 1) { 0.14 } else { pt_tex_g(iu, iv) })
			ab = (if (grout == 1) { 0.16 } else { 0.55 })
			la = (I32.to_f32(frame) / 30.0)
			lx = (DeviceMath.real_cos(la) * 0.6)
			ly = 0.7
			lz = ((DeviceMath.real_sin(la) * 0.6) - 0.3)
			ll = DeviceMath.real_sqrt((((lx * lx) + (ly * ly)) + (lz * lz)))
			ux = (lx / ll)
			uy = (ly / ll)
			uz = (lz / ll)
			hlx = (ux - dx)
			hly = (uy - dy)
			hlz = (uz - dz)
			hl = (DeviceMath.real_sqrt((((hlx * hlx) + (hly * hly)) + (hlz * hlz))) + 0.001)
			ndh = DeviceMath.real_max(0.0, ((((nx * hlx) / hl) + ((ny * hly) / hl)) + ((nz * hlz) / hl)))
			ndl = DeviceMath.real_max(0.0, (((nx * ux) + (ny * uy)) + (nz * uz)))
			a2 = 0.09
			dd = (((ndh * ndh) * (a2 - 1.0)) + 1.0)
			spec = ((a2 / ((dd * dd) + 0.001)) * 0.4)
			sh = (0.15 + (ndl * 0.85))
			pt_pack(((ar * sh) + spec), ((ag * sh) + spec), ((ab * sh) + spec))
		}) })
	})

	pbrtex_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	pbrtex_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, pt_render(gid, frame))
	})
}
