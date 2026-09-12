# EarthKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

EarthKernel :: [].{

	cordic_sin : F64 -> F64
	cordic_sin = |x| DeviceMath.real_sin(x)

	cordic_cos : F64 -> F64
	cordic_cos = |x| DeviceMath.real_cos(x)

	atan2_real : F64, F64 -> F64
	atan2_real = |y, x| ({
		ax = (if (x < 0.0) { (0.0 - x) } else { x })
		ay = (if (y < 0.0) { (0.0 - y) } else { y })
		swap = (if (ay > ax) { 1 } else { 0 })
		cx = (if (swap == 1) { ay } else { ax })
		cy = (if (swap == 1) { ax } else { ay })
		angle = cordic_iterate(cx, cy, 0.0, 0)
		a1 = (if (swap == 1) { (1.5707963267949 - angle) } else { angle })
		a2 = (if (x < 0.0) { (3.14159265358979 - a1) } else { a1 })
		(if (y < 0.0) { (0.0 - a2) } else { a2 })
	})

	cordic_iterate : F64, F64, F64, I64 -> F64
	cordic_iterate = |cx, cy, angle, i| (if (i >= 16) { angle } else { ({
		atan_table_val = cordic_atan_val(i)
		power = cordic_power(i)
		(if (cy > 0.0) { ({
			nx = (cx + (cy * power))
			ny = (cy - (cx * power))
			cordic_iterate(nx, ny, (angle + atan_table_val), (i + 1))
		}) } else { ({
			nx = (cx - (cy * power))
			ny = (cy + (cx * power))
			cordic_iterate(nx, ny, (angle - atan_table_val), (i + 1))
		}) })
	}) })

	cordic_atan_val : I64 -> F64
	cordic_atan_val = |i| (if (i == 0) { 0.7853981633974483 } else { (if (i == 1) { 0.4636476090008061 } else { (if (i == 2) { 0.24497866312686414 } else { (if (i == 3) { 0.12435499454676144 } else { (if (i == 4) { 0.06241880999595735 } else { (if (i == 5) { 0.031239833430268277 } else { (if (i == 6) { 0.015623728620476831 } else { (if (i == 7) { 0.007812341060101111 } else { (if (i == 8) { 0.0039062301319669718 } else { (if (i == 9) { 0.0019531225164788188 } else { (if (i == 10) { 0.0009765621895593195 } else { (if (i == 11) { 0.0004882812111948983 } else { (if (i == 12) { 0.00024414062014936177 } else { (if (i == 13) { 0.00012207031189367021 } else { (if (i == 14) { F64.from_bits(4544132024005645653) } else { F64.from_bits(4539628424386663765) }) }) }) }) }) }) }) }) }) }) }) }) }) }) })

	cordic_power : I64 -> F64
	cordic_power = |i| (if (i == 0) { 1.0 } else { (if (i == 1) { 0.5 } else { (if (i == 2) { 0.25 } else { (if (i == 3) { 0.125 } else { (if (i == 4) { 0.0625 } else { (if (i == 5) { 0.03125 } else { (if (i == 6) { 0.015625 } else { (if (i == 7) { 0.0078125 } else { (if (i == 8) { 0.00390625 } else { (if (i == 9) { 0.001953125 } else { (if (i == 10) { 0.0009765625 } else { (if (i == 11) { 0.00048828125 } else { (if (i == 12) { 0.000244140625 } else { (if (i == 13) { 0.0001220703125 } else { (if (i == 14) { F64.from_bits(4544132024016830464) } else { F64.from_bits(4539628424389459968) }) }) }) }) }) }) }) }) }) }) }) }) }) }) })

	int_to_real : I64 -> F64
	int_to_real = |n| I64.to_f64(n)

	real_to_int : F64 -> I64
	real_to_int = |r| F64.to_i64_wrap(r)

	clamp_int : I64, I64, I64 -> I64
	clamp_int = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	earth_sky : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	earth_sky = |dev, framebuf, gid, _px, _py| ({
		pixel = (255 * 16777216)
		Device.store(dev, framebuf, gid, pixel)
	})

	earth_pixel : Device.Device, I64, I64, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	earth_pixel = |dev, framebuf, tex, params, tw, th, w, h, pixel_count| ({
		(dev1, tid) = Device.thread_idx_x(dev)
		(dev2, bid) = Device.block_idx_x(dev1)
		(dev3, bdim) = Device.block_dim_x(dev2)
		({
			gid = ((bid * bdim) + tid)
			(if (gid < pixel_count) { earth_pixel_work(dev3, framebuf, tex, params, tw, th, w, h, gid) } else { (dev3, 0) })
		})
	})

	earth_pixel_work : Device.Device, I64, I64, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	earth_pixel_work = |dev, framebuf, tex, params, tw, th, w, h, gid| ({
		(dev1, i_aspect) = Device.load(dev, params, 0)
		(dev2, i_zoom) = Device.load(dev1, params, 1)
		(dev3, i_cam_pitch) = Device.load(dev2, params, 2)
		(dev4, i_earth_yaw) = Device.load(dev3, params, 3)
		(dev5, i_earth_pitch) = Device.load(dev4, params, 4)
		(dev6, i_sun_x) = Device.load(dev5, params, 5)
		(dev7, i_sun_y) = Device.load(dev6, params, 6)
		(dev8, i_sun_z) = Device.load(dev7, params, 7)
		({
			px = (gid - (I64.div_trunc_by(gid, w) * w))
			py = I64.div_trunc_by(gid, w)
			aspect = (int_to_real(i_aspect) / 1000.0)
			zoom = (int_to_real(i_zoom) / 1000.0)
			cam_pitch = (int_to_real(i_cam_pitch) / 1000.0)
			earth_yaw = (int_to_real(i_earth_yaw) / 1000.0)
			earth_pitch = (int_to_real(i_earth_pitch) / 1000.0)
			_sun_x = (int_to_real(i_sun_x) / 1000.0)
			_sun_y = (int_to_real(i_sun_y) / 1000.0)
			_sun_z = (int_to_real(i_sun_z) / 1000.0)
			ndx = ((((int_to_real(px) / int_to_real(w)) - 0.5) * 2.0) * aspect)
			ndy = ((0.5 - (int_to_real(py) / int_to_real(h))) * 2.0)
			rlen = DeviceMath.real_sqrt((((ndx * ndx) + (ndy * ndy)) + 1.0))
			rdx = (ndx / rlen)
			rdy = (ndy / rlen)
			rdz = (1.0 / rlen)
			cos_cp = cordic_cos(cam_pitch)
			sin_cp = cordic_sin(cam_pitch)
			dx = rdx
			dy = ((cos_cp * rdy) - (sin_cp * rdz))
			dz = ((sin_cp * rdy) + (cos_cp * rdz))
			neg_zoom = (0.0 - zoom)
			oy = (0.0 - (sin_cp * neg_zoom))
			oz = (cos_cp * neg_zoom)
			b = (2.0 * ((oy * dy) + (oz * dz)))
			c = (((oy * oy) + (oz * oz)) - 1.0)
			disc = ((b * b) - (4.0 * c))
			(if (disc < 0.0) { earth_sky(dev8, framebuf, gid, px, py) } else { ({
				t = (((0.0 - b) - DeviceMath.real_sqrt(disc)) / 2.0)
				(if (t < 0.001) { earth_sky(dev8, framebuf, gid, px, py) } else { ({
					hx = (t * dx)
					hy = (oy + (t * dy))
					hz = (oz + (t * dz))
					cos_ey = cordic_cos(earth_yaw)
					sin_ey = cordic_sin(earth_yaw)
					cos_ep = cordic_cos(earth_pitch)
					sin_ep = cordic_sin(earth_pitch)
					ry = ((cos_ep * hy) - (sin_ep * hz))
					rz = ((sin_ep * hy) + (cos_ep * hz))
					gx = ((cos_ey * hx) + (sin_ey * rz))
					gy = ry
					gz = ((0.0 - (sin_ey * hx)) + (cos_ey * rz))
					lat = atan2_real(gy, DeviceMath.real_sqrt(((gx * gx) + (gz * gz))))
					lon = atan2_real(gx, gz)
					pi = 3.14159265358979
					u = (1.0 - (((lon / pi) + 1.0) * 0.5))
					v = (0.5 - (lat / pi))
					tx_raw = real_to_int((u * int_to_real(tw)))
					tx_mod = (tx_raw - (I64.div_trunc_by(tx_raw, tw) * tw))
					tx_idx = (if (tx_mod < 0) { (tx_mod + tw) } else { tx_mod })
					ty_idx = clamp_int(real_to_int((v * int_to_real(th))), 0, (th - 1))
					_ti = (((ty_idx * tw) + tx_idx) * 3)
					raw_u = ((hx + 1.0) * 0.5)
					raw_v = ((hy + 1.0) * 0.5)
					rtx = clamp_int(real_to_int((raw_u * int_to_real(tw))), 0, (tw - 1))
					rty = clamp_int(real_to_int((raw_v * int_to_real(th))), 0, (th - 1))
					rti = (((rty * tw) + rtx) * 3)
					({
						(dev9, rr) = Device.load(dev8, tex, rti)
						(dev10, rg) = Device.load(dev9, tex, (rti + 1))
						(dev11, rb) = Device.load(dev10, tex, (rti + 2))
						({
							pixel = ((((clamp_int(rr, 0, 255) * 65536) + (clamp_int(rg, 0, 255) * 256)) + clamp_int(rb, 0, 255)) + (255 * 16777216))
							Device.store(dev11, framebuf, gid, pixel)
						})
					})
				}) })
			}) })
		})
	})
}
