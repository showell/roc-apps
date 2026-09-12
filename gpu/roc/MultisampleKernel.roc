# MultisampleKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

MultisampleKernel :: [].{

	ms_width : I32
	ms_width = 1024

	ms_half_w : I32
	ms_half_w = 512

	ms_half_h : I32
	ms_half_h = 384

	ms_ring : F32, F32, F32 -> F32
	ms_ring = |cx, cy, phase| ({
		r2 = ((cx * cx) + (cy * cy))
		(if (DeviceMath.real_sin(((r2 * 0.0009) + phase)) > 0.0) { 1.0 } else { 0.0 })
	})

	ms_super : F32, F32, F32, I32, F32 -> F32
	ms_super = |cx, cy, phase, s, acc| (if (s >= 16) { acc } else { ({
		sxi = I32.minus_wrap(s, I32.times_wrap(Device.div(s, 4), 4))
		syi = Device.div(s, 4)
		ddx = ((I32.to_f32(sxi) * 0.25) - 0.375)
		ddy = ((I32.to_f32(syi) * 0.25) - 0.375)
		ms_super(cx, cy, phase, I32.plus_wrap(s, 1), (acc + ms_ring((cx + ddx), (cy + ddy), phase)))
	}) })

	ms_render : I32, I32 -> I32
	ms_render = |gid, frame| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, ms_width), ms_width))
		py = Device.div(gid, ms_width)
		cx = I32.to_f32(I32.minus_wrap(px, ms_half_w))
		cy = I32.to_f32(I32.minus_wrap(py, ms_half_h))
		phase = (I32.to_f32(frame) / 20.0)
		v = (if (px < ms_half_w) { ms_ring(cx, cy, phase) } else { (ms_super(cx, cy, phase, 0, 0.0) / 16.0) })
		edge = (if ((px > I32.minus_wrap(ms_half_w, 2)) and (px < I32.plus_wrap(ms_half_w, 2))) { 1 } else { 0 })
		(if (edge == 1) { I32.plus_wrap(I32.plus_wrap(I32.times_wrap(40, 65536), I32.times_wrap(90, 256)), 130) } else { ({
			tint_r = (if (px < ms_half_w) { 0.75 } else { 0.55 })
			tint_g = (if (px < ms_half_w) { 0.6 } else { 0.8 })
			tint_b = 0.9
			ir = F32.to_i32_wrap(((v * tint_r) * 255.0))
			ig = F32.to_i32_wrap(((v * tint_g) * 255.0))
			ib = F32.to_i32_wrap(((v * tint_b) * 255.0))
			I32.plus_wrap(I32.plus_wrap(I32.times_wrap(ir, 65536), I32.times_wrap(ig, 256)), ib)
		}) })
	})

	multisample_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	multisample_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, ms_render(gid, frame))
	})
}
