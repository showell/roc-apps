# VertexAttrKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

VertexAttrKernel :: [].{

	va_width : I32
	va_width = 1024

	va_half_w : I32
	va_half_w = 512

	va_wrap : I32 -> I32
	va_wrap = |a| ({
		m = I32.minus_wrap(a, I32.times_wrap(Device.div(a, 6283), 6283))
		(if (m < 0) { I32.plus_wrap(m, 6283) } else { m })
	})

	va_sin_core : I32 -> I32
	va_sin_core = |x| ({
		x2 = Device.div(I32.times_wrap(x, x), 1000)
		x3 = Device.div(I32.times_wrap(x2, x), 1000)
		x5 = Device.div(I32.times_wrap(x3, x2), 1000)
		I32.plus_wrap(I32.minus_wrap(x, Device.div(x3, 6)), Device.div(x5, 120))
	})

	va_sin : I32 -> I32
	va_sin = |raw| ({
		a = va_wrap(raw)
		(if (a <= 1570) { va_sin_core(a) } else { (if (a <= 3141) { va_sin_core(I32.minus_wrap(3141, a)) } else { (if (a <= 4712) { I32.minus_wrap(0, va_sin_core(I32.minus_wrap(a, 3141))) } else { I32.minus_wrap(0, va_sin_core(I32.minus_wrap(6283, a))) }) }) })
	})

	va_cos : I32 -> I32
	va_cos = |raw| va_sin(I32.plus_wrap(raw, 1570))

	va_edge : I32, I32, I32, I32, I32, I32 -> I32
	va_edge = |ax, ay, bx, by, px, py| I32.minus_wrap(I32.times_wrap(I32.minus_wrap(px, ax), I32.minus_wrap(by, ay)), I32.times_wrap(I32.minus_wrap(py, ay), I32.minus_wrap(bx, ax)))

	va_render : I32, I32 -> I32
	va_render = |gid, frame| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, va_width), va_width))
		py = Device.div(gid, va_width)
		ax = I32.plus_wrap(512, Device.div(I32.times_wrap(va_cos(I32.times_wrap(frame, 18)), 300), 1000))
		ay = I32.plus_wrap(384, Device.div(I32.times_wrap(va_sin(I32.times_wrap(frame, 18)), 300), 1000))
		bx = I32.plus_wrap(512, Device.div(I32.times_wrap(va_cos(I32.plus_wrap(I32.times_wrap(frame, 18), 2094)), 300), 1000))
		by = I32.plus_wrap(384, Device.div(I32.times_wrap(va_sin(I32.plus_wrap(I32.times_wrap(frame, 18), 2094)), 300), 1000))
		cx = I32.plus_wrap(512, Device.div(I32.times_wrap(va_cos(I32.plus_wrap(I32.times_wrap(frame, 18), 4188)), 300), 1000))
		cy = I32.plus_wrap(384, Device.div(I32.times_wrap(va_sin(I32.plus_wrap(I32.times_wrap(frame, 18), 4188)), 300), 1000))
		w0 = va_edge(bx, by, cx, cy, px, py)
		w1 = va_edge(cx, cy, ax, ay, px, py)
		w2 = va_edge(ax, ay, bx, by, px, py)
		inside = ((((w0 >= 0) and (w1 >= 0)) and (w2 >= 0)) or (((w0 <= 0) and (w1 <= 0)) and (w2 <= 0)))
		(if (inside == False) { I32.plus_wrap(I32.plus_wrap(I32.times_wrap(14, 65536), I32.times_wrap(16, 256)), 24) } else { ({
			sum = I32.plus_wrap(I32.plus_wrap(w0, w1), w2)
			(if (sum == 0) { 0 } else { (if (px < va_half_w) { ({
				r = Device.div(I32.times_wrap(w0, 255), sum)
				g = Device.div(I32.times_wrap(w1, 255), sum)
				b = Device.div(I32.times_wrap(w2, 255), sum)
				I32.plus_wrap(I32.plus_wrap(I32.times_wrap(r, 65536), I32.times_wrap(g, 256)), b)
			}) } else { ({
				u = Device.div(I32.times_wrap(w1, 512), sum)
				v = Device.div(I32.times_wrap(w2, 512), sum)
				chk = I32.minus_wrap(I32.plus_wrap(Device.div(u, 40), Device.div(v, 40)), I32.times_wrap(Device.div(I32.plus_wrap(Device.div(u, 40), Device.div(v, 40)), 2), 2))
				(if (chk == 0) { I32.plus_wrap(I32.plus_wrap(I32.times_wrap(230, 65536), I32.times_wrap(230, 256)), 235) } else { I32.plus_wrap(I32.plus_wrap(I32.times_wrap(40, 65536), I32.times_wrap(44, 256)), 60) })
			}) }) })
		}) })
	})

	vertexattr_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	vertexattr_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, va_render(gid, frame))
	})
}
