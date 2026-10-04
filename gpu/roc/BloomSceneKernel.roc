# BloomSceneKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

BloomSceneKernel :: [].{

	bs_width : I32
	bs_width = 1024

	bs_half_w : I32
	bs_half_w = 512

	bs_half_h : I32
	bs_half_h = 384

	bs_fall : I32, I32, I32, I32 -> F32
	bs_fall = |px, py, cx, cy| ({
		dx : F32
		dx = I32.to_f32(I32.minus_wrap(px, cx))
		dy : F32
		dy = I32.to_f32(I32.minus_wrap(py, cy))
		d2 : F32
		d2 = ((dx * dx) + (dy * dy))
		inten : F32
		inten = DeviceMath.real_max(0.0, (1.0 - (d2 / 4200.0)))
		((inten * inten) * inten)
	})

	bloom_scene_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	bloom_scene_step = |dev, outb, frame, gid| ({
		px : I32
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, bs_width), bs_width))
		py : I32
		py = Device.div(gid, bs_width)
		f : F32
		f = (I32.to_f32(frame) / 32.0)
		x0 : I32
		x0 = I32.plus_wrap(bs_half_w, F32.to_i32_wrap((DeviceMath.real_cos(f) * 300.0)))
		y0 : I32
		y0 = I32.plus_wrap(bs_half_h, F32.to_i32_wrap((DeviceMath.real_sin(f) * 175.0)))
		x1 : I32
		x1 = I32.plus_wrap(bs_half_w, F32.to_i32_wrap((DeviceMath.real_cos(((f * 1.3) + 2.1)) * 240.0)))
		y1 : I32
		y1 = I32.plus_wrap(bs_half_h, F32.to_i32_wrap((DeviceMath.real_sin(((f * 1.3) + 2.1)) * 250.0)))
		x2 : I32
		x2 = I32.plus_wrap(bs_half_w, F32.to_i32_wrap((DeviceMath.real_cos(((f * 0.8) + 4.2)) * 330.0)))
		y2 : I32
		y2 = I32.plus_wrap(bs_half_h, F32.to_i32_wrap((DeviceMath.real_sin(((f * 0.8) + 4.2)) * 150.0)))
		a : F32
		a = bs_fall(px, py, x0, y0)
		b : F32
		b = bs_fall(px, py, x1, y1)
		c : F32
		c = bs_fall(px, py, x2, y2)
		r : F32
		r = (((a * 255.0) + (b * 70.0)) + (c * 90.0))
		g : F32
		g = (((a * 70.0) + (b * 255.0)) + (c * 110.0))
		bl : F32
		bl = (((a * 60.0) + (b * 120.0)) + (c * 255.0))
		ri : I32
		ri = F32.to_i32_wrap(DeviceMath.real_min(255.0, (r + 6.0)))
		gi : I32
		gi = F32.to_i32_wrap(DeviceMath.real_min(255.0, (g + 7.0)))
		bi : I32
		bi = F32.to_i32_wrap(DeviceMath.real_min(255.0, (bl + 11.0)))
		({
			Device.store(dev, outb, gid, I32.plus_wrap(I32.plus_wrap(I32.times_wrap(ri, 65536), I32.times_wrap(gi, 256)), bi))
		})
	})
}
