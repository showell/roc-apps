# NbodyKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

NbodyKernel :: [].{

	nb_count : I32
	nb_count = 1024

	nb_width : I32
	nb_width = 1024

	nb_height : I32
	nb_height = 768

	nb_fx : Device.Device, I32, I32, I32, I32, I32 -> (Device.Device, I32)
	nb_fx = |dev, buf, myx, myy, j, acc| (if (j >= nb_count) { (dev, acc) } else { ({
		(dev1, jx) = Device.load(dev, buf, I32.times_wrap(j, 4))
		(dev2, jy) = Device.load(dev1, buf, I32.plus_wrap(I32.times_wrap(j, 4), 1))
		({
			dx = Device.div(I32.minus_wrap(jx, myx), 256)
			dy = Device.div(I32.minus_wrap(jy, myy), 256)
			d2 = I32.plus_wrap(I32.plus_wrap(I32.times_wrap(dx, dx), I32.times_wrap(dy, dy)), 32)
			w = Device.div(9000, d2)
			nb_fx(dev2, buf, myx, myy, I32.plus_wrap(j, 1), I32.plus_wrap(acc, I32.times_wrap(dx, w)))
		})
	}) })

	nb_fy : Device.Device, I32, I32, I32, I32, I32 -> (Device.Device, I32)
	nb_fy = |dev, buf, myx, myy, j, acc| (if (j >= nb_count) { (dev, acc) } else { ({
		(dev1, jx) = Device.load(dev, buf, I32.times_wrap(j, 4))
		(dev2, jy) = Device.load(dev1, buf, I32.plus_wrap(I32.times_wrap(j, 4), 1))
		({
			dx = Device.div(I32.minus_wrap(jx, myx), 256)
			dy = Device.div(I32.minus_wrap(jy, myy), 256)
			d2 = I32.plus_wrap(I32.plus_wrap(I32.times_wrap(dx, dx), I32.times_wrap(dy, dy)), 32)
			w = Device.div(9000, d2)
			nb_fy(dev2, buf, myx, myy, I32.plus_wrap(j, 1), I32.plus_wrap(acc, I32.times_wrap(dy, w)))
		})
	}) })

	nb_wrap : I32, I32 -> I32
	nb_wrap = |v, m| ({
		r = I32.minus_wrap(v, I32.times_wrap(Device.div(v, m), m))
		(if (r < 0) { I32.plus_wrap(r, m) } else { r })
	})

	nbody_step : Device.Device, I32, I32, I32, I32 -> (Device.Device, I32)
	nbody_step = |dev, inb, outb, _frame, gid| ({
		(dev1, px) = Device.load(dev, inb, I32.times_wrap(gid, 4))
		(dev2, py) = Device.load(dev1, inb, I32.plus_wrap(I32.times_wrap(gid, 4), 1))
		(dev3, vx) = Device.load(dev2, inb, I32.plus_wrap(I32.times_wrap(gid, 4), 2))
		(dev4, vy) = Device.load(dev3, inb, I32.plus_wrap(I32.times_wrap(gid, 4), 3))
		(dev5, fx) = nb_fx(dev4, inb, px, py, 0, 0)
		(dev6, fy) = nb_fy(dev5, inb, px, py, 0, 0)
		({
			nvx = I32.plus_wrap(vx, Device.div(fx, 32))
			nvy = I32.plus_wrap(vy, Device.div(fy, 32))
			cvx = (if (nvx > 4200) { 4200 } else { (if (nvx < I32.minus_wrap(0, 4200)) { I32.minus_wrap(0, 4200) } else { nvx }) })
			cvy = (if (nvy > 4200) { 4200 } else { (if (nvy < I32.minus_wrap(0, 4200)) { I32.minus_wrap(0, 4200) } else { nvy }) })
			npx = nb_wrap(I32.plus_wrap(px, cvx), I32.times_wrap(nb_width, 256))
			npy = nb_wrap(I32.plus_wrap(py, cvy), I32.times_wrap(nb_height, 256))
			({
				(dev7, _s0) = Device.store(dev6, outb, I32.times_wrap(gid, 4), npx)
				(dev8, _s1) = Device.store(dev7, outb, I32.plus_wrap(I32.times_wrap(gid, 4), 1), npy)
				(dev9, _s2) = Device.store(dev8, outb, I32.plus_wrap(I32.times_wrap(gid, 4), 2), cvx)
				Device.store(dev9, outb, I32.plus_wrap(I32.times_wrap(gid, 4), 3), cvy)
			})
		})
	})
}
