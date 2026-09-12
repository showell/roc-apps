# FireworksKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

FireworksKernel :: [].{

	fw_wrap : I64 -> I64
	fw_wrap = |a| ({
		m = (a - (I64.div_trunc_by(a, 6283) * 6283))
		(if (m < 0) { (m + 6283) } else { m })
	})

	fw_sin_core : I64 -> I64
	fw_sin_core = |x| ({
		x2 = I64.div_trunc_by((x * x), 1000)
		x3 = I64.div_trunc_by((x2 * x), 1000)
		x5 = I64.div_trunc_by((x3 * x2), 1000)
		((x - I64.div_trunc_by(x3, 6)) + I64.div_trunc_by(x5, 120))
	})

	fw_sin : I64 -> I64
	fw_sin = |raw| ({
		a = fw_wrap(raw)
		(if (a <= 1570) { fw_sin_core(a) } else { (if (a <= 3141) { fw_sin_core((3141 - a)) } else { (if (a <= 4712) { (0 - fw_sin_core((a - 3141))) } else { (0 - fw_sin_core((6283 - a))) }) }) })
	})

	fw_cos : I64 -> I64
	fw_cos = |raw| fw_sin((raw + 1570))

	fw_jit_speed : I64 -> I64
	fw_jit_speed = |gid| (260 + ((gid * 37) - ((I64.div_trunc_by(gid, 29) * 29) * 37)))

	fw_burst_spark : Device.Device, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	fw_burst_spark = |dev, out, cx, cy, frame, nspark, gid| ({
		ang = fw_wrap(I64.div_trunc_by((gid * 6283), nspark))
		spd = fw_jit_speed(gid)
		vx = I64.div_trunc_by((fw_cos(ang) * spd), 1000)
		vy = I64.div_trunc_by((fw_sin(ang) * spd), 1000)
		px = (cx + I64.div_trunc_by((vx * frame), 256))
		py = ((cy + I64.div_trunc_by((vy * frame), 256)) + I64.div_trunc_by(((20 * frame) * frame), 512))
		life = (200 - frame)
		bright = (if (life < 0) { 0 } else { I64.div_trunc_by((life * 255), 200) })
		packed = (((bright * 16777216) + (px * 4096)) + py)
		Device.store(dev, out, gid, packed)
	})

	fw_integrate : Device.Device, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	fw_integrate = |dev, state, out, frame, grav, gid| ({
		(dev1, px0) = Device.load(dev, state, (gid * 4))
		(dev2, py0) = Device.load(dev1, state, ((gid * 4) + 1))
		(dev3, vx) = Device.load(dev2, state, ((gid * 4) + 2))
		(dev4, vy) = Device.load(dev3, state, ((gid * 4) + 3))
		({
			px = (px0 + I64.div_trunc_by((vx * frame), 256))
			py = ((py0 + I64.div_trunc_by((vy * frame), 256)) + I64.div_trunc_by(((grav * frame) * frame), 512))
			packed = ((px * 65536) + py)
			Device.store(dev4, out, gid, packed)
		})
	})
}
