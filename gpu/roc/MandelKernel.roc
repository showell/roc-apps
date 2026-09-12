# MandelKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

MandelKernel :: [].{

	mb_width : I32
	mb_width = 1024

	mb_height : I32
	mb_height = 768

	mb_max : I32
	mb_max = 96

	mb_mod : I32, I32 -> I32
	mb_mod = |x, m| I32.minus_wrap(x, I32.times_wrap(Device.div(x, m), m))

	mb_iter : I32, I32, I32, I32, I32 -> I32
	mb_iter = |zr, zi, cr, ci, n| (if (n >= mb_max) { mb_max } else { (if (I32.plus_wrap(I32.times_wrap(zr, zr), I32.times_wrap(zi, zi)) > 4000000) { n } else { mb_iter(I32.plus_wrap(Device.div(I32.minus_wrap(I32.times_wrap(zr, zr), I32.times_wrap(zi, zi)), 1000), cr), I32.plus_wrap(Device.div(I32.times_wrap(I32.times_wrap(2, zr), zi), 1000), ci), cr, ci, I32.plus_wrap(n, 1)) }) })

	mb_cr : I32 -> I32
	mb_cr = |gid| I32.minus_wrap(Device.div(I32.times_wrap(mb_mod(gid, mb_width), 3500), mb_width), 2500)

	mb_ci : I32 -> I32
	mb_ci = |gid| I32.minus_wrap(Device.div(I32.times_wrap(Device.div(gid, mb_width), 2400), mb_height), 1200)

	mb_chan : I32, I32, I32 -> I32
	mb_chan = |it, mul, phase| mb_mod(I32.plus_wrap(I32.times_wrap(it, mul), phase), 256)

	mb_color : I32, I32 -> I32
	mb_color = |it, frame| (if (it >= mb_max) { 0 } else { ({
		f = I32.times_wrap(frame, 2)
		r = mb_chan(it, 9, f)
		g = mb_chan(it, 6, I32.plus_wrap(40, f))
		b = mb_chan(it, 13, I32.plus_wrap(90, f))
		I32.plus_wrap(I32.plus_wrap(I32.times_wrap(r, 65536), I32.times_wrap(g, 256)), b)
	}) })

	mandel_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	mandel_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, mb_color(mb_iter(0, 0, mb_cr(gid), mb_ci(gid), 0), frame))
	})
}
