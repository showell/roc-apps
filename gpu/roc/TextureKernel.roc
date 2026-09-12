# TextureKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

TextureKernel :: [].{

	tx_width : I32
	tx_width = 1024

	tx_half_w : I32
	tx_half_w = 512

	tx_horizon : I32
	tx_horizon = 300

	tx_focal : I32
	tx_focal = 420

	tx_scale : I32
	tx_scale = 52000

	tx_tile : I32 -> I32
	tx_tile = |w| ({
		m = I32.minus_wrap(w, I32.times_wrap(Device.div(w, 256), 256))
		(if (m < 0) { I32.plus_wrap(m, 256) } else { m })
	})

	tx_sky : I32 -> I32
	tx_sky = |py| ({
		h = Device.div(I32.times_wrap(py, 255), tx_horizon)
		r = I32.plus_wrap(20, Device.div(I32.times_wrap(h, 20), 255))
		g = I32.plus_wrap(30, Device.div(I32.times_wrap(h, 40), 255))
		b = I32.plus_wrap(60, Device.div(I32.times_wrap(h, 120), 255))
		I32.plus_wrap(I32.plus_wrap(I32.times_wrap(r, 65536), I32.times_wrap(g, 256)), b)
	})

	tx_shade : I32, I32 -> I32
	tx_shade = |texel, fog| ({
		r = Device.div(texel, 65536)
		g = I32.minus_wrap(Device.div(texel, 256), I32.times_wrap(Device.div(texel, 65536), 256))
		b = I32.minus_wrap(texel, I32.times_wrap(Device.div(texel, 256), 256))
		hr = 60
		hg = 70
		hb = 95
		sr = Device.div(I32.plus_wrap(I32.times_wrap(r, fog), I32.times_wrap(hr, I32.minus_wrap(256, fog))), 256)
		sg = Device.div(I32.plus_wrap(I32.times_wrap(g, fog), I32.times_wrap(hg, I32.minus_wrap(256, fog))), 256)
		sb = Device.div(I32.plus_wrap(I32.times_wrap(b, fog), I32.times_wrap(hb, I32.minus_wrap(256, fog))), 256)
		I32.plus_wrap(I32.plus_wrap(I32.times_wrap(sr, 65536), I32.times_wrap(sg, 256)), sb)
	})

	texture_step : Device.Device, I32, I32, I32, I32 -> (Device.Device, I32)
	texture_step = |dev, texbuf, outb, frame, gid| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, tx_width), tx_width))
		py = Device.div(gid, tx_width)
		sy = I32.minus_wrap(py, tx_horizon)
		sky = (sy <= 0)
		d = (if sky { 1 } else { Device.div(tx_scale, sy) })
		wx = Device.div(I32.times_wrap(I32.minus_wrap(px, tx_half_w), d), tx_focal)
		wz = I32.plus_wrap(d, I32.times_wrap(frame, 3))
		u = tx_tile(wx)
		v = tx_tile(wz)
		idx = (if sky { 0 } else { I32.plus_wrap(I32.times_wrap(v, 256), u) })
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
