# OcclusionKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

OcclusionKernel :: [].{

	oc_width : I32
	oc_width = 1024

	oc_half_w : I32
	oc_half_w = 512

	oc_half_h : I32
	oc_half_h = 384

	oc_count : I32
	oc_count = 14

	oc_cx : I32 -> F32
	oc_cx = |i| (DeviceMath.real_cos((I32.to_f32(i) * 1.1)) * (0.8 + I32.to_f32(I32.minus_wrap(i, I32.times_wrap(Device.div(i, 3), 3)))))

	oc_cy : I32 -> F32
	oc_cy = |i| (DeviceMath.real_sin((I32.to_f32(i) * 1.7)) * 1.3)

	oc_cz : I32 -> F32
	oc_cz = |i| (DeviceMath.real_sin((I32.to_f32(i) * 0.9)) * 1.4)

	oc_enters : F32, F32, F32, F32, F32, F32, I32, F32, I32 -> I32
	oc_enters = |ox, oy, oz, dx, dy, dz, i, spin, acc| (if (i >= oc_count) { acc } else { ({
		cx = ((oc_cx(i) * DeviceMath.real_cos(spin)) - (oc_cz(i) * DeviceMath.real_sin(spin)))
		cz = ((oc_cx(i) * DeviceMath.real_sin(spin)) + (oc_cz(i) * DeviceMath.real_cos(spin)))
		lx = (ox - cx)
		ly = (oy - oc_cy(i))
		lz = (oz - cz)
		b = (((dx * lx) + (dy * ly)) + (dz * lz))
		c = ((((lx * lx) + (ly * ly)) + (lz * lz)) - 0.64)
		disc = ((b * b) - c)
		hit = (if (disc > 0.0) { (if (((0.0 - b) + DeviceMath.real_sqrt(disc)) > 0.0) { 1 } else { 0 }) } else { 0 })
		oc_enters(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), spin, I32.plus_wrap(acc, hit))
	}) })

	oc_pack : F32, F32, F32 -> I32
	oc_pack = |r, g, b| I32.plus_wrap(I32.plus_wrap(I32.times_wrap(F32.to_i32_wrap((DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, r)) * 255.0)), 65536), I32.times_wrap(F32.to_i32_wrap((DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, g)) * 255.0)), 256)), F32.to_i32_wrap((DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, b)) * 255.0)))

	occlusion_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	occlusion_step = |dev, outb, frame, gid| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, oc_width), oc_width))
		py = Device.div(gid, oc_width)
		fx = (I32.to_f32(I32.minus_wrap(px, oc_half_w)) / 384.0)
		fy = (I32.to_f32(I32.minus_wrap(oc_half_h, py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 4.0))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (2.0 / rl)
		spin = (I32.to_f32(frame) / 45.0)
		n = oc_enters(0.0, 0.0, (0.0 - 5.0), dx, dy, dz, 0, spin, 0)
		f = (I32.to_f32(n) / 6.0)
		({
			Device.store(dev, outb, gid, (if (n == 0) { I32.plus_wrap(I32.plus_wrap(I32.times_wrap(8, 65536), I32.times_wrap(10, 256)), 16) } else { oc_pack((DeviceMath.real_max(0.0, (f - 0.4)) * 1.6), DeviceMath.real_min(1.0, (f * 1.4)), DeviceMath.real_max(0.0, (0.9 - (f * 1.3)))) }))
		})
	})
}
