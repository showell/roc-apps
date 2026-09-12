# PbrTexKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

PbrTexKernel :: [].{

	pt_width : I64
	pt_width = 1024

	pt_half_w : I64
	pt_half_w = 512

	pt_half_h : I64
	pt_half_h = 384

	pt_tex_r : I64, I64 -> F64
	pt_tex_r = |iu, iv| ({
		m = (((iu * 3) + (iv * 5)) - (I64.div_trunc_by(((iu * 3) + (iv * 5)), 4) * 4))
		(0.45 + (I64.to_f64(m) * 0.12))
	})

	pt_tex_g : I64, I64 -> F64
	pt_tex_g = |iu, iv| ({
		m = ((iu + (iv * 2)) - (I64.div_trunc_by((iu + (iv * 2)), 3) * 3))
		(0.4 + (I64.to_f64(m) * 0.16))
	})

	pt_clamp01 : F64 -> F64
	pt_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	pt_pack : F64, F64, F64 -> I64
	pt_pack = |r, g, b| (((F64.to_i64_wrap((pt_clamp01(r) * 255.0)) * 65536) + (F64.to_i64_wrap((pt_clamp01(g) * 255.0)) * 256)) + F64.to_i64_wrap((pt_clamp01(b) * 255.0)))

	pt_pow5 : F64 -> F64
	pt_pow5 = |x| ({
		x2 = (x * x)
		((x2 * x2) * x)
	})

	pt_render : I64, I64 -> I64
	pt_render = |gid, frame| ({
		px = (gid - (I64.div_trunc_by(gid, pt_width) * pt_width))
		py = I64.div_trunc_by(gid, pt_width)
		fx = (I64.to_f64((px - pt_half_w)) / 384.0)
		fy = (I64.to_f64((pt_half_h - py)) / 384.0)
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
			spin = (I64.to_f64(frame) / 40.0)
			u = ((((DeviceMath.real_cos(spin) * nx) + (DeviceMath.real_sin(spin) * nz)) * 0.5) + 0.5)
			v = ((ny * 0.5) + 0.5)
			iu = F64.to_i64_wrap((u * 12.0))
			iv = F64.to_i64_wrap((v * 8.0))
			fu = ((u * 12.0) - I64.to_f64(iu))
			fv = ((v * 8.0) - I64.to_f64(iv))
			grout = (if (fu < 0.08) { 1 } else { (if (fv < 0.08) { 1 } else { 0 }) })
			ar = (if (grout == 1) { 0.14 } else { pt_tex_r(iu, iv) })
			ag = (if (grout == 1) { 0.14 } else { pt_tex_g(iu, iv) })
			ab = (if (grout == 1) { 0.16 } else { 0.55 })
			la = (I64.to_f64(frame) / 30.0)
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

	pbrtex_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	pbrtex_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, pt_render(gid, frame))
	})
}
