# Hand port of apps/gpushow/kernels/PlasmaKernel.codex (cobblestone-u58), in
# the shape rocemit writes: one type module for the chapter, every def
# annotated, Codex `/` as I64.div_trunc_by. The kernel plasma_step threads
# the Device instead of running under the effect.
import Device

PlasmaKernel :: [].{
	# Section: Screen
	pl_width : I64
	pl_width = 1024

	# Section: Fixed-Point Trig
	pl_wrap : I64 -> I64
	pl_wrap = |a| {
		m = a - I64.div_trunc_by(a, 6283) * 6283
		if m < 0 { m + 6283 } else { m }
	}

	pl_sin_core : I64 -> I64
	pl_sin_core = |x| {
		x2 = I64.div_trunc_by(x * x, 1000)
		x3 = I64.div_trunc_by(x2 * x, 1000)
		x5 = I64.div_trunc_by(x3 * x2, 1000)
		x - I64.div_trunc_by(x3, 6) + I64.div_trunc_by(x5, 120)
	}

	pl_sin : I64 -> I64
	pl_sin = |raw| {
		a = pl_wrap(raw)
		if a <= 1570 { pl_sin_core(a) } else if a <= 3141 { pl_sin_core(3141 - a) } else if a <= 4712 { 0 - pl_sin_core(a - 3141) } else { 0 - pl_sin_core(6283 - a) }
	}

	# Section: Colour Field
	pl_px : I64 -> I64
	pl_px = |gid| gid - I64.div_trunc_by(gid, pl_width) * pl_width

	pl_py : I64 -> I64
	pl_py = |gid| I64.div_trunc_by(gid, pl_width)

	pl_channel : I64, I64, I64 -> I64
	pl_channel = |wave, phase, t| {
		s = pl_sin(wave + phase + t)
		128 + I64.div_trunc_by(s * 118, 1000)
	}

	pl_color : I64, I64 -> I64
	pl_color = |gid, frame| {
		px = pl_px(gid)
		py = pl_py(gid)
		t = frame * 24
		r = pl_channel(px * 11 + py * 4, 0, t)
		g = pl_channel(py * 12, 2094, t + I64.div_trunc_by(t, 2))
		b = pl_channel((px + py) * 7 + pl_sin(px * 5 + t) * 3, 4188, t)
		r * 65536 + g * 256 + b
	}

	# Section: Plasma Kernel
	plasma_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	plasma_step = |dev, outb, frame, gid|
		Device.store(dev, outb, gid, pl_color(gid, frame))
}
