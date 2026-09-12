# BloomSceneKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

BloomSceneKernel :: [].{

	bs_width : I64
	bs_width = 1024

	bs_half_w : I64
	bs_half_w = 512

	bs_half_h : I64
	bs_half_h = 384

	bs_fall : I64, I64, I64, I64 -> F64
	bs_fall = |px, py, cx, cy| ({
		dx = I64.to_f64((px - cx))
		dy = I64.to_f64((py - cy))
		d2 = ((dx * dx) + (dy * dy))
		inten = DeviceMath.real_max(0.0, (1.0 - (d2 / 4200.0)))
		((inten * inten) * inten)
	})

	bloom_scene_step : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	bloom_scene_step = |dev, outb, frame, gid| ({
		px = (gid - (I64.div_trunc_by(gid, bs_width) * bs_width))
		py = I64.div_trunc_by(gid, bs_width)
		f = (I64.to_f64(frame) / 32.0)
		x0 = (bs_half_w + F64.to_i64_wrap((DeviceMath.real_cos(f) * 300.0)))
		y0 = (bs_half_h + F64.to_i64_wrap((DeviceMath.real_sin(f) * 175.0)))
		x1 = (bs_half_w + F64.to_i64_wrap((DeviceMath.real_cos(((f * 1.3) + 2.1)) * 240.0)))
		y1 = (bs_half_h + F64.to_i64_wrap((DeviceMath.real_sin(((f * 1.3) + 2.1)) * 250.0)))
		x2 = (bs_half_w + F64.to_i64_wrap((DeviceMath.real_cos(((f * 0.8) + 4.2)) * 330.0)))
		y2 = (bs_half_h + F64.to_i64_wrap((DeviceMath.real_sin(((f * 0.8) + 4.2)) * 150.0)))
		a = bs_fall(px, py, x0, y0)
		b = bs_fall(px, py, x1, y1)
		c = bs_fall(px, py, x2, y2)
		r = (((a * 255.0) + (b * 70.0)) + (c * 90.0))
		g = (((a * 70.0) + (b * 255.0)) + (c * 110.0))
		bl = (((a * 60.0) + (b * 120.0)) + (c * 255.0))
		ri = F64.to_i64_wrap(DeviceMath.real_min(255.0, (r + 6.0)))
		gi = F64.to_i64_wrap(DeviceMath.real_min(255.0, (g + 7.0)))
		bi = F64.to_i64_wrap(DeviceMath.real_min(255.0, (bl + 11.0)))
		({
			Device.store(dev, outb, gid, (((ri * 65536) + (gi * 256)) + bi))
		})
	})
}
