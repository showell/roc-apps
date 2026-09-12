# RadialKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

RadialKernel :: [].{

	rd_width : I32
	rd_width = 1024

	rd_half_w : I32
	rd_half_w = 512

	rd_half_h : I32
	rd_half_h = 384

	rd_taps : I32
	rd_taps = 28

	rd_clamp : I32, I32, I32 -> I32
	rd_clamp = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	rd_extract : I32, I32 -> I32
	rd_extract = |texel, ch| (if (ch == 0) { Device.div(texel, 65536) } else { (if (ch == 1) { I32.minus_wrap(Device.div(texel, 256), I32.times_wrap(Device.div(texel, 65536), 256)) } else { I32.minus_wrap(texel, I32.times_wrap(Device.div(texel, 256), 256)) }) })

	rd_gather : Device.Device, I32, I32, I32, I32, I32, I32 -> (Device.Device, I32)
	rd_gather = |dev, buf, px, py, ch, k, acc| (if (k >= rd_taps) { (dev, acc) } else { ({
		scale = (1.0 - (I32.to_f32(k) * 0.0075))
		sx = I32.plus_wrap(rd_half_w, F32.to_i32_wrap((I32.to_f32(I32.minus_wrap(px, rd_half_w)) * scale)))
		sy = I32.plus_wrap(rd_half_h, F32.to_i32_wrap((I32.to_f32(I32.minus_wrap(py, rd_half_h)) * scale)))
		cx = rd_clamp(sx, 0, 1023)
		cy = rd_clamp(sy, 0, 767)
		idx = I32.plus_wrap(I32.times_wrap(cy, 1024), cx)
		({
			(dev1, texel) = Device.load(dev, buf, idx)
			({
				c = rd_extract(texel, ch)
				rd_gather(dev1, buf, px, py, ch, I32.plus_wrap(k, 1), I32.plus_wrap(acc, c))
			})
		})
	}) })

	radial_step : Device.Device, I32, I32, I32, I32 -> (Device.Device, I32)
	radial_step = |dev, scenebuf, outb, _frame, gid| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, rd_width), rd_width))
		py = Device.div(gid, rd_width)
		({
			(dev1, own) = Device.load(dev, scenebuf, gid)
			(dev2, rr) = rd_gather(dev1, scenebuf, px, py, 0, 0, 0)
			(dev3, rg) = rd_gather(dev2, scenebuf, px, py, 1, 0, 0)
			(dev4, rb) = rd_gather(dev3, scenebuf, px, py, 2, 0, 0)
			({
				fr = rd_clamp(I32.plus_wrap(Device.div(rr, rd_taps), Device.div(rd_extract(own, 0), 3)), 0, 255)
				fg = rd_clamp(I32.plus_wrap(Device.div(rg, rd_taps), Device.div(rd_extract(own, 1), 3)), 0, 255)
				fb = rd_clamp(I32.plus_wrap(Device.div(rb, rd_taps), Device.div(rd_extract(own, 2), 3)), 0, 255)
				Device.store(dev4, outb, gid, I32.plus_wrap(I32.plus_wrap(I32.times_wrap(fr, 65536), I32.times_wrap(fg, 256)), fb))
			})
		})
	})
}
