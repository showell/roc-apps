# JuliaKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

JuliaKernel :: [].{

	jl_width : I32
	jl_width = 1024

	jl_half_w : I32
	jl_half_w = 512

	jl_half_h : I32
	jl_half_h = 384

	jl_max : I32
	jl_max = 128

	jl_mod : I32, I32 -> I32
	jl_mod = |x, m| I32.minus_wrap(x, I32.times_wrap(Device.div(x, m), m))

	jl_iter : F32, F32, F32, F32, I32 -> I32
	jl_iter = |zr, zi, cr, ci, n| (if (n >= jl_max) { jl_max } else { (if (((zr * zr) + (zi * zi)) > 4.0) { n } else { jl_iter((((zr * zr) - (zi * zi)) + cr), (((2.0 * zr) * zi) + ci), cr, ci, I32.plus_wrap(n, 1)) }) })

	jl_chan : I32, I32, I32 -> I32
	jl_chan = |it, mul, phase| jl_mod(I32.plus_wrap(I32.times_wrap(it, mul), phase), 256)

	jl_color : I32, I32 -> I32
	jl_color = |it, frame| (if (it >= jl_max) { 0 } else { ({
		f = frame
		r = jl_chan(it, 8, I32.plus_wrap(30, f))
		g = jl_chan(it, 5, I32.plus_wrap(90, f))
		b = jl_chan(it, 11, I32.plus_wrap(160, f))
		I32.plus_wrap(I32.plus_wrap(I32.times_wrap(r, 65536), I32.times_wrap(g, 256)), b)
	}) })

	jl_render : I32, I32 -> I32
	jl_render = |gid, frame| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, jl_width), jl_width))
		py = Device.div(gid, jl_width)
		zr = (I32.to_f32(I32.minus_wrap(px, jl_half_w)) / 320.0)
		zi = (I32.to_f32(I32.minus_wrap(py, jl_half_h)) / 320.0)
		a = (I32.to_f32(frame) / 40.0)
		cr = (0.7885 * DeviceMath.real_cos(a))
		ci = (0.7885 * DeviceMath.real_sin(a))
		jl_color(jl_iter(zr, zi, cr, ci, 0), frame)
	})

	julia_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	julia_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, jl_render(gid, frame))
	})
}
