# OcclusionKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

OcclusionKernel :: [].{

	oc_width : I64
	oc_width = 1024

	oc_half_w : I64
	oc_half_w = 512

	oc_half_h : I64
	oc_half_h = 384

	oc_count : I64
	oc_count = 14

	oc_cx : I64 -> F64
	oc_cx = |i| (DeviceMath.real_cos((I64.to_f64(i) * 1.1)) * (0.8 + I64.to_f64((i - (I64.div_trunc_by(i, 3) * 3)))))

	oc_cy : I64 -> F64
	oc_cy = |i| (DeviceMath.real_sin((I64.to_f64(i) * 1.7)) * 1.3)

	oc_cz : I64 -> F64
	oc_cz = |i| (DeviceMath.real_sin((I64.to_f64(i) * 0.9)) * 1.4)

	oc_enters : F64, F64, F64, F64, F64, F64, I64, F64, I64 -> I64
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
		oc_enters(ox, oy, oz, dx, dy, dz, (i + 1), spin, (acc + hit))
	}) })

	oc_pack : F64, F64, F64 -> I64
	oc_pack = |r, g, b| (((F64.to_i64_wrap((DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, r)) * 255.0)) * 65536) + (F64.to_i64_wrap((DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, g)) * 255.0)) * 256)) + F64.to_i64_wrap((DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, b)) * 255.0)))

	occlusion_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	occlusion_step = |dev, outb, frame, gid| ({
		px = (gid - (I64.div_trunc_by(gid, oc_width) * oc_width))
		py = I64.div_trunc_by(gid, oc_width)
		fx = (I64.to_f64((px - oc_half_w)) / 384.0)
		fy = (I64.to_f64((oc_half_h - py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 4.0))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (2.0 / rl)
		spin = (I64.to_f64(frame) / 45.0)
		n = oc_enters(0.0, 0.0, (0.0 - 5.0), dx, dy, dz, 0, spin, 0)
		f = (I64.to_f64(n) / 6.0)
		({
			Device.store(dev, outb, gid, (if (n == 0) { (((8 * 65536) + (10 * 256)) + 16) } else { oc_pack((DeviceMath.real_max(0.0, (f - 0.4)) * 1.6), DeviceMath.real_min(1.0, (f * 1.4)), DeviceMath.real_max(0.0, (0.9 - (f * 1.3)))) }))
		})
	})
}
