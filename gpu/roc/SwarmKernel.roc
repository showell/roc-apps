# SwarmKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

SwarmKernel :: [].{

	sw_width : I64
	sw_width = 1024

	sw_height : I64
	sw_height = 768

	sw_speed : I64
	sw_speed = 9

	sw_wrap : I64 -> I64
	sw_wrap = |a| ({
		m = (a - (I64.div_trunc_by(a, 6283) * 6283))
		(if (m < 0) { (m + 6283) } else { m })
	})

	sw_sin_core : I64 -> I64
	sw_sin_core = |x| ({
		x2 = I64.div_trunc_by((x * x), 1000)
		x3 = I64.div_trunc_by((x2 * x), 1000)
		x5 = I64.div_trunc_by((x3 * x2), 1000)
		((x - I64.div_trunc_by(x3, 6)) + I64.div_trunc_by(x5, 120))
	})

	sw_sin : I64 -> I64
	sw_sin = |raw| ({
		a = sw_wrap(raw)
		(if (a <= 1570) { sw_sin_core(a) } else { (if (a <= 3141) { sw_sin_core((3141 - a)) } else { (if (a <= 4712) { (0 - sw_sin_core((a - 3141))) } else { (0 - sw_sin_core((6283 - a))) }) }) })
	})

	sw_cos : I64 -> I64
	sw_cos = |raw| sw_sin((raw + 1570))

	sw_flow_ang : I64, I64, I64 -> I64
	sw_flow_ang = |px, py, frame| sw_wrap((((sw_sin(((px * 5) + (frame * 4))) + sw_sin(((py * 5) - (frame * 3)))) * 3) + (frame * 2)))

	sw_flow_vx : I64, I64, I64 -> I64
	sw_flow_vx = |px, py, frame| I64.div_trunc_by((sw_cos(sw_flow_ang(px, py, frame)) * sw_speed), 1000)

	sw_flow_vy : I64, I64, I64 -> I64
	sw_flow_vy = |px, py, frame| I64.div_trunc_by((sw_sin(sw_flow_ang(px, py, frame)) * sw_speed), 1000)

	sw_new_vx : I64, I64, I64, I64 -> I64
	sw_new_vx = |px, py, vx, frame| I64.div_trunc_by(((vx * 7) + sw_flow_vx(px, py, frame)), 8)

	sw_new_vy : I64, I64, I64, I64 -> I64
	sw_new_vy = |px, py, vy, frame| I64.div_trunc_by(((vy * 7) + sw_flow_vy(px, py, frame)), 8)

	sw_wrap_pos : I64, I64 -> I64
	sw_wrap_pos = |v, m| ({
		r = (v - (I64.div_trunc_by(v, m) * m))
		(if (r < 0) { (r + m) } else { r })
	})

	sw_new_px : I64, I64, I64, I64 -> I64
	sw_new_px = |px, py, vx, frame| sw_wrap_pos((px + sw_new_vx(px, py, vx, frame)), sw_width)

	sw_new_py : I64, I64, I64, I64 -> I64
	sw_new_py = |px, py, vy, frame| sw_wrap_pos((py + sw_new_vy(px, py, vy, frame)), sw_height)

	swarm_step : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	swarm_step = |dev, inb, outb, frame, gid| ({
		(dev1, px) = Device.load(dev, inb, (gid * 4))
		(dev2, py) = Device.load(dev1, inb, ((gid * 4) + 1))
		(dev3, vx) = Device.load(dev2, inb, ((gid * 4) + 2))
		(dev4, vy) = Device.load(dev3, inb, ((gid * 4) + 3))
		(dev5, _s0) = Device.store(dev4, outb, (gid * 4), sw_new_px(px, py, vx, frame))
		(dev6, _s1) = Device.store(dev5, outb, ((gid * 4) + 1), sw_new_py(px, py, vy, frame))
		(dev7, _s2) = Device.store(dev6, outb, ((gid * 4) + 2), sw_new_vx(px, py, vx, frame))
		Device.store(dev7, outb, ((gid * 4) + 3), sw_new_vy(px, py, vy, frame))
	})
}
