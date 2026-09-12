# BloomKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

BloomKernel :: [].{

	bl_width : I64
	bl_width = 1024

	bl_height : I64
	bl_height = 768

	bl_taps : I64
	bl_taps = 40

	bl_clamp : I64, I64, I64 -> I64
	bl_clamp = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	bl_extract : I64, I64 -> I64
	bl_extract = |texel, ch| (if (ch == 0) { I64.div_trunc_by(texel, 65536) } else { (if (ch == 1) { (I64.div_trunc_by(texel, 256) - (I64.div_trunc_by(texel, 65536) * 256)) } else { (texel - (I64.div_trunc_by(texel, 256) * 256)) }) })

	bl_glow : Device.Device, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	bl_glow = |dev, buf, px, py, ch, k, acc| (if (k >= bl_taps) { (dev, acc) } else { ({
		ang = (I64.to_f64(k) * 2.399)
		rad = (DeviceMath.real_sqrt(I64.to_f64(k)) * 3.4)
		dx = F64.to_i64_wrap((DeviceMath.real_cos(ang) * rad))
		dy = F64.to_i64_wrap((DeviceMath.real_sin(ang) * rad))
		sx = bl_clamp((px + dx), 0, 1023)
		sy = bl_clamp((py + dy), 0, 767)
		idx = ((sy * 1024) + sx)
		({
			(dev1, texel) = Device.load(dev, buf, idx)
			({
				c = bl_extract(texel, ch)
				bright = (if (c > 150) { (c - 150) } else { 0 })
				bl_glow(dev1, buf, px, py, ch, (k + 1), (acc + bright))
			})
		})
	}) })

	bloom_step : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	bloom_step = |dev, scenebuf, outb, _frame, gid| ({
		px = (gid - (I64.div_trunc_by(gid, bl_width) * bl_width))
		py = I64.div_trunc_by(gid, bl_width)
		({
			(dev1, base) = Device.load(dev, scenebuf, gid)
			(dev2, gr) = bl_glow(dev1, scenebuf, px, py, 0, 0, 0)
			(dev3, gg) = bl_glow(dev2, scenebuf, px, py, 1, 0, 0)
			(dev4, gb) = bl_glow(dev3, scenebuf, px, py, 2, 0, 0)
			({
				br = I64.div_trunc_by(base, 65536)
				bg = (I64.div_trunc_by(base, 256) - (I64.div_trunc_by(base, 65536) * 256))
				bb = (base - (I64.div_trunc_by(base, 256) * 256))
				fr = bl_clamp((br + I64.div_trunc_by(gr, 34)), 0, 255)
				fg = bl_clamp((bg + I64.div_trunc_by(gg, 34)), 0, 255)
				fb = bl_clamp((bb + I64.div_trunc_by(gb, 34)), 0, 255)
				Device.store(dev4, outb, gid, (((fr * 65536) + (fg * 256)) + fb))
			})
		})
	})
}
