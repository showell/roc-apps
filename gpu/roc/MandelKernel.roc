# MandelKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

MandelKernel :: [].{

	mb_width : I64
	mb_width = 1024

	mb_height : I64
	mb_height = 768

	mb_max : I64
	mb_max = 96

	mb_mod : I64, I64 -> I64
	mb_mod = |x, m| (x - (I64.div_trunc_by(x, m) * m))

	mb_iter : I64, I64, I64, I64, I64 -> I64
	mb_iter = |zr, zi, cr, ci, n| (if (n >= mb_max) { mb_max } else { (if (((zr * zr) + (zi * zi)) > 4000000) { n } else { mb_iter((I64.div_trunc_by(((zr * zr) - (zi * zi)), 1000) + cr), (I64.div_trunc_by(((2 * zr) * zi), 1000) + ci), cr, ci, (n + 1)) }) })

	mb_cr : I64 -> I64
	mb_cr = |gid| (I64.div_trunc_by((mb_mod(gid, mb_width) * 3500), mb_width) - 2500)

	mb_ci : I64 -> I64
	mb_ci = |gid| (I64.div_trunc_by((I64.div_trunc_by(gid, mb_width) * 2400), mb_height) - 1200)

	mb_chan : I64, I64, I64 -> I64
	mb_chan = |it, mul, phase| mb_mod(((it * mul) + phase), 256)

	mb_color : I64, I64 -> I64
	mb_color = |it, frame| (if (it >= mb_max) { 0 } else { ({
		f = (frame * 2)
		r = mb_chan(it, 9, f)
		g = mb_chan(it, 6, (40 + f))
		b = mb_chan(it, 13, (90 + f))
		(((r * 65536) + (g * 256)) + b)
	}) })

	mandel_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	mandel_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, mb_color(mb_iter(0, 0, mb_cr(gid), mb_ci(gid), 0), frame))
	})
}
