# PipelinesKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

PipelinesKernel :: [].{

	pl_width : I32
	pl_width = 1024

	pl_half_w : I32
	pl_half_w = 512

	pl_half_h : I32
	pl_half_h = 384

	pl_count : I32
	pl_count = 6

	pl_cx : I32 -> F32
	pl_cx = |i| ((I32.to_f32(i) * 1.2) - 3.0)

	pl_hit : F32, F32, F32, F32, F32, F32, I32 -> F32
	pl_hit = |ox, oy, oz, dx, dy, dz, i| ({
		lx = (ox - pl_cx(i))
		b = (((dx * lx) + (dy * oy)) + (dz * oz))
		c = ((((lx * lx) + (oy * oy)) + (oz * oz)) - 0.3025)
		disc = ((b * b) - c)
		(if (disc < 0.0) { (0.0 - 1.0) } else { ({
			t = ((0.0 - b) - DeviceMath.real_sqrt(disc))
			(if (t > 0.001) { t } else { (0.0 - 1.0) })
		}) })
	})

	pl_nearest : F32, F32, F32, F32, F32, F32, I32, I32, F32 -> I32
	pl_nearest = |ox, oy, oz, dx, dy, dz, i, bid, bt| (if (i >= pl_count) { bid } else { ({
		t = pl_hit(ox, oy, oz, dx, dy, dz, i)
		take = (if (t > 0.001) { (if (bt < 0.0) { 1 } else { (if (t < bt) { 1 } else { 0 }) }) } else { 0 })
		(if (take == 1) { pl_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), i, t) } else { pl_nearest(ox, oy, oz, dx, dy, dz, I32.plus_wrap(i, 1), bid, bt) })
	}) })

	pl_clamp01 : F32 -> F32
	pl_clamp01 = |x| DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, x))

	pl_pack : F32, F32, F32 -> I32
	pl_pack = |r, g, b| I32.plus_wrap(I32.plus_wrap(I32.times_wrap(F32.to_i32_wrap((pl_clamp01(r) * 255.0)), 65536), I32.times_wrap(F32.to_i32_wrap((pl_clamp01(g) * 255.0)), 256)), F32.to_i32_wrap((pl_clamp01(b) * 255.0)))

	pl_render : I32, I32 -> I32
	pl_render = |gid, frame| ({
		px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, pl_width), pl_width))
		py = Device.div(gid, pl_width)
		fx = (I32.to_f32(I32.minus_wrap(px, pl_half_w)) / 384.0)
		fy = (I32.to_f32(I32.minus_wrap(pl_half_h, py)) / 384.0)
		rl = DeviceMath.real_sqrt((((fx * fx) + (fy * fy)) + 4.0))
		dx = (fx / rl)
		dy = (fy / rl)
		dz = (2.0 / rl)
		oz = (0.0 - 5.0)
		id = pl_nearest(0.0, 0.0, oz, dx, dy, dz, 0, I32.minus_wrap(0, 1), (0.0 - 1.0))
		(if (id < 0) { ({
			h = pl_clamp01(((dy * 0.5) + 0.5))
			pl_pack((0.05 + (h * 0.05)), (0.06 + (h * 0.08)), (0.1 + (h * 0.14)))
		}) } else { ({
			t = pl_hit(0.0, 0.0, oz, dx, dy, dz, id)
			hx = (dx * t)
			hy = (dy * t)
			hz = (oz + (dz * t))
			nx = ((hx - pl_cx(id)) / 0.55)
			ny = (hy / 0.55)
			nz = (hz / 0.55)
			la = (I32.to_f32(frame) / 30.0)
			lx = (DeviceMath.real_cos(la) * 0.5)
			ly = 0.7
			lz = ((DeviceMath.real_sin(la) * 0.5) - 0.4)
			ll = DeviceMath.real_sqrt((((lx * lx) + (ly * ly)) + (lz * lz)))
			ndl = DeviceMath.real_max(0.0, ((((nx * lx) / ll) + ((ny * ly) / ll)) + ((nz * lz) / ll)))
			vdn = (0.0 - (((dx * nx) + (dy * ny)) + (dz * nz)))
			hlx = ((lx / ll) - dx)
			hly = ((ly / ll) - dy)
			hlz = ((lz / ll) - dz)
			hl = (DeviceMath.real_sqrt((((hlx * hlx) + (hly * hly)) + (hlz * hlz))) + 0.001)
			spec = DeviceMath.real_max(0.0, ((((nx * hlx) / hl) + ((ny * hly) / hl)) + ((nz * hlz) / hl)))
			s2 = (spec * spec)
			s8 = (((s2 * s2) * s2) * s2)
			(if (id == 0) { pl_pack(0.55, 0.35, 0.75) } else { (if (id == 1) { pl_pack((0.3 * (0.2 + ndl)), (0.6 * (0.2 + ndl)), (0.9 * (0.2 + ndl))) } else { (if (id == 2) { pl_pack(((0.85 * ndl) + s8), ((0.5 * ndl) + s8), ((0.3 * ndl) + s8)) } else { (if (id == 3) { ({
				band = (if (ndl > 0.75) { 1.0 } else { (if (ndl > 0.4) { 0.65 } else { (if (ndl > 0.15) { 0.38 } else { 0.18 }) }) })
				pl_pack((0.9 * band), (0.55 * band), (0.35 * band))
			}) } else { (if (id == 4) { pl_pack(((nx * 0.5) + 0.5), ((ny * 0.5) + 0.5), ((nz * 0.5) + 0.5)) } else { ({
				fres = pl_clamp01((1.0 - vdn))
				f5 = ((((fres * fres) * fres) * fres) * fres)
				pl_pack((0.1 + (f5 * 0.9)), (0.15 + (f5 * 0.85)), (0.25 + (f5 * 0.75)))
			}) }) }) }) }) })
		}) })
	})

	pipelines_step : Device.Device, I32, I32, I32 -> (Device.Device, I32)
	pipelines_step = |dev, outb, frame, gid| ({
		Device.store(dev, outb, gid, pl_render(gid, frame))
	})
}
