# FireworksKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

FireworksKernel :: [].{

	fw_wrap : I32 -> I32
	fw_wrap = |a| ({
		m = I32.minus_wrap(a, I32.times_wrap(Device.div(a, 6283), 6283))
		(if (m < 0) { I32.plus_wrap(m, 6283) } else { m })
	})

	fw_sin_core : I32 -> I32
	fw_sin_core = |x| ({
		x2 = Device.div(I32.times_wrap(x, x), 1000)
		x3 = Device.div(I32.times_wrap(x2, x), 1000)
		x5 = Device.div(I32.times_wrap(x3, x2), 1000)
		I32.plus_wrap(I32.minus_wrap(x, Device.div(x3, 6)), Device.div(x5, 120))
	})

	fw_sin : I32 -> I32
	fw_sin = |raw| ({
		a = fw_wrap(raw)
		(if (a <= 1570) { fw_sin_core(a) } else { (if (a <= 3141) { fw_sin_core(I32.minus_wrap(3141, a)) } else { (if (a <= 4712) { I32.minus_wrap(0, fw_sin_core(I32.minus_wrap(a, 3141))) } else { I32.minus_wrap(0, fw_sin_core(I32.minus_wrap(6283, a))) }) }) })
	})

	fw_cos : I32 -> I32
	fw_cos = |raw| fw_sin(I32.plus_wrap(raw, 1570))

	fw_jit_speed : I32 -> I32
	fw_jit_speed = |gid| I32.plus_wrap(260, I32.minus_wrap(I32.times_wrap(gid, 37), I32.times_wrap(I32.times_wrap(Device.div(gid, 29), 29), 37)))

	fw_burst_spark : Device.Device, I32, I32, I32, I32, I32, I32 -> (Device.Device, I32)
	fw_burst_spark = |dev, out, cx, cy, frame, nspark, gid| ({
		ang = fw_wrap(Device.div(I32.times_wrap(gid, 6283), nspark))
		spd = fw_jit_speed(gid)
		vx = Device.div(I32.times_wrap(fw_cos(ang), spd), 1000)
		vy = Device.div(I32.times_wrap(fw_sin(ang), spd), 1000)
		px = I32.plus_wrap(cx, Device.div(I32.times_wrap(vx, frame), 256))
		py = I32.plus_wrap(I32.plus_wrap(cy, Device.div(I32.times_wrap(vy, frame), 256)), Device.div(I32.times_wrap(I32.times_wrap(20, frame), frame), 512))
		life = I32.minus_wrap(200, frame)
		bright = (if (life < 0) { 0 } else { Device.div(I32.times_wrap(life, 255), 200) })
		packed = I32.plus_wrap(I32.plus_wrap(I32.times_wrap(bright, 16777216), I32.times_wrap(px, 4096)), py)
		Device.store(dev, out, gid, packed)
	})

	fw_integrate : Device.Device, I32, I32, I32, I32, I32 -> (Device.Device, I32)
	fw_integrate = |dev, state, out, frame, grav, gid| ({
		(dev1, px0) = Device.load(dev, state, I32.times_wrap(gid, 4))
		(dev2, py0) = Device.load(dev1, state, I32.plus_wrap(I32.times_wrap(gid, 4), 1))
		(dev3, vx) = Device.load(dev2, state, I32.plus_wrap(I32.times_wrap(gid, 4), 2))
		(dev4, vy) = Device.load(dev3, state, I32.plus_wrap(I32.times_wrap(gid, 4), 3))
		({
			px = I32.plus_wrap(px0, Device.div(I32.times_wrap(vx, frame), 256))
			py = I32.plus_wrap(I32.plus_wrap(py0, Device.div(I32.times_wrap(vy, frame), 256)), Device.div(I32.times_wrap(I32.times_wrap(grav, frame), frame), 512))
			packed = I32.plus_wrap(I32.times_wrap(px, 65536), py)
			Device.store(dev4, out, gid, packed)
		})
	})
}
