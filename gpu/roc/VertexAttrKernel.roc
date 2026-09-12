# VertexAttrKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

VertexAttrKernel :: [].{

	va_width : I64
	va_width = 1024

	va_half_w : I64
	va_half_w = 512

	va_wrap : I64 -> I64
	va_wrap = |a| ({
		m = (a - (I64.div_trunc_by(a, 6283) * 6283))
		(if (m < 0) { (m + 6283) } else { m })
	})

	va_sin_core : I64 -> I64
	va_sin_core = |x| ({
		x2 = I64.div_trunc_by((x * x), 1000)
		x3 = I64.div_trunc_by((x2 * x), 1000)
		x5 = I64.div_trunc_by((x3 * x2), 1000)
		((x - I64.div_trunc_by(x3, 6)) + I64.div_trunc_by(x5, 120))
	})

	va_sin : I64 -> I64
	va_sin = |raw| ({
		a = va_wrap(raw)
		(if (a <= 1570) { va_sin_core(a) } else { (if (a <= 3141) { va_sin_core((3141 - a)) } else { (if (a <= 4712) { (0 - va_sin_core((a - 3141))) } else { (0 - va_sin_core((6283 - a))) }) }) })
	})

	va_cos : I64 -> I64
	va_cos = |raw| va_sin((raw + 1570))

	va_edge : I64, I64, I64, I64, I64, I64 -> I64
	va_edge = |ax, ay, bx, by, px, py| (((px - ax) * (by - ay)) - ((py - ay) * (bx - ax)))

	va_render : I64, I64 -> I64
	va_render = |gid, frame| ({
		px = (gid - (I64.div_trunc_by(gid, va_width) * va_width))
		py = I64.div_trunc_by(gid, va_width)
		ax = (512 + I64.div_trunc_by((va_cos((frame * 18)) * 300), 1000))
		ay = (384 + I64.div_trunc_by((va_sin((frame * 18)) * 300), 1000))
		bx = (512 + I64.div_trunc_by((va_cos(((frame * 18) + 2094)) * 300), 1000))
		by = (384 + I64.div_trunc_by((va_sin(((frame * 18) + 2094)) * 300), 1000))
		cx = (512 + I64.div_trunc_by((va_cos(((frame * 18) + 4188)) * 300), 1000))
		cy = (384 + I64.div_trunc_by((va_sin(((frame * 18) + 4188)) * 300), 1000))
		w0 = va_edge(bx, by, cx, cy, px, py)
		w1 = va_edge(cx, cy, ax, ay, px, py)
		w2 = va_edge(ax, ay, bx, by, px, py)
		inside = ((((w0 >= 0) and (w1 >= 0)) and (w2 >= 0)) or (((w0 <= 0) and (w1 <= 0)) and (w2 <= 0)))
		(if (inside == False) { (((14 * 65536) + (16 * 256)) + 24) } else { ({
			sum = ((w0 + w1) + w2)
			(if (sum == 0) { 0 } else { (if (px < va_half_w) { ({
				r = I64.div_trunc_by((w0 * 255), sum)
				g = I64.div_trunc_by((w1 * 255), sum)
				b = I64.div_trunc_by((w2 * 255), sum)
				(((r * 65536) + (g * 256)) + b)
			}) } else { ({
				u = I64.div_trunc_by((w1 * 512), sum)
				v = I64.div_trunc_by((w2 * 512), sum)
				chk = ((I64.div_trunc_by(u, 40) + I64.div_trunc_by(v, 40)) - (I64.div_trunc_by((I64.div_trunc_by(u, 40) + I64.div_trunc_by(v, 40)), 2) * 2))
				(if (chk == 0) { (((230 * 65536) + (230 * 256)) + 235) } else { (((40 * 65536) + (44 * 256)) + 60) })
			}) }) })
		}) })
	})

	vertexattr_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	vertexattr_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, va_render(gid, frame))
	})
}
