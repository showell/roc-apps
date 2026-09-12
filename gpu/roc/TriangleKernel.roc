# TriangleKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

TriangleKernel :: [].{

	tr_width : I64
	tr_width = 1024

	tr_wrap : I64 -> I64
	tr_wrap = |a| ({
		m = (a - (I64.div_trunc_by(a, 6283) * 6283))
		(if (m < 0) { (m + 6283) } else { m })
	})

	tr_sin_core : I64 -> I64
	tr_sin_core = |x| ({
		x2 = I64.div_trunc_by((x * x), 1000)
		x3 = I64.div_trunc_by((x2 * x), 1000)
		x5 = I64.div_trunc_by((x3 * x2), 1000)
		((x - I64.div_trunc_by(x3, 6)) + I64.div_trunc_by(x5, 120))
	})

	tr_sin : I64 -> I64
	tr_sin = |raw| ({
		a = tr_wrap(raw)
		(if (a <= 1570) { tr_sin_core(a) } else { (if (a <= 3141) { tr_sin_core((3141 - a)) } else { (if (a <= 4712) { (0 - tr_sin_core((a - 3141))) } else { (0 - tr_sin_core((6283 - a))) }) }) })
	})

	tr_cos : I64 -> I64
	tr_cos = |raw| tr_sin((raw + 1570))

	tr_vx : I64, I64 -> I64
	tr_vx = |frame, k| (512 + I64.div_trunc_by((tr_cos(((frame * 18) + (k * 2094))) * 250), 1000))

	tr_vy : I64, I64 -> I64
	tr_vy = |frame, k| (384 + I64.div_trunc_by((tr_sin(((frame * 18) + (k * 2094))) * 250), 1000))

	tr_edge : I64, I64, I64, I64, I64, I64 -> I64
	tr_edge = |ax, ay, bx, by, px, py| (((px - ax) * (by - ay)) - ((py - ay) * (bx - ax)))

	tr_render : I64, I64 -> I64
	tr_render = |gid, frame| ({
		px = (gid - (I64.div_trunc_by(gid, tr_width) * tr_width))
		py = I64.div_trunc_by(gid, tr_width)
		ax = tr_vx(frame, 0)
		ay = tr_vy(frame, 0)
		bx = tr_vx(frame, 1)
		by = tr_vy(frame, 1)
		cx = tr_vx(frame, 2)
		cy = tr_vy(frame, 2)
		w0 = tr_edge(bx, by, cx, cy, px, py)
		w1 = tr_edge(cx, cy, ax, ay, px, py)
		w2 = tr_edge(ax, ay, bx, by, px, py)
		inside = ((((w0 >= 0) and (w1 >= 0)) and (w2 >= 0)) or (((w0 <= 0) and (w1 <= 0)) and (w2 <= 0)))
		(if (inside == False) { 0 } else { ({
			sum = ((w0 + w1) + w2)
			(if (sum == 0) { 0 } else { ({
				r = I64.div_trunc_by((w0 * 255), sum)
				g = I64.div_trunc_by((w1 * 255), sum)
				b = I64.div_trunc_by((w2 * 255), sum)
				(((r * 65536) + (g * 256)) + b)
			}) })
		}) })
	})

	triangle_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	triangle_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, tr_render(gid, frame))
	})
}
