# ParticlesKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

ParticlesKernel :: [].{

	pa_width : I32
	pa_width = 1024

	pa_height : I32
	pa_height = 768

	pa_wrap : I32 -> I32
	pa_wrap = |a| ({
		m = I32.minus_wrap(a, I32.times_wrap(Device.div(a, 6283), 6283))
		(if (m < 0) { I32.plus_wrap(m, 6283) } else { m })
	})

	pa_sin_core : I32 -> I32
	pa_sin_core = |x| ({
		x2 = Device.div(I32.times_wrap(x, x), 1000)
		x3 = Device.div(I32.times_wrap(x2, x), 1000)
		x5 = Device.div(I32.times_wrap(x3, x2), 1000)
		I32.plus_wrap(I32.minus_wrap(x, Device.div(x3, 6)), Device.div(x5, 120))
	})

	pa_sin : I32 -> I32
	pa_sin = |raw| ({
		a = pa_wrap(raw)
		(if (a <= 1570) { pa_sin_core(a) } else { (if (a <= 3141) { pa_sin_core(I32.minus_wrap(3141, a)) } else { (if (a <= 4712) { I32.minus_wrap(0, pa_sin_core(I32.minus_wrap(a, 3141))) } else { I32.minus_wrap(0, pa_sin_core(I32.minus_wrap(6283, a))) }) }) })
	})

	pa_cos : I32 -> I32
	pa_cos = |raw| pa_sin(I32.plus_wrap(raw, 1570))

	pa_ax0 : I32 -> I32
	pa_ax0 = |frame| I32.plus_wrap(512, Device.div(I32.times_wrap(pa_cos(I32.times_wrap(frame, 34)), 270), 1000))

	pa_ay0 : I32 -> I32
	pa_ay0 = |frame| I32.plus_wrap(384, Device.div(I32.times_wrap(pa_sin(I32.times_wrap(frame, 34)), 180), 1000))

	pa_ax1 : I32 -> I32
	pa_ax1 = |frame| I32.minus_wrap(512, Device.div(I32.times_wrap(pa_cos(I32.times_wrap(frame, 34)), 270), 1000))

	pa_ay1 : I32 -> I32
	pa_ay1 = |frame| I32.minus_wrap(384, Device.div(I32.times_wrap(pa_sin(I32.times_wrap(frame, 34)), 180), 1000))

	pa_acc : I32, I32, I32, I32 -> I32
	pa_acc = |px, py, ax, ay| ({
		dx = I32.minus_wrap(ax, px)
		dy = I32.minus_wrap(ay, py)
		d2 = I32.plus_wrap(I32.times_wrap(dx, dx), I32.times_wrap(dy, dy))
		inv = Device.div(260000, I32.plus_wrap(Device.div(d2, 256), 500))
		Device.div(I32.times_wrap(dx, inv), 11000)
	})

	pa_acc_y : I32, I32, I32, I32 -> I32
	pa_acc_y = |px, py, ax, ay| ({
		dx = I32.minus_wrap(ax, px)
		dy = I32.minus_wrap(ay, py)
		d2 = I32.plus_wrap(I32.times_wrap(dx, dx), I32.times_wrap(dy, dy))
		inv = Device.div(260000, I32.plus_wrap(Device.div(d2, 256), 500))
		Device.div(I32.times_wrap(dy, inv), 11000)
	})

	pa_wrap_pos : I32, I32 -> I32
	pa_wrap_pos = |v, m| ({
		r = I32.minus_wrap(v, I32.times_wrap(Device.div(v, m), m))
		(if (r < 0) { I32.plus_wrap(r, m) } else { r })
	})

	particles_step : Device.Device, I32, I32, I32, I32 -> (Device.Device, I32)
	particles_step = |dev, inb, outb, frame, gid| ({
		(dev1, px) = Device.load(dev, inb, I32.times_wrap(gid, 4))
		(dev2, py) = Device.load(dev1, inb, I32.plus_wrap(I32.times_wrap(gid, 4), 1))
		(dev3, vx) = Device.load(dev2, inb, I32.plus_wrap(I32.times_wrap(gid, 4), 2))
		(dev4, vy) = Device.load(dev3, inb, I32.plus_wrap(I32.times_wrap(gid, 4), 3))
		({
			ax0 = pa_ax0(frame)
			ay0 = pa_ay0(frame)
			ax1 = pa_ax1(frame)
			ay1 = pa_ay1(frame)
			accx = I32.plus_wrap(pa_acc(px, py, ax0, ay0), pa_acc(px, py, ax1, ay1))
			accy = I32.plus_wrap(pa_acc_y(px, py, ax0, ay0), pa_acc_y(px, py, ax1, ay1))
			nvx = I32.plus_wrap(I32.minus_wrap(vx, Device.div(vx, 48)), accx)
			nvy = I32.plus_wrap(I32.minus_wrap(vy, Device.div(vy, 48)), accy)
			npx = pa_wrap_pos(I32.plus_wrap(px, Device.div(nvx, 16)), pa_width)
			npy = pa_wrap_pos(I32.plus_wrap(py, Device.div(nvy, 16)), pa_height)
			({
				(dev5, _s0) = Device.store(dev4, outb, I32.times_wrap(gid, 4), npx)
				(dev6, _s1) = Device.store(dev5, outb, I32.plus_wrap(I32.times_wrap(gid, 4), 1), npy)
				(dev7, _s2) = Device.store(dev6, outb, I32.plus_wrap(I32.times_wrap(gid, 4), 2), nvx)
				Device.store(dev7, outb, I32.plus_wrap(I32.times_wrap(gid, 4), 3), nvy)
			})
		})
	})
}
