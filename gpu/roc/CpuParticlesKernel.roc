# CpuParticlesKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

CpuParticlesKernel :: [].{

	cp_width : I64
	cp_width = 1024

	cp_grav : I64
	cp_grav = 60

	cp_step : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	cp_step = |dev, inb, outb, frame, gid| ({
		(dev1, px) = Device.load(dev, inb, (gid * 4))
		(dev2, py) = Device.load(dev1, inb, ((gid * 4) + 1))
		(dev3, vx) = Device.load(dev2, inb, ((gid * 4) + 2))
		(dev4, vy) = Device.load(dev3, inb, ((gid * 4) + 3))
		({
			nvy = (vy + cp_grav)
			mx = (px + vx)
			my = (py + nvy)
			off = (if (my > 12288) { 1 } else { (if (mx < 0) { 1 } else { (if (mx > 16384) { 1 } else { 0 }) }) })
			seed = ((gid * 2657) + (frame * 131))
			h1 = (seed - (I64.div_trunc_by(seed, 131) * 131))
			h2 = ((seed * 7) - (I64.div_trunc_by((seed * 7), 173) * 173))
			h3 = ((seed * 17) - (I64.div_trunc_by((seed * 17), 97) * 97))
			rpx = (if (off == 1) { (8192 + ((h1 - 65) * 20)) } else { mx })
			rpy = (if (off == 1) { 12200 } else { my })
			rvx = (if (off == 1) { ((h2 - 86) * 9) } else { vx })
			rvy = (if (off == 1) { (0 - (760 + (h3 * 5))) } else { nvy })
			({
				(dev5, _s0) = Device.store(dev4, outb, (gid * 4), rpx)
				(dev6, _s1) = Device.store(dev5, outb, ((gid * 4) + 1), rpy)
				(dev7, _s2) = Device.store(dev6, outb, ((gid * 4) + 2), rvx)
				Device.store(dev7, outb, ((gid * 4) + 3), rvy)
			})
		})
	})
}
