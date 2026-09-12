# TriangleKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

TriangleKernel :: [].{

	tr_width : I32
	tr_width = 1024

	tr_wrap : I32 -> I32
	tr_wrap = |a| ({
		m = I32.minus_wrap(a, I32.times_wrap(Device.div(a, 6283), 6283))
		(if (m < 0) { I32.plus_wrap(m, 6283) } else { m })
	})

	tr_sin_core : I32 -> I32
	tr_sin_core = |x| ({
		x2 = Device.div(I32.times_wrap(x, x), 1000)
		x3 = Device.div(I32.times_wrap(x2, x), 1000)
		x5 = Device.div(I32.times_wrap(x3, x2), 1000)
		I32.plus_wrap(I32.minus_wrap(x, Device.div(x3, 6)), Device.div(x5, 120))
	})

	tr_sin : I32 -> I32
	tr_sin = |raw| ({
		a = tr_wrap(raw)
		(if (a <= 1570) { tr_sin_core(a) } else { (if (a <= 3141) { tr_sin_core(I32.minus_wrap(3141, a)) } else { (if (a <= 4712) { I32.minus_wrap(0, tr_sin_core(I32.minus_wrap(a, 3141))) } else { I32.minus_wrap(0, tr_sin_core(I32.minus_wrap(6283, a))) }) }) })
	})

	tr_cos : I32 -> I32
	tr_cos = |raw| tr_sin(I32.plus_wrap(raw, 1570))

	tr_vx : I32, I32 -> I32
	tr_vx = |frame, k| I32.plus_wrap(512, Device.div(I32.times_wrap(tr_cos(I32.plus_wrap(I32.times_wrap(frame, 18), I32.times_wrap(k, 2094))), 250), 1000))

	tr_vy : I32, I32 -> I32
	tr_vy = |frame, k| I32.plus_wrap(384, Device.div(I32.times_wrap(tr_sin(I32.plus_wrap(I32.times_wrap(frame, 18), I32.times_wrap(k, 2094))), 250), 1000))

	tr_edge : I32, I32, I32, I32, I32, I32 -> I32
	tr_edge = |ax, ay, bx, by, px, py| I32.minus_wrap(I32.times_wrap(I32.minus_wrap(px, ax), I32.minus_wrap(by, ay)), I32.times_wrap(I32.minus_wrap(py, ay), I32.minus_wrap(bx, ax)))

	tr_render : I32, I32 -> I32
	tr_render = |gid, frame| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, tr_width), tr_width))
		py = Device.div(gid, tr_width)
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
			sum = I32.plus_wrap(I32.plus_wrap(w0, w1), w2)
			(if (sum == 0) { 0 } else { ({
				r = Device.div(I32.times_wrap(w0, 255), sum)
				g = Device.div(I32.times_wrap(w1, 255), sum)
				b = Device.div(I32.times_wrap(w2, 255), sum)
				I32.plus_wrap(I32.plus_wrap(I32.times_wrap(r, 65536), I32.times_wrap(g, 256)), b)
			}) })
		}) })
	})

	triangle_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	triangle_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, tr_render(gid, frame))
	})
}
