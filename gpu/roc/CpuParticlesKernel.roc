# CpuParticlesKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

CpuParticlesKernel :: [].{

	cp_width : I32
	cp_width = 1024

	cp_grav : I32
	cp_grav = 60

	cp_step : Device.Device, I32, I32, I32, I32 -> (Device.Device, I32)
	cp_step = |dev, inb, outb, frame, gid| ({
		(dev1, px) = Device.load(dev, inb, I32.times_wrap(gid, 4))
		(dev2, py) = Device.load(dev1, inb, I32.plus_wrap(I32.times_wrap(gid, 4), 1))
		(dev3, vx) = Device.load(dev2, inb, I32.plus_wrap(I32.times_wrap(gid, 4), 2))
		(dev4, vy) = Device.load(dev3, inb, I32.plus_wrap(I32.times_wrap(gid, 4), 3))
		({
			nvy = I32.plus_wrap(vy, cp_grav)
			mx = I32.plus_wrap(px, vx)
			my = I32.plus_wrap(py, nvy)
			off = (if (my > 12288) { 1 } else { (if (mx < 0) { 1 } else { (if (mx > 16384) { 1 } else { 0 }) }) })
			seed = I32.plus_wrap(I32.times_wrap(gid, 2657), I32.times_wrap(frame, 131))
			h1 = I32.minus_wrap(seed, I32.times_wrap(Device.div(seed, 131), 131))
			h2 = I32.minus_wrap(I32.times_wrap(seed, 7), I32.times_wrap(Device.div(I32.times_wrap(seed, 7), 173), 173))
			h3 = I32.minus_wrap(I32.times_wrap(seed, 17), I32.times_wrap(Device.div(I32.times_wrap(seed, 17), 97), 97))
			rpx = (if (off == 1) { I32.plus_wrap(8192, I32.times_wrap(I32.minus_wrap(h1, 65), 20)) } else { mx })
			rpy = (if (off == 1) { 12200 } else { my })
			rvx = (if (off == 1) { I32.times_wrap(I32.minus_wrap(h2, 86), 9) } else { vx })
			rvy = (if (off == 1) { I32.minus_wrap(0, I32.plus_wrap(760, I32.times_wrap(h3, 5))) } else { nvy })
			({
				(dev5, _s0) = Device.store(dev4, outb, I32.times_wrap(gid, 4), rpx)
				(dev6, _s1) = Device.store(dev5, outb, I32.plus_wrap(I32.times_wrap(gid, 4), 1), rpy)
				(dev7, _s2) = Device.store(dev6, outb, I32.plus_wrap(I32.times_wrap(gid, 4), 2), rvx)
				Device.store(dev7, outb, I32.plus_wrap(I32.times_wrap(gid, 4), 3), rvy)
			})
		})
	})
}
