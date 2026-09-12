# SwarmKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

SwarmKernel :: [].{

	sw_width : I32
	sw_width = 1024

	sw_height : I32
	sw_height = 768

	sw_speed : I32
	sw_speed = 9

	sw_wrap : I32 -> I32
	sw_wrap = |a| ({
		m = I32.minus_wrap(a, I32.times_wrap(Device.div(a, 6283), 6283))
		(if (m < 0) { I32.plus_wrap(m, 6283) } else { m })
	})

	sw_sin_core : I32 -> I32
	sw_sin_core = |x| ({
		x2 = Device.div(I32.times_wrap(x, x), 1000)
		x3 = Device.div(I32.times_wrap(x2, x), 1000)
		x5 = Device.div(I32.times_wrap(x3, x2), 1000)
		I32.plus_wrap(I32.minus_wrap(x, Device.div(x3, 6)), Device.div(x5, 120))
	})

	sw_sin : I32 -> I32
	sw_sin = |raw| ({
		a = sw_wrap(raw)
		(if (a <= 1570) { sw_sin_core(a) } else { (if (a <= 3141) { sw_sin_core(I32.minus_wrap(3141, a)) } else { (if (a <= 4712) { I32.minus_wrap(0, sw_sin_core(I32.minus_wrap(a, 3141))) } else { I32.minus_wrap(0, sw_sin_core(I32.minus_wrap(6283, a))) }) }) })
	})

	sw_cos : I32 -> I32
	sw_cos = |raw| sw_sin(I32.plus_wrap(raw, 1570))

	sw_flow_ang : I32, I32, I32 -> I32
	sw_flow_ang = |px, py, frame| sw_wrap(I32.plus_wrap(I32.times_wrap(I32.plus_wrap(sw_sin(I32.plus_wrap(I32.times_wrap(px, 5), I32.times_wrap(frame, 4))), sw_sin(I32.minus_wrap(I32.times_wrap(py, 5), I32.times_wrap(frame, 3)))), 3), I32.times_wrap(frame, 2)))

	sw_flow_vx : I32, I32, I32 -> I32
	sw_flow_vx = |px, py, frame| Device.div(I32.times_wrap(sw_cos(sw_flow_ang(px, py, frame)), sw_speed), 1000)

	sw_flow_vy : I32, I32, I32 -> I32
	sw_flow_vy = |px, py, frame| Device.div(I32.times_wrap(sw_sin(sw_flow_ang(px, py, frame)), sw_speed), 1000)

	sw_new_vx : I32, I32, I32, I32 -> I32
	sw_new_vx = |px, py, vx, frame| Device.div(I32.plus_wrap(I32.times_wrap(vx, 7), sw_flow_vx(px, py, frame)), 8)

	sw_new_vy : I32, I32, I32, I32 -> I32
	sw_new_vy = |px, py, vy, frame| Device.div(I32.plus_wrap(I32.times_wrap(vy, 7), sw_flow_vy(px, py, frame)), 8)

	sw_wrap_pos : I32, I32 -> I32
	sw_wrap_pos = |v, m| ({
		r = I32.minus_wrap(v, I32.times_wrap(Device.div(v, m), m))
		(if (r < 0) { I32.plus_wrap(r, m) } else { r })
	})

	sw_new_px : I32, I32, I32, I32 -> I32
	sw_new_px = |px, py, vx, frame| sw_wrap_pos(I32.plus_wrap(px, sw_new_vx(px, py, vx, frame)), sw_width)

	sw_new_py : I32, I32, I32, I32 -> I32
	sw_new_py = |px, py, vy, frame| sw_wrap_pos(I32.plus_wrap(py, sw_new_vy(px, py, vy, frame)), sw_height)

	swarm_step : Device.Device, I32, I32, I32, I32 -> (Device.Device, I32)
	swarm_step = |dev, inb, outb, frame, gid| ({
		(dev1, px) = Device.load(dev, inb, I32.times_wrap(gid, 4))
		(dev2, py) = Device.load(dev1, inb, I32.plus_wrap(I32.times_wrap(gid, 4), 1))
		(dev3, vx) = Device.load(dev2, inb, I32.plus_wrap(I32.times_wrap(gid, 4), 2))
		(dev4, vy) = Device.load(dev3, inb, I32.plus_wrap(I32.times_wrap(gid, 4), 3))
		(dev5, _s0) = Device.store(dev4, outb, I32.times_wrap(gid, 4), sw_new_px(px, py, vx, frame))
		(dev6, _s1) = Device.store(dev5, outb, I32.plus_wrap(I32.times_wrap(gid, 4), 1), sw_new_py(px, py, vy, frame))
		(dev7, _s2) = Device.store(dev6, outb, I32.plus_wrap(I32.times_wrap(gid, 4), 2), sw_new_vx(px, py, vx, frame))
		Device.store(dev7, outb, I32.plus_wrap(I32.times_wrap(gid, 4), 3), sw_new_vy(px, py, vy, frame))
	})
}
