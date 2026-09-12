# JuliaKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

JuliaKernel :: [].{

	jl_width : I64
	jl_width = 1024

	jl_half_w : I64
	jl_half_w = 512

	jl_half_h : I64
	jl_half_h = 384

	jl_max : I64
	jl_max = 128

	jl_mod : I64, I64 -> I64
	jl_mod = |x, m| (x - (I64.div_trunc_by(x, m) * m))

	jl_iter : F64, F64, F64, F64, I64 -> I64
	jl_iter = |zr, zi, cr, ci, n| (if (n >= jl_max) { jl_max } else { (if (((zr * zr) + (zi * zi)) > 4.0) { n } else { jl_iter((((zr * zr) - (zi * zi)) + cr), (((2.0 * zr) * zi) + ci), cr, ci, (n + 1)) }) })

	jl_chan : I64, I64, I64 -> I64
	jl_chan = |it, mul, phase| jl_mod(((it * mul) + phase), 256)

	jl_color : I64, I64 -> I64
	jl_color = |it, frame| (if (it >= jl_max) { 0 } else { ({
		f = frame
		r = jl_chan(it, 8, (30 + f))
		g = jl_chan(it, 5, (90 + f))
		b = jl_chan(it, 11, (160 + f))
		(((r * 65536) + (g * 256)) + b)
	}) })

	jl_render : I64, I64 -> I64
	jl_render = |gid, frame| ({
		px = (gid - (I64.div_trunc_by(gid, jl_width) * jl_width))
		py = I64.div_trunc_by(gid, jl_width)
		zr = (I64.to_f64((px - jl_half_w)) / 320.0)
		zi = (I64.to_f64((py - jl_half_h)) / 320.0)
		a = (I64.to_f64(frame) / 40.0)
		cr = (0.7885 * DeviceMath.real_cos(a))
		ci = (0.7885 * DeviceMath.real_sin(a))
		jl_color(jl_iter(zr, zi, cr, ci, 0), frame)
	})

	julia_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	julia_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, jl_render(gid, frame))
	})
}
