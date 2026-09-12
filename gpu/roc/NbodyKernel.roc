# NbodyKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

NbodyKernel :: [].{

	nb_count : I64
	nb_count = 1024

	nb_width : I64
	nb_width = 1024

	nb_height : I64
	nb_height = 768

	nb_fx : Device.Device, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	nb_fx = |dev, buf, myx, myy, j, acc| (if (j >= nb_count) { (dev, acc) } else { ({
		(dev1, jx) = Device.load(dev, buf, (j * 4))
		(dev2, jy) = Device.load(dev1, buf, ((j * 4) + 1))
		({
			dx = I64.div_trunc_by((jx - myx), 256)
			dy = I64.div_trunc_by((jy - myy), 256)
			d2 = (((dx * dx) + (dy * dy)) + 32)
			w = I64.div_trunc_by(9000, d2)
			nb_fx(dev2, buf, myx, myy, (j + 1), (acc + (dx * w)))
		})
	}) })

	nb_fy : Device.Device, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	nb_fy = |dev, buf, myx, myy, j, acc| (if (j >= nb_count) { (dev, acc) } else { ({
		(dev1, jx) = Device.load(dev, buf, (j * 4))
		(dev2, jy) = Device.load(dev1, buf, ((j * 4) + 1))
		({
			dx = I64.div_trunc_by((jx - myx), 256)
			dy = I64.div_trunc_by((jy - myy), 256)
			d2 = (((dx * dx) + (dy * dy)) + 32)
			w = I64.div_trunc_by(9000, d2)
			nb_fy(dev2, buf, myx, myy, (j + 1), (acc + (dy * w)))
		})
	}) })

	nb_wrap : I64, I64 -> I64
	nb_wrap = |v, m| ({
		r = (v - (I64.div_trunc_by(v, m) * m))
		(if (r < 0) { (r + m) } else { r })
	})

	nbody_step : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	nbody_step = |dev, inb, outb, _frame, gid| ({
		(dev1, px) = Device.load(dev, inb, (gid * 4))
		(dev2, py) = Device.load(dev1, inb, ((gid * 4) + 1))
		(dev3, vx) = Device.load(dev2, inb, ((gid * 4) + 2))
		(dev4, vy) = Device.load(dev3, inb, ((gid * 4) + 3))
		(dev5, fx) = nb_fx(dev4, inb, px, py, 0, 0)
		(dev6, fy) = nb_fy(dev5, inb, px, py, 0, 0)
		({
			nvx = (vx + I64.div_trunc_by(fx, 32))
			nvy = (vy + I64.div_trunc_by(fy, 32))
			cvx = (if (nvx > 4200) { 4200 } else { (if (nvx < (0 - 4200)) { (0 - 4200) } else { nvx }) })
			cvy = (if (nvy > 4200) { 4200 } else { (if (nvy < (0 - 4200)) { (0 - 4200) } else { nvy }) })
			npx = nb_wrap((px + cvx), (nb_width * 256))
			npy = nb_wrap((py + cvy), (nb_height * 256))
			({
				(dev7, _s0) = Device.store(dev6, outb, (gid * 4), npx)
				(dev8, _s1) = Device.store(dev7, outb, ((gid * 4) + 1), npy)
				(dev9, _s2) = Device.store(dev8, outb, ((gid * 4) + 2), cvx)
				Device.store(dev9, outb, ((gid * 4) + 3), cvy)
			})
		})
	})
}
