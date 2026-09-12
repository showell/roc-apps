# RadialKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

RadialKernel :: [].{

	rd_width : I64
	rd_width = 1024

	rd_half_w : I64
	rd_half_w = 512

	rd_half_h : I64
	rd_half_h = 384

	rd_taps : I64
	rd_taps = 28

	rd_clamp : I64, I64, I64 -> I64
	rd_clamp = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	rd_extract : I64, I64 -> I64
	rd_extract = |texel, ch| (if (ch == 0) { I64.div_trunc_by(texel, 65536) } else { (if (ch == 1) { (I64.div_trunc_by(texel, 256) - (I64.div_trunc_by(texel, 65536) * 256)) } else { (texel - (I64.div_trunc_by(texel, 256) * 256)) }) })

	rd_gather : Device.Device, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	rd_gather = |dev, buf, px, py, ch, k, acc| (if (k >= rd_taps) { (dev, acc) } else { ({
		scale = (1.0 - (I64.to_f64(k) * 0.0075))
		sx = (rd_half_w + F64.to_i64_wrap((I64.to_f64((px - rd_half_w)) * scale)))
		sy = (rd_half_h + F64.to_i64_wrap((I64.to_f64((py - rd_half_h)) * scale)))
		cx = rd_clamp(sx, 0, 1023)
		cy = rd_clamp(sy, 0, 767)
		idx = ((cy * 1024) + cx)
		({
			(dev1, texel) = Device.load(dev, buf, idx)
			({
				c = rd_extract(texel, ch)
				rd_gather(dev1, buf, px, py, ch, (k + 1), (acc + c))
			})
		})
	}) })

	radial_step : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	radial_step = |dev, scenebuf, outb, _frame, gid| ({
		px = (gid - (I64.div_trunc_by(gid, rd_width) * rd_width))
		py = I64.div_trunc_by(gid, rd_width)
		({
			(dev1, own) = Device.load(dev, scenebuf, gid)
			(dev2, rr) = rd_gather(dev1, scenebuf, px, py, 0, 0, 0)
			(dev3, rg) = rd_gather(dev2, scenebuf, px, py, 1, 0, 0)
			(dev4, rb) = rd_gather(dev3, scenebuf, px, py, 2, 0, 0)
			({
				fr = rd_clamp((I64.div_trunc_by(rr, rd_taps) + I64.div_trunc_by(rd_extract(own, 0), 3)), 0, 255)
				fg = rd_clamp((I64.div_trunc_by(rg, rd_taps) + I64.div_trunc_by(rd_extract(own, 1), 3)), 0, 255)
				fb = rd_clamp((I64.div_trunc_by(rb, rd_taps) + I64.div_trunc_by(rd_extract(own, 2), 3)), 0, 255)
				Device.store(dev4, outb, gid, (((fr * 65536) + (fg * 256)) + fb))
			})
		})
	})
}
