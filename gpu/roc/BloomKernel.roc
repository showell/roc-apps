# BloomKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

BloomKernel :: [].{

	bl_width : I32
	bl_width = 1024

	bl_height : I32
	bl_height = 768

	bl_taps : I32
	bl_taps = 40

	bl_clamp : I32, I32, I32 -> I32
	bl_clamp = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	bl_extract : I32, I32 -> I32
	bl_extract = |texel, ch| (if (ch == 0) { Device.div(texel, 65536) } else { (if (ch == 1) { I32.minus_wrap(Device.div(texel, 256), I32.times_wrap(Device.div(texel, 65536), 256)) } else { I32.minus_wrap(texel, I32.times_wrap(Device.div(texel, 256), 256)) }) })

	bl_glow : Device.Device, I32, I32, I32, I32, I32, I32 -> (Device.Device, I32)
	bl_glow = |dev, buf, px, py, ch, k, acc| (if (k >= bl_taps) { (dev, acc) } else { ({
		ang = (I32.to_f32(k) * 2.399)
		rad = (DeviceMath.real_sqrt(I32.to_f32(k)) * 3.4)
		dx = F32.to_i32_wrap((DeviceMath.real_cos(ang) * rad))
		dy = F32.to_i32_wrap((DeviceMath.real_sin(ang) * rad))
		sx = bl_clamp(I32.plus_wrap(px, dx), 0, 1023)
		sy = bl_clamp(I32.plus_wrap(py, dy), 0, 767)
		idx = I32.plus_wrap(I32.times_wrap(sy, 1024), sx)
		({
			(dev1, texel) = Device.load(dev, buf, idx)
			({
				c = bl_extract(texel, ch)
				bright = (if (c > 150) { I32.minus_wrap(c, 150) } else { 0 })
				bl_glow(dev1, buf, px, py, ch, I32.plus_wrap(k, 1), I32.plus_wrap(acc, bright))
			})
		})
	}) })

	bloom_step : Device.Device, I32, I32, I32, I32 -> (Device.Device, I32)
	bloom_step = |dev, scenebuf, outb, _frame, gid| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, bl_width), bl_width))
		py = Device.div(gid, bl_width)
		({
			(dev1, base) = Device.load(dev, scenebuf, gid)
			(dev2, gr) = bl_glow(dev1, scenebuf, px, py, 0, 0, 0)
			(dev3, gg) = bl_glow(dev2, scenebuf, px, py, 1, 0, 0)
			(dev4, gb) = bl_glow(dev3, scenebuf, px, py, 2, 0, 0)
			({
				br = Device.div(base, 65536)
				bg = I32.minus_wrap(Device.div(base, 256), I32.times_wrap(Device.div(base, 65536), 256))
				bb = I32.minus_wrap(base, I32.times_wrap(Device.div(base, 256), 256))
				fr = bl_clamp(I32.plus_wrap(br, Device.div(gr, 34)), 0, 255)
				fg = bl_clamp(I32.plus_wrap(bg, Device.div(gg, 34)), 0, 255)
				fb = bl_clamp(I32.plus_wrap(bb, Device.div(gb, 34)), 0, 255)
				Device.store(dev4, outb, gid, I32.plus_wrap(I32.plus_wrap(I32.times_wrap(fr, 65536), I32.times_wrap(fg, 256)), fb))
			})
		})
	})
}
