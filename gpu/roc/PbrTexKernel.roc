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
		m : I32
		m = I32.minus_wrap(I32.plus_wrap(I32.times_wrap(iu, 3), I32.times_wrap(iv, 5)), I32.times_wrap(Device.div(I32.plus_wrap(I32.times_wrap(iu, 3), I32.times_wrap(iv, 5)), 4), 4))
		(0.45 + (I32.to_f32(m) * 0.12))
	})

	pt_tex_g : I32, I32 -> F32
	pt_tex_g = |iu, iv| ({
		m : I32
		m = I32.minus_wrap(I32.plus_wrap(iu, I32.times_wrap(iv, 2)), I32.times_wrap(Device.div(I32.plus_wrap(iu, I32.times_wrap(iv, 2)), 3), 3))
		(0.4 + (I32.to_f32(m) * 0.16))
	})

	pt_clamp01 : F32 -> F32
	pt_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	pt_pack : F32, F32, F32 -> I32
	pt_pack = |r, g, b| I32.plus_wrap(I32.plus_wrap(I32.times_wrap(F32.to_i32_wrap((pt_clamp01(r) * 255.0)), 65536), I32.times_wrap(F32.to_i32_wrap((pt_clamp01(g) * 255.0)), 256)), F32.to_i32_wrap((pt_clamp01(b) * 255.0)))

	pt_pow5 : F32 -> F32
	pt_pow5 = |x| ({
		x2 : F32
		x2 = (x * x)
		((x2 * x2) * x)
	})

	pt_render : I32, I32 -> I32
	pt_render = |gid, frame| ({
		px : I32
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, pt_width), pt_width))
		py : I32
		py = Device.div(gid, pt_width)
		fx : F32
		fx = (I32.to_f32(I32.minus_wrap(px, pt_half_w)) / 384.0)
		fy : F32
		fy = (I32.to_f32(I32.minus_wrap(pt_half_h, py)) / 384.0)
		rl : F32
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 4.0))
		dx : F32
		dx = (fx / rl)
		dy : F32
		dy = (fy / rl)
		dz : F32
		dz = (2.0 / rl)
		oz : F32
		oz = (0.0 - 4.0)
		b : F32
		b = (dz * oz)
		c : F32
		c = ((oz * oz) - 1.6)
		disc : F32
		disc = ((b * b) - c)
		(if (disc < 0.0) { ({
			h : F32
			h = pt_clamp01(((dy * 0.5) + 0.5))
			pt_pack((0.05 + (h * 0.05)), (0.06 + (h * 0.08)), (0.1 + (h * 0.15)))
		}) } else { ({
			t : F32
			t = ((0.0 - b) - DeviceMath.real_sqrt(disc))
			hx : F32
			hx = (dx * t)
			hy : F32
			hy = (dy * t)
			hz : F32
			hz = (oz + (dz * t))
			nx : F32
			nx = (hx / 1.265)
			ny : F32
			ny = (hy / 1.265)
			nz : F32
			nz = (hz / 1.265)
			spin : F32
			spin = (I32.to_f32(frame) / 40.0)
			u : F32
			u = ((((DeviceMath.real_cos(spin) * nx) + (DeviceMath.real_sin(spin) * nz)) * 0.5) + 0.5)
			v : F32
			v = ((ny * 0.5) + 0.5)
			iu : I32
			iu = F32.to_i32_wrap((u * 12.0))
			iv : I32
			iv = F32.to_i32_wrap((v * 8.0))
			fu : F32
			fu = ((u * 12.0) - I32.to_f32(iu))
			fv : F32
			fv = ((v * 8.0) - I32.to_f32(iv))
			grout : I32
			grout = (if (fu < 0.08) { 1 } else { (if (fv < 0.08) { 1 } else { 0 }) })
			ar : F32
			ar = (if (grout == 1) { 0.14 } else { pt_tex_r(iu, iv) })
			ag : F32
			ag = (if (grout == 1) { 0.14 } else { pt_tex_g(iu, iv) })
			ab : F32
			ab = (if (grout == 1) { 0.16 } else { 0.55 })
			la : F32
			la = (I32.to_f32(frame) / 30.0)
			lx : F32
			lx = (DeviceMath.real_cos(la) * 0.6)
			ly : F32
			ly = 0.7
			lz : F32
			lz = ((DeviceMath.real_sin(la) * 0.6) - 0.3)
			ll : F32
			ll = DeviceMath.real_sqrt((((lx * lx) + (ly * ly)) + (lz * lz)))
			ux : F32
			ux = (lx / ll)
			uy : F32
			uy = (ly / ll)
			uz : F32
			uz = (lz / ll)
			hlx : F32
			hlx = (ux - dx)
			hly : F32
			hly = (uy - dy)
			hlz : F32
			hlz = (uz - dz)
			hl : F32
			hl = (DeviceMath.real_sqrt((((hlx * hlx) + (hly * hly)) + (hlz * hlz))) + 0.001)
			ndh : F32
			ndh = DeviceMath.real_max(0.0, ((((nx * hlx) / hl) + ((ny * hly) / hl)) + ((nz * hlz) / hl)))
			ndl : F32
			ndl = DeviceMath.real_max(0.0, (((nx * ux) + (ny * uy)) + (nz * uz)))
			a2 : F32
			a2 = 0.09
			dd : F32
			dd = (((ndh * ndh) * (a2 - 1.0)) + 1.0)
			spec : F32
			spec = ((a2 / ((dd * dd) + 0.001)) * 0.4)
			sh : F32
			sh = (0.15 + (ndl * 0.85))
			pt_pack(((ar * sh) + spec), ((ag * sh) + spec), ((ab * sh) + spec))
		}) })
	})

	pbrtex_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	pbrtex_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, pt_render(gid, frame))
	})
}
