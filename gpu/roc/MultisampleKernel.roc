# MultisampleKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

MultisampleKernel :: [].{

	ms_width : I64
	ms_width = 1024

	ms_half_w : I64
	ms_half_w = 512

	ms_half_h : I64
	ms_half_h = 384

	ms_ring : F64, F64, F64 -> F64
	ms_ring = |cx, cy, phase| ({
		r2 = ((cx * cx) + (cy * cy))
		(if (DeviceMath.real_sin(((r2 * 0.0009) + phase)) > 0.0) { 1.0 } else { 0.0 })
	})

	ms_super : F64, F64, F64, I64, F64 -> F64
	ms_super = |cx, cy, phase, s, acc| (if (s >= 16) { acc } else { ({
		sxi = (s - (I64.div_trunc_by(s, 4) * 4))
		syi = I64.div_trunc_by(s, 4)
		ddx = ((I64.to_f64(sxi) * 0.25) - 0.375)
		ddy = ((I64.to_f64(syi) * 0.25) - 0.375)
		ms_super(cx, cy, phase, (s + 1), (acc + ms_ring((cx + ddx), (cy + ddy), phase)))
	}) })

	ms_render : I64, I64 -> I64
	ms_render = |gid, frame| ({
		px = (gid - (I64.div_trunc_by(gid, ms_width) * ms_width))
		py = I64.div_trunc_by(gid, ms_width)
		cx = I64.to_f64((px - ms_half_w))
		cy = I64.to_f64((py - ms_half_h))
		phase = (I64.to_f64(frame) / 20.0)
		v = (if (px < ms_half_w) { ms_ring(cx, cy, phase) } else { (ms_super(cx, cy, phase, 0, 0.0) / 16.0) })
		edge = (if ((px > (ms_half_w - 2)) and (px < (ms_half_w + 2))) { 1 } else { 0 })
		(if (edge == 1) { (((40 * 65536) + (90 * 256)) + 130) } else { ({
			tint_r = (if (px < ms_half_w) { 0.75 } else { 0.55 })
			tint_g = (if (px < ms_half_w) { 0.6 } else { 0.8 })
			tint_b = 0.9
			ir = F64.to_i64_wrap(((v * tint_r) * 255.0))
			ig = F64.to_i64_wrap(((v * tint_g) * 255.0))
			ib = F64.to_i64_wrap(((v * tint_b) * 255.0))
			(((ir * 65536) + (ig * 256)) + ib)
		}) })
	})

	multisample_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	multisample_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, ms_render(gid, frame))
	})
}
