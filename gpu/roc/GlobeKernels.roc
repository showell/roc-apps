# GlobeKernels -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

GlobeKernels :: [].{

	cordic_sin : F64 -> F64
	cordic_sin = |x| DeviceMath.real_sin(x)

	cordic_cos : F64 -> F64
	cordic_cos = |x| DeviceMath.real_cos(x)

	opening : Device.Device -> (Device.Device, I64)
	opening = |dev| ({
		(dev1, a) = earth_pixel(dev, 0, 0, 0, 0, 0, 0, 0, 0)
		(dev2, b) = bh_pixel(dev1, 0, 0, 0, 0, 0)
		(dev2, (a + b))
	})

	earth_pixel : Device.Device, I64, I64, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	earth_pixel = |dev, framebuf, tex, params, tw, th, w, h, gid| ({
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
			sun_x = (int_to_real(i_sun_x) / 1000.0)
			sun_y = (int_to_real(i_sun_y) / 1000.0)
			sun_z = (int_to_real(i_sun_z) / 1000.0)
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
			t = (if (disc < 0.0) { (0.0 - 1.0) } else { ({
				tv = (((0.0 - b) - DeviceMath.real_sqrt(disc)) / 2.0)
				(if (tv > 0.001) { tv } else { (0.0 - 1.0) })
			}) })
			(if (t > 0.001) { ({
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
				lat = asin_approx(gy)
				lon = atan2_approx(gx, gz)
				pi = 3.14159265358979
				u = (1.0 - (((lon / pi) + 1.0) * 0.5))
				v = (0.5 - (lat / pi))
				tx_raw = real_to_int((u * int_to_real(tw)))
				tx_idx = (tx_raw - (I64.div_trunc_by(tx_raw, tw) * tw))
				ty_idx = clamp_int(real_to_int((v * int_to_real(th))), 0, (th - 1))
				ti = (((ty_idx * tw) + tx_idx) * 3)
				earth_shade_pixel(dev8, framebuf, tex, gid, ti, hx, hy, hz, sun_x, sun_y, sun_z)
			}) } else { ({
				miss = (DeviceMath.real_sqrt(DeviceMath.real_max(0.0, ((c + 1.0) - ((b * b) / 4.0)))) - 1.0)
				earth_sky_pixel(dev8, framebuf, gid, miss)
			}) })
		})
	})

	earth_shade_pixel : Device.Device, I64, I64, I64, I64, F64, F64, F64, F64, F64, F64 -> (Device.Device, I64)
	earth_shade_pixel = |dev, framebuf, tex, gid, ti, hx, hy, hz, sx, sy, sz| ({
		(dev1, tr) = Device.load(dev, tex, ti)
		(dev2, tg) = Device.load(dev1, tex, (ti + 1))
		(dev3, tb) = Device.load(dev2, tex, (ti + 2))
		({
			dot = (((hx * sx) + (hy * sy)) + (hz * sz))
			sun = DeviceMath.real_max(0.0, dot)
			diff = (0.12 + (sun * 1.3))
			rim = DeviceMath.real_sqrt(((hx * hx) + (hy * hy)))
			atmo = (((rim * rim) * rim) * 0.6)
			cr = clamp_int(real_to_int(((int_to_real(tr) * diff) + (atmo * 70.0))), 0, 255)
			cg = clamp_int(real_to_int(((int_to_real(tg) * diff) + (atmo * 130.0))), 0, 255)
			cb = clamp_int(real_to_int(((int_to_real(tb) * diff) + (atmo * 255.0))), 0, 255)
			pixel = ((((cr * 65536) + (cg * 256)) + cb) + (255 * 16777216))
			Device.store(dev3, framebuf, gid, pixel)
		})
	})

	earth_sky_pixel : Device.Device, I64, I64, F64 -> (Device.Device, I64)
	earth_sky_pixel = |dev, framebuf, gid, miss| ({
		glow = DeviceMath.real_max(0.0, (1.0 - (miss * 12.0)))
		g2 = (glow * glow)
		cr = clamp_int(real_to_int((g2 * 25.0)), 0, 255)
		cg = clamp_int(real_to_int((g2 * 50.0)), 0, 255)
		cb = clamp_int(real_to_int((g2 * 160.0)), 0, 255)
		pixel = ((((cr * 65536) + (cg * 256)) + cb) + (255 * 16777216))
		Device.store(dev, framebuf, gid, pixel)
	})

	bh_pixel : Device.Device, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	bh_pixel = |dev, framebuf, params, w, h, gid| ({
		(dev1, i_aspect) = Device.load(dev, params, 0)
		(dev2, i_zoom) = Device.load(dev1, params, 1)
		(dev3, i_cam_pitch) = Device.load(dev2, params, 2)
		(dev4, i_cam_yaw) = Device.load(dev3, params, 3)
		(dev5, i_bh_time) = Device.load(dev4, params, 4)
		({
			px = (gid - (I64.div_trunc_by(gid, w) * w))
			py = I64.div_trunc_by(gid, w)
			aspect = (int_to_real(i_aspect) / 1000.0)
			zoom = (int_to_real(i_zoom) / 1000.0)
			cp = (int_to_real(i_cam_pitch) / 1000.0)
			cy = (int_to_real(i_cam_yaw) / 1000.0)
			time = (int_to_real(i_bh_time) / 1000.0)
			ndx = ((((int_to_real(px) / int_to_real(w)) - 0.5) * 2.0) * aspect)
			ndy = ((0.5 - (int_to_real(py) / int_to_real(h))) * 2.0)
			rlen = DeviceMath.real_sqrt((((ndx * ndx) + (ndy * ndy)) + 5.76))
			rdx = (ndx / rlen)
			rdy = (ndy / rlen)
			rdz = (2.4 / rlen)
			cos_y = cordic_cos(cy)
			sin_y = cordic_sin(cy)
			cos_p = cordic_cos(cp)
			sin_p = cordic_sin(cp)
			d1x = ((cos_y * rdx) + (sin_y * rdz))
			d1z = ((0.0 - (sin_y * rdx)) + (cos_y * rdz))
			vx = d1x
			vy = ((cos_p * rdy) - (sin_p * d1z))
			vz = ((sin_p * rdy) + (cos_p * d1z))
			neg_zoom = (0.0 - zoom)
			o1x = (sin_y * neg_zoom)
			o1z = (cos_y * neg_zoom)
			posx = o1x
			posy = (0.0 - (sin_p * o1z))
			posz = (cos_p * o1z)
			bh_march(dev5, framebuf, gid, posx, posy, posz, vx, vy, vz, time, 0, 0.0, 0.0, 0.0, 0.0)
		})
	})

	bh_march : Device.Device, I64, I64, F64, F64, F64, F64, F64, F64, F64, I64, F64, F64, F64, F64 -> (Device.Device, I64)
	bh_march = |dev, framebuf, gid, px, py, pz, vx, vy, vz, time, step, cr, cg, cb, opacity| (if (step >= 250) { bh_write(dev, framebuf, gid, cr, cg, cb, opacity, vx, vy, vz) } else { (if (opacity > 0.99) { bh_write(dev, framebuf, gid, cr, cg, cb, opacity, vx, vy, vz) } else { ({
		r = DeviceMath.real_sqrt((((px * px) + (py * py)) + (pz * pz)))
		(if (r < 0.32) { bh_write(dev, framebuf, gid, cr, cg, cb, 1.0, vx, vy, vz) } else { (if (r > 50.0) { bh_write(dev, framebuf, gid, cr, cg, cb, opacity, vx, vy, vz) } else { ({
			dt = DeviceMath.real_min(0.12, DeviceMath.real_max(0.003, (r * 0.04)))
			hcx = ((py * vz) - (pz * vy))
			hcy = ((pz * vx) - (px * vz))
			hcz = ((px * vy) - (py * vx))
			h2 = (((hcx * hcx) + (hcy * hcy)) + (hcz * hcz))
			r5 = ((((r * r) * r) * r) * r)
			gm = (((0.0 - 0.48) * h2) / r5)
			gx = ((px / r) * gm)
			gy = ((py / r) * gm)
			gz = ((pz / r) * gm)
			nvx = (vx + (gx * dt))
			nvy = (vy + (gy * dt))
			nvz = (vz + (gz * dt))
			vl = DeviceMath.real_sqrt((((nvx * nvx) + (nvy * nvy)) + (nvz * nvz)))
			nvx2 = (nvx / vl)
			nvy2 = (nvy / vl)
			nvz2 = (nvz / vl)
			npx = (px + (nvx2 * dt))
			npy = (py + (nvy2 * dt))
			npz = (pz + (nvz2 * dt))
			crossed = (if ((py * npy) < 0.0) { 1.0 } else { 0.0 })
			(if (crossed > 0.5) { ({
				tc = (py / (py - npy))
				cx = (px + ((npx - px) * tc))
				cz = (pz + ((npz - pz) * tc))
				disk_r = DeviceMath.real_sqrt(((cx * cx) + (cz * cz)))
				inner_fade = DeviceMath.real_min(1.0, DeviceMath.real_max(0.0, ((disk_r - 0.7) / 0.3)))
				outer_fade = DeviceMath.real_min(1.0, DeviceMath.real_max(0.0, ((2.2 - disk_r) / 0.4)))
				in_ring = (inner_fade * outer_fade)
				(if (in_ring > 0.01) { ({
					angle = atan2_approx(cz, cx)
					orbit = (angle + ((time * 1.5) / (disk_r * disk_r)))
					n1 = cordic_sin(((orbit * 3.0) + (disk_r * 2.0)))
					n2 = cordic_sin((((orbit * 7.0) + (disk_r * 0.5)) + 1.3))
					turb = ((0.65 + (n1 * 0.25)) + (n2 * 0.1))
					density = ((in_ring * 0.5) * turb)
					temp = DeviceMath.real_max(0.0, (1.0 - ((disk_r - 0.48) / 2.24)))
					grav = DeviceMath.real_sqrt(DeviceMath.real_max(0.0, (1.0 - (0.32 / r))))
					side = cordic_sin(angle)
					doppler = (if (side > 0.0) { (1.3 + (side * 0.5)) } else { (0.4 + ((1.0 + side) * 0.3)) })
					bright = ((grav * doppler) * density)
					t2 = (temp * temp)
					rem = (1.0 - opacity)
					ncr = (cr + ((bright * (1.2 + (t2 * 0.6))) * rem))
					ncg = (cg + ((bright * (0.9 + (temp * 0.5))) * rem))
					ncb = (cb + ((bright * (0.5 + (t2 * 0.4))) * rem))
					nop = DeviceMath.real_min((opacity + (density * 0.5)), 1.0)
					bh_march(dev, framebuf, gid, npx, npy, npz, nvx2, nvy2, nvz2, time, (step + 1), ncr, ncg, ncb, nop)
				}) } else { bh_march(dev, framebuf, gid, npx, npy, npz, nvx2, nvy2, nvz2, time, (step + 1), cr, cg, cb, opacity) })
			}) } else { bh_march(dev, framebuf, gid, npx, npy, npz, nvx2, nvy2, nvz2, time, (step + 1), cr, cg, cb, opacity) })
		}) }) })
	}) }) })

	bh_write : Device.Device, I64, I64, F64, F64, F64, F64, F64, F64, F64 -> (Device.Device, I64)
	bh_write = |dev, framebuf, gid, cr, cg, cb, _opacity, _vx, _vy, _vz| ({
		gr = gamma_byte(cr)
		gg = gamma_byte(cg)
		gb = gamma_byte(cb)
		pixel = ((((gr * 65536) + (gg * 256)) + gb) + (255 * 16777216))
		Device.store(dev, framebuf, gid, pixel)
	})

	sphere_hit : F64, F64, F64, F64, F64, F64, F64 -> F64
	sphere_hit = |ox, oy, oz, dx, dy, dz, r| ({
		b = (2.0 * (((ox * dx) + (oy * dy)) + (oz * dz)))
		c = ((((ox * ox) + (oy * oy)) + (oz * oz)) - (r * r))
		disc = ((b * b) - (4.0 * c))
		(if (disc < 0.0) { (0.0 - 1.0) } else { ({
			t = (((0.0 - b) - DeviceMath.real_sqrt(disc)) / 2.0)
			(if (t > 0.001) { t } else { (0.0 - 1.0) })
		}) })
	})

	asin_approx : F64 -> F64
	asin_approx = |x| ({
		clamped = DeviceMath.real_min(0.999, DeviceMath.real_max((0.0 - 0.999), x))
		atan2_approx(clamped, DeviceMath.real_sqrt((1.0 - (clamped * clamped))))
	})

	atan2_approx : F64, F64 -> F64
	atan2_approx = |y, x| cordic_atan2(y, x)

	gamma_byte : F64 -> I64
	gamma_byte = |v| ({
		clamped = DeviceMath.real_max(0.0, v)
		g = (DeviceMath.real_sqrt(DeviceMath.real_sqrt(clamped)) * DeviceMath.real_sqrt(clamped))
		clamp_int(real_to_int((g * 255.0)), 0, 255)
	})

	clamp_int : I64, I64, I64 -> I64
	clamp_int = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	int_to_real : I64 -> F64
	int_to_real = |n| I64.to_f64(n)

	real_to_int : F64 -> I64
	real_to_int = |r| F64.to_i64_wrap(r)

	cordic_atan2 : F64, F64 -> F64
	cordic_atan2 = |y, x| ({
		ax = DeviceMath.real_abs(x)
		ay = DeviceMath.real_abs(y)
		mn = DeviceMath.real_min(ax, ay)
		mx = DeviceMath.real_max(ax, ay)
		a = (if (mx > 0.0) { (mn / mx) } else { 0.0 })
		a2 = (a * a)
		numer = (105.0 + (55.0 * a2))
		denom = (105.0 + (a2 * (90.0 + (9.0 * a2))))
		t = (a * numer)
		base = (t / denom)
		r1 = (if (ay > ax) { (1.5707963267949 - base) } else { base })
		r2 = (if (x < 0.0) { (3.14159265358979 - r1) } else { r1 })
		(if (y < 0.0) { (0.0 - r2) } else { r2 })
	})
}
