# ParticlesKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

ParticlesKernel :: [].{

	pa_width : I64
	pa_width = 1024

	pa_height : I64
	pa_height = 768

	pa_wrap : I64 -> I64
	pa_wrap = |a| ({
		m = (a - (I64.div_trunc_by(a, 6283) * 6283))
		(if (m < 0) { (m + 6283) } else { m })
	})

	pa_sin_core : I64 -> I64
	pa_sin_core = |x| ({
		x2 = I64.div_trunc_by((x * x), 1000)
		x3 = I64.div_trunc_by((x2 * x), 1000)
		x5 = I64.div_trunc_by((x3 * x2), 1000)
		((x - I64.div_trunc_by(x3, 6)) + I64.div_trunc_by(x5, 120))
	})

	pa_sin : I64 -> I64
	pa_sin = |raw| ({
		a = pa_wrap(raw)
		(if (a <= 1570) { pa_sin_core(a) } else { (if (a <= 3141) { pa_sin_core((3141 - a)) } else { (if (a <= 4712) { (0 - pa_sin_core((a - 3141))) } else { (0 - pa_sin_core((6283 - a))) }) }) })
	})

	pa_cos : I64 -> I64
	pa_cos = |raw| pa_sin((raw + 1570))

	pa_ax0 : I64 -> I64
	pa_ax0 = |frame| (512 + I64.div_trunc_by((pa_cos((frame * 34)) * 270), 1000))

	pa_ay0 : I64 -> I64
	pa_ay0 = |frame| (384 + I64.div_trunc_by((pa_sin((frame * 34)) * 180), 1000))

	pa_ax1 : I64 -> I64
	pa_ax1 = |frame| (512 - I64.div_trunc_by((pa_cos((frame * 34)) * 270), 1000))

	pa_ay1 : I64 -> I64
	pa_ay1 = |frame| (384 - I64.div_trunc_by((pa_sin((frame * 34)) * 180), 1000))

	pa_acc : I64, I64, I64, I64 -> I64
	pa_acc = |px, py, ax, ay| ({
		dx = (ax - px)
		dy = (ay - py)
		d2 = ((dx * dx) + (dy * dy))
		inv = I64.div_trunc_by(260000, (I64.div_trunc_by(d2, 256) + 500))
		I64.div_trunc_by((dx * inv), 11000)
	})

	pa_acc_y : I64, I64, I64, I64 -> I64
	pa_acc_y = |px, py, ax, ay| ({
		dx = (ax - px)
		dy = (ay - py)
		d2 = ((dx * dx) + (dy * dy))
		inv = I64.div_trunc_by(260000, (I64.div_trunc_by(d2, 256) + 500))
		I64.div_trunc_by((dy * inv), 11000)
	})

	pa_wrap_pos : I64, I64 -> I64
	pa_wrap_pos = |v, m| ({
		r = (v - (I64.div_trunc_by(v, m) * m))
		(if (r < 0) { (r + m) } else { r })
	})

	particles_step : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	particles_step = |dev, inb, outb, frame, gid| ({
		(dev1, px) = Device.load(dev, inb, (gid * 4))
		(dev2, py) = Device.load(dev1, inb, ((gid * 4) + 1))
		(dev3, vx) = Device.load(dev2, inb, ((gid * 4) + 2))
		(dev4, vy) = Device.load(dev3, inb, ((gid * 4) + 3))
		({
			ax0 = pa_ax0(frame)
			ay0 = pa_ay0(frame)
			ax1 = pa_ax1(frame)
			ay1 = pa_ay1(frame)
			accx = (pa_acc(px, py, ax0, ay0) + pa_acc(px, py, ax1, ay1))
			accy = (pa_acc_y(px, py, ax0, ay0) + pa_acc_y(px, py, ax1, ay1))
			nvx = ((vx - I64.div_trunc_by(vx, 48)) + accx)
			nvy = ((vy - I64.div_trunc_by(vy, 48)) + accy)
			npx = pa_wrap_pos((px + I64.div_trunc_by(nvx, 16)), pa_width)
			npy = pa_wrap_pos((py + I64.div_trunc_by(nvy, 16)), pa_height)
			({
				(dev5, _s0) = Device.store(dev4, outb, (gid * 4), npx)
				(dev6, _s1) = Device.store(dev5, outb, ((gid * 4) + 1), npy)
				(dev7, _s2) = Device.store(dev6, outb, ((gid * 4) + 2), nvx)
				Device.store(dev7, outb, ((gid * 4) + 3), nvy)
			})
		})
	})
}
