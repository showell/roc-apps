# GlobeKernels -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

GlobeKernels :: [].{

	cordic_sin : F32 -> F32
	cordic_sin = |x| DeviceMath.real_sin(x)

	cordic_cos : F32 -> F32
	cordic_cos = |x| DeviceMath.real_cos(x)

	opening : Device.Device -> (Device.Device, I32)
	opening = |dev| ({
		(dev1, a) = earth_pixel(dev, 0, 0, 0, 0, 0, 0, 0, 0)
		(dev2, b) = bh_pixel(dev1, 0, 0, 0, 0, 0)
		(dev2, I32.plus_wrap(a, b))
	})

	earth_pixel : Device.Device, I32, I32, I32, I32, I32, I32, I32, I32 -> (Device.Device, I32)
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
			px : I32
			px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, w), w))
			py : I32
			py = Device.div(gid, w)
			aspect : F32
			aspect = (int_to_real(i_aspect) / 1000.0)
			zoom : F32
			zoom = (int_to_real(i_zoom) / 1000.0)
			cam_pitch : F32
			cam_pitch = (int_to_real(i_cam_pitch) / 1000.0)
			earth_yaw : F32
			earth_yaw = (int_to_real(i_earth_yaw) / 1000.0)
			earth_pitch : F32
			earth_pitch = (int_to_real(i_earth_pitch) / 1000.0)
			sun_x : F32
			sun_x = (int_to_real(i_sun_x) / 1000.0)
			sun_y : F32
			sun_y = (int_to_real(i_sun_y) / 1000.0)
			sun_z : F32
			sun_z = (int_to_real(i_sun_z) / 1000.0)
			ndx : F32
			ndx = ((((int_to_real(px) / int_to_real(w)) - 0.5) * 2.0) * aspect)
			ndy : F32
			ndy = ((0.5 - (int_to_real(py) / int_to_real(h))) * 2.0)
			rlen : F32
			rlen = DeviceMath.real_sqrt((((ndx * ndx) + (ndy * ndy)) + 1.0))
			rdx : F32
			rdx = (ndx / rlen)
			rdy : F32
			rdy = (ndy / rlen)
			rdz : F32
			rdz = (1.0 / rlen)
			cos_cp : F32
			cos_cp = cordic_cos(cam_pitch)
			sin_cp : F32
			sin_cp = cordic_sin(cam_pitch)
			dx : F32
			dx = rdx
			dy : F32
			dy = ((cos_cp * rdy) - (sin_cp * rdz))
			dz : F32
			dz = ((sin_cp * rdy) + (cos_cp * rdz))
			neg_zoom : F32
			neg_zoom = (0.0 - zoom)
			oy : F32
			oy = (0.0 - (sin_cp * neg_zoom))
			oz : F32
			oz = (cos_cp * neg_zoom)
			b : F32
			b = (2.0 * ((oy * dy) + (oz * dz)))
			c : F32
			c = (((oy * oy) + (oz * oz)) - 1.0)
			disc : F32
			disc = ((b * b) - (4.0 * c))
			t : F32
			t = (if (disc < 0.0) { (0.0 - 1.0) } else { ({
				tv : F32
				tv = (((0.0 - b) - DeviceMath.real_sqrt(disc)) / 2.0)
				(if (tv > 0.001) { tv } else { (0.0 - 1.0) })
			}) })
			(if (t > 0.001) { ({
				hx : F32
				hx = (t * dx)
				hy : F32
				hy = (oy + (t * dy))
				hz : F32
				hz = (oz + (t * dz))
				cos_ey : F32
				cos_ey = cordic_cos(earth_yaw)
				sin_ey : F32
				sin_ey = cordic_sin(earth_yaw)
				cos_ep : F32
				cos_ep = cordic_cos(earth_pitch)
				sin_ep : F32
				sin_ep = cordic_sin(earth_pitch)
				ry : F32
				ry = ((cos_ep * hy) - (sin_ep * hz))
				rz : F32
				rz = ((sin_ep * hy) + (cos_ep * hz))
				gx : F32
				gx = ((cos_ey * hx) + (sin_ey * rz))
				gy : F32
				gy = ry
				gz : F32
				gz = ((0.0 - (sin_ey * hx)) + (cos_ey * rz))
				lat : F32
				lat = asin_approx(gy)
				lon : F32
				lon = atan2_approx(gx, gz)
				pi : F32
				pi = 3.1415927
				u : F32
				u = (1.0 - (((lon / pi) + 1.0) * 0.5))
				v : F32
				v = (0.5 - (lat / pi))
				tx_raw : I32
				tx_raw = real_to_int((u * int_to_real(tw)))
				tx_idx : I32
				tx_idx = I32.minus_wrap(tx_raw, I32.times_wrap(Device.div(tx_raw, tw), tw))
				ty_idx : I32
				ty_idx = clamp_int(real_to_int((v * int_to_real(th))), 0, I32.minus_wrap(th, 1))
				ti : I32
				ti = I32.times_wrap(I32.plus_wrap(I32.times_wrap(ty_idx, tw), tx_idx), 3)
				earth_shade_pixel(dev8, framebuf, tex, gid, ti, hx, hy, hz, sun_x, sun_y, sun_z)
			}) } else { ({
				miss : F32
				miss = (DeviceMath.real_sqrt(DeviceMath.real_max(0.0, ((c + 1.0) - ((b * b) / 4.0)))) - 1.0)
				earth_sky_pixel(dev8, framebuf, gid, miss)
			}) })
		})
	})

	earth_shade_pixel : Device.Device, I32, I32, I32, I32, F32, F32, F32, F32, F32, F32 -> (Device.Device, I32)
	earth_shade_pixel = |dev, framebuf, tex, gid, ti, hx, hy, hz, sx, sy, sz| ({
		(dev1, tr) = Device.load(dev, tex, ti)
		(dev2, tg) = Device.load(dev1, tex, I32.plus_wrap(ti, 1))
		(dev3, tb) = Device.load(dev2, tex, I32.plus_wrap(ti, 2))
		({
			dot : F32
			dot = (((hx * sx) + (hy * sy)) + (hz * sz))
			sun : F32
			sun = DeviceMath.real_max(0.0, dot)
			diff : F32
			diff = (0.12 + (sun * 1.3))
			rim : F32
			rim = DeviceMath.real_sqrt(((hx * hx) + (hy * hy)))
			atmo : F32
			atmo = (((rim * rim) * rim) * 0.6)
			cr : I32
			cr = clamp_int(real_to_int(((int_to_real(tr) * diff) + (atmo * 70.0))), 0, 255)
			cg : I32
			cg = clamp_int(real_to_int(((int_to_real(tg) * diff) + (atmo * 130.0))), 0, 255)
			cb : I32
			cb = clamp_int(real_to_int(((int_to_real(tb) * diff) + (atmo * 255.0))), 0, 255)
			pixel : I32
			pixel = I32.plus_wrap(I32.plus_wrap(I32.plus_wrap(I32.times_wrap(cr, 65536), I32.times_wrap(cg, 256)), cb), I32.times_wrap(255, 16777216))
			Device.store(dev3, framebuf, gid, pixel)
		})
	})

	earth_sky_pixel : Device.Device, I32, I32, F32 -> (Device.Device, I32)
	earth_sky_pixel = |dev, framebuf, gid, miss| ({
		glow : F32
		glow = DeviceMath.real_max(0.0, (1.0 - (miss * 12.0)))
		g2 : F32
		g2 = (glow * glow)
		cr : I32
		cr = clamp_int(real_to_int((g2 * 25.0)), 0, 255)
		cg : I32
		cg = clamp_int(real_to_int((g2 * 50.0)), 0, 255)
		cb : I32
		cb = clamp_int(real_to_int((g2 * 160.0)), 0, 255)
		pixel : I32
		pixel = I32.plus_wrap(I32.plus_wrap(I32.plus_wrap(I32.times_wrap(cr, 65536), I32.times_wrap(cg, 256)), cb), I32.times_wrap(255, 16777216))
		Device.store(dev, framebuf, gid, pixel)
	})

	bh_pixel : Device.Device, I32, I32, I32, I32, I32 -> (Device.Device, I32)
	bh_pixel = |dev, framebuf, params, w, h, gid| ({
		(dev1, i_aspect) = Device.load(dev, params, 0)
		(dev2, i_zoom) = Device.load(dev1, params, 1)
		(dev3, i_cam_pitch) = Device.load(dev2, params, 2)
		(dev4, i_cam_yaw) = Device.load(dev3, params, 3)
		(dev5, i_bh_time) = Device.load(dev4, params, 4)
		({
			px : I32
			px = I32.minus_wrap(gid, I32.times_wrap(Device.div(gid, w), w))
			py : I32
			py = Device.div(gid, w)
			aspect : F32
			aspect = (int_to_real(i_aspect) / 1000.0)
			zoom : F32
			zoom = (int_to_real(i_zoom) / 1000.0)
			cp : F32
			cp = (int_to_real(i_cam_pitch) / 1000.0)
			cy : F32
			cy = (int_to_real(i_cam_yaw) / 1000.0)
			time : F32
			time = (int_to_real(i_bh_time) / 1000.0)
			ndx : F32
			ndx = ((((int_to_real(px) / int_to_real(w)) - 0.5) * 2.0) * aspect)
			ndy : F32
			ndy = ((0.5 - (int_to_real(py) / int_to_real(h))) * 2.0)
			rlen : F32
			rlen = DeviceMath.real_sqrt((((ndx * ndx) + (ndy * ndy)) + 5.76))
			rdx : F32
			rdx = (ndx / rlen)
			rdy : F32
			rdy = (ndy / rlen)
			rdz : F32
			rdz = (2.4 / rlen)
			cos_y : F32
			cos_y = cordic_cos(cy)
			sin_y : F32
			sin_y = cordic_sin(cy)
			cos_p : F32
			cos_p = cordic_cos(cp)
			sin_p : F32
			sin_p = cordic_sin(cp)
			d1x : F32
			d1x = ((cos_y * rdx) + (sin_y * rdz))
			d1z : F32
			d1z = ((0.0 - (sin_y * rdx)) + (cos_y * rdz))
			vx : F32
			vx = d1x
			vy : F32
			vy = ((cos_p * rdy) - (sin_p * d1z))
			vz : F32
			vz = ((sin_p * rdy) + (cos_p * d1z))
			neg_zoom : F32
			neg_zoom = (0.0 - zoom)
			o1x : F32
			o1x = (sin_y * neg_zoom)
			o1z : F32
			o1z = (cos_y * neg_zoom)
			posX : F32
			posX = o1x
			posY : F32
			posY = (0.0 - (sin_p * o1z))
			posZ : F32
			posZ = (cos_p * o1z)
			bh_march(dev5, framebuf, gid, posX, posY, posZ, vx, vy, vz, time, 0, 0.0, 0.0, 0.0, 0.0)
		})
	})

	bh_march : Device.Device, I32, I32, F32, F32, F32, F32, F32, F32, F32, I32, F32, F32, F32, F32 -> (Device.Device, I32)
	bh_march = |dev, framebuf, gid, px, py, pz, vx, vy, vz, time, step, cr, cg, cb, opacity| (if (step >= 250) { bh_write(dev, framebuf, gid, cr, cg, cb, opacity, vx, vy, vz) } else { (if (opacity > 0.99) { bh_write(dev, framebuf, gid, cr, cg, cb, opacity, vx, vy, vz) } else { ({
		r : F32
		r = DeviceMath.real_sqrt((((px * px) + (py * py)) + (pz * pz)))
		(if (r < 0.32) { bh_write(dev, framebuf, gid, cr, cg, cb, 1.0, vx, vy, vz) } else { (if (r > 50.0) { bh_write(dev, framebuf, gid, cr, cg, cb, opacity, vx, vy, vz) } else { ({
			dt : F32
			dt = DeviceMath.real_min(0.12, DeviceMath.real_max(0.003, (r * 0.04)))
			hcx : F32
			hcx = ((py * vz) - (pz * vy))
			hcy : F32
			hcy = ((pz * vx) - (px * vz))
			hcz : F32
			hcz = ((px * vy) - (py * vx))
			h2 : F32
			h2 = (((hcx * hcx) + (hcy * hcy)) + (hcz * hcz))
			r5 : F32
			r5 = ((((r * r) * r) * r) * r)
			gm : F32
			gm = (((0.0 - 0.48) * h2) / r5)
			gx : F32
			gx = ((px / r) * gm)
			gy : F32
			gy = ((py / r) * gm)
			gz : F32
			gz = ((pz / r) * gm)
			nvx : F32
			nvx = (vx + (gx * dt))
			nvy : F32
			nvy = (vy + (gy * dt))
			nvz : F32
			nvz = (vz + (gz * dt))
			vl : F32
			vl = DeviceMath.real_sqrt((((nvx * nvx) + (nvy * nvy)) + (nvz * nvz)))
			nvx2 : F32
			nvx2 = (nvx / vl)
			nvy2 : F32
			nvy2 = (nvy / vl)
			nvz2 : F32
			nvz2 = (nvz / vl)
			npx : F32
			npx = (px + (nvx2 * dt))
			npy : F32
			npy = (py + (nvy2 * dt))
			npz : F32
			npz = (pz + (nvz2 * dt))
			crossed : F32
			crossed = (if ((py * npy) < 0.0) { 1.0 } else { 0.0 })
			(if (crossed > 0.5) { ({
				tc : F32
				tc = (py / (py - npy))
				cx : F32
				cx = (px + ((npx - px) * tc))
				cz : F32
				cz = (pz + ((npz - pz) * tc))
				disk_r : F32
				disk_r = DeviceMath.real_sqrt(((cx * cx) + (cz * cz)))
				inner_fade : F32
				inner_fade = DeviceMath.real_min(1.0, DeviceMath.real_max(0.0, ((disk_r - 0.7) / 0.3)))
				outer_fade : F32
				outer_fade = DeviceMath.real_min(1.0, DeviceMath.real_max(0.0, ((2.2 - disk_r) / 0.4)))
				in_ring : F32
				in_ring = (inner_fade * outer_fade)
				(if (in_ring > 0.01) { ({
					angle : F32
					angle = atan2_approx(cz, cx)
					orbit : F32
					orbit = (angle + ((time * 1.5) / (disk_r * disk_r)))
					n1 : F32
					n1 = cordic_sin(((orbit * 3.0) + (disk_r * 2.0)))
					n2 : F32
					n2 = cordic_sin((((orbit * 7.0) + (disk_r * 0.5)) + 1.3))
					turb : F32
					turb = ((0.65 + (n1 * 0.25)) + (n2 * 0.1))
					density : F32
					density = ((in_ring * 0.5) * turb)
					temp : F32
					temp = DeviceMath.real_max(0.0, (1.0 - ((disk_r - 0.48) / 2.24)))
					grav : F32
					grav = DeviceMath.real_sqrt(DeviceMath.real_max(0.0, (1.0 - (0.32 / r))))
					side : F32
					side = cordic_sin(angle)
					doppler : F32
					doppler = (if (side > 0.0) { (1.3 + (side * 0.5)) } else { (0.4 + ((1.0 + side) * 0.3)) })
					bright : F32
					bright = ((grav * doppler) * density)
					t2 : F32
					t2 = (temp * temp)
					rem : F32
					rem = (1.0 - opacity)
					ncr : F32
					ncr = (cr + ((bright * (1.2 + (t2 * 0.6))) * rem))
					ncg : F32
					ncg = (cg + ((bright * (0.9 + (temp * 0.5))) * rem))
					ncb : F32
					ncb = (cb + ((bright * (0.5 + (t2 * 0.4))) * rem))
					nop : F32
					nop = DeviceMath.real_min((opacity + (density * 0.5)), 1.0)
					bh_march(dev, framebuf, gid, npx, npy, npz, nvx2, nvy2, nvz2, time, I32.plus_wrap(step, 1), ncr, ncg, ncb, nop)
				}) } else { bh_march(dev, framebuf, gid, npx, npy, npz, nvx2, nvy2, nvz2, time, I32.plus_wrap(step, 1), cr, cg, cb, opacity) })
			}) } else { bh_march(dev, framebuf, gid, npx, npy, npz, nvx2, nvy2, nvz2, time, I32.plus_wrap(step, 1), cr, cg, cb, opacity) })
		}) }) })
	}) }) })

	bh_write : Device.Device, I32, I32, F32, F32, F32, F32, F32, F32, F32 -> (Device.Device, I32)
	bh_write = |dev, framebuf, gid, cr, cg, cb, _opacity, _vx, _vy, _vz| ({
		gr : I32
		gr = gamma_byte(cr)
		gg : I32
		gg = gamma_byte(cg)
		gb : I32
		gb = gamma_byte(cb)
		pixel : I32
		pixel = I32.plus_wrap(I32.plus_wrap(I32.plus_wrap(I32.times_wrap(gr, 65536), I32.times_wrap(gg, 256)), gb), I32.times_wrap(255, 16777216))
		Device.store(dev, framebuf, gid, pixel)
	})

	sphere_hit : F32, F32, F32, F32, F32, F32, F32 -> F32
	sphere_hit = |ox, oy, oz, dx, dy, dz, r| ({
		b : F32
		b = (2.0 * (((ox * dx) + (oy * dy)) + (oz * dz)))
		c : F32
		c = ((((ox * ox) + (oy * oy)) + (oz * oz)) - (r * r))
		disc : F32
		disc = ((b * b) - (4.0 * c))
		(if (disc < 0.0) { (0.0 - 1.0) } else { ({
			t : F32
			t = (((0.0 - b) - DeviceMath.real_sqrt(disc)) / 2.0)
			(if (t > 0.001) { t } else { (0.0 - 1.0) })
		}) })
	})

	asin_approx : F32 -> F32
	asin_approx = |x| ({
		clamped : F32
		clamped = DeviceMath.real_min(0.999, DeviceMath.real_max((0.0 - 0.999), x))
		atan2_approx(clamped, DeviceMath.real_sqrt((1.0 - (clamped * clamped))))
	})

	atan2_approx : F32, F32 -> F32
	atan2_approx = |y, x| cordic_atan2(y, x)

	gamma_byte : F32 -> I32
	gamma_byte = |v| ({
		clamped : F32
		clamped = DeviceMath.real_max(0.0, v)
		g : F32
		g = (DeviceMath.real_sqrt(DeviceMath.real_sqrt(clamped)) * DeviceMath.real_sqrt(clamped))
		clamp_int(real_to_int((g * 255.0)), 0, 255)
	})

	clamp_int : I32, I32, I32 -> I32
	clamp_int = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	int_to_real : I32 -> F32
	int_to_real = |n| I32.to_f32(n)

	real_to_int : F32 -> I32
	real_to_int = |r| F32.to_i32_wrap(r)

	cordic_atan2 : F32, F32 -> F32
	cordic_atan2 = |y, x| ({
		ax : F32
		ax = DeviceMath.real_abs(x)
		ay : F32
		ay = DeviceMath.real_abs(y)
		mn : F32
		mn = DeviceMath.real_min(ax, ay)
		mx : F32
		mx = DeviceMath.real_max(ax, ay)
		a : F32
		a = (if (mx > 0.0) { (mn / mx) } else { 0.0 })
		a2 : F32
		a2 = (a * a)
		numer : F32
		numer = (105.0 + (55.0 * a2))
		denom : F32
		denom = (105.0 + (a2 * (90.0 + (9.0 * a2))))
		t : F32
		t = (a * numer)
		base : F32
		base = (t / denom)
		r1 : F32
		r1 = (if (ay > ax) { (1.5707964 - base) } else { base })
		r2 : F32
		r2 = (if (x < 0.0) { (3.1415927 - r1) } else { r1 })
		(if (y < 0.0) { (0.0 - r2) } else { r2 })
	})
}
