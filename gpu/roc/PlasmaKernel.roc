# PlasmaKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

PlasmaKernel :: [].{

	pl_width : I32
	pl_width = 1024

	pl_wrap : I32 -> I32
	pl_wrap = |a| ({
		m = I32.minus_wrap(a, I32.times_wrap(Device.div(a, 6283), 6283))
		(if (m < 0) { I32.plus_wrap(m, 6283) } else { m })
	})

	pl_sin_core : I32 -> I32
	pl_sin_core = |x| ({
		x2 = Device.div(I32.times_wrap(x, x), 1000)
		x3 = Device.div(I32.times_wrap(x2, x), 1000)
		x5 = Device.div(I32.times_wrap(x3, x2), 1000)
		I32.plus_wrap(I32.minus_wrap(x, Device.div(x3, 6)), Device.div(x5, 120))
	})

	pl_sin : I32 -> I32
	pl_sin = |raw| ({
		a = pl_wrap(raw)
		(if (a <= 1570) { pl_sin_core(a) } else { (if (a <= 3141) { pl_sin_core(I32.minus_wrap(3141, a)) } else { (if (a <= 4712) { I32.minus_wrap(0, pl_sin_core(I32.minus_wrap(a, 3141))) } else { I32.minus_wrap(0, pl_sin_core(I32.minus_wrap(6283, a))) }) }) })
	})

	pl_px : I32 -> I32
	pl_px = |gid| I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, pl_width), pl_width))

	pl_py : I32 -> I32
	pl_py = |gid| Device.div(gid, pl_width)

	pl_channel : I32, I32, I32 -> I32
	pl_channel = |wave, phase, t| ({
		s = pl_sin(I32.plus_wrap(I32.plus_wrap(wave, phase), t))
		I32.plus_wrap(128, Device.div(I32.times_wrap(s, 118), 1000))
	})

	pl_color : I32, I32 -> I32
	pl_color = |gid, frame| ({
		px = pl_px(gid)
		py = pl_py(gid)
		t = I32.times_wrap(frame, 24)
		r = pl_channel(I32.plus_wrap(I32.times_wrap(px, 11), I32.times_wrap(py, 4)), 0, t)
		g = pl_channel(I32.times_wrap(py, 12), 2094, I32.plus_wrap(t, Device.div(t, 2)))
		b = pl_channel(I32.plus_wrap(I32.times_wrap(I32.plus_wrap(px, py), 7), I32.times_wrap(pl_sin(I32.plus_wrap(I32.times_wrap(px, 5), t)), 3)), 4188, t)
		I32.plus_wrap(I32.plus_wrap(I32.times_wrap(r, 65536), I32.times_wrap(g, 256)), b)
	})

	plasma_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	plasma_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, pl_color(gid, frame))
	})
}
