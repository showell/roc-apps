# TextureKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

TextureKernel :: [].{

	tx_width : I64
	tx_width = 1024

	tx_half_w : I64
	tx_half_w = 512

	tx_horizon : I64
	tx_horizon = 300

	tx_focal : I64
	tx_focal = 420

	tx_scale : I64
	tx_scale = 52000

	tx_tile : I64 -> I64
	tx_tile = |w| ({
		m = (w - (I64.div_trunc_by(w, 256) * 256))
		(if (m < 0) { (m + 256) } else { m })
	})

	tx_sky : I64 -> I64
	tx_sky = |py| ({
		h = I64.div_trunc_by((py * 255), tx_horizon)
		r = (20 + I64.div_trunc_by((h * 20), 255))
		g = (30 + I64.div_trunc_by((h * 40), 255))
		b = (60 + I64.div_trunc_by((h * 120), 255))
		(((r * 65536) + (g * 256)) + b)
	})

	tx_shade : I64, I64 -> I64
	tx_shade = |texel, fog| ({
		r = I64.div_trunc_by(texel, 65536)
		g = (I64.div_trunc_by(texel, 256) - (I64.div_trunc_by(texel, 65536) * 256))
		b = (texel - (I64.div_trunc_by(texel, 256) * 256))
		hr = 60
		hg = 70
		hb = 95
		sr = I64.div_trunc_by(((r * fog) + (hr * (256 - fog))), 256)
		sg = I64.div_trunc_by(((g * fog) + (hg * (256 - fog))), 256)
		sb = I64.div_trunc_by(((b * fog) + (hb * (256 - fog))), 256)
		(((sr * 65536) + (sg * 256)) + sb)
	})

	texture_step : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	texture_step = |dev, texbuf, outb, frame, gid| ({
		px = (gid - (I64.div_trunc_by(gid, tx_width) * tx_width))
		py = I64.div_trunc_by(gid, tx_width)
		sy = (py - tx_horizon)
		sky = (sy <= 0)
		d = (if sky { 1 } else { I64.div_trunc_by(tx_scale, sy) })
		wx = I64.div_trunc_by(((px - tx_half_w) * d), tx_focal)
		wz = (d + (frame * 3))
		u = tx_tile(wx)
		v = tx_tile(wz)
		idx = (if sky { 0 } else { ((v * 256) + u) })
		fog = (if (sy > 256) { 256 } else { sy })
		({
			(dev1, texel) = Device.load(dev, texbuf, idx)
			({
				out = (if sky { tx_sky(py) } else { tx_shade(texel, fog) })
				Device.store(dev1, outb, gid, out)
			})
		})
	})
}
