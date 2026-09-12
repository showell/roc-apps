# FireworksSimKernel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device
import DeviceMath

FireworksSimKernel :: [].{

	fw_k_dead : I64
	fw_k_dead = 0

	fw_k_spark : I64
	fw_k_spark = 1

	fw_k_shell : I64
	fw_k_shell = 2

	fw_k_willow : I64
	fw_k_willow = 3

	fw_k_glitter : I64
	fw_k_glitter = 4

	fw_k_smoke : I64
	fw_k_smoke = 5

	fw_k_trail : I64
	fw_k_trail = 6

	fw_floor : F64 -> F64
	fw_floor = |x| ({
		t = I64.to_f64(F64.to_i64_wrap(x))
		(if (t > x) { (t - 1.0) } else { t })
	})

	fw_fract : F64 -> F64
	fw_fract = |x| (x - fw_floor(x))

	fw_rand : F64 -> F64
	fw_rand = |x| fw_fract((DeviceMath.real_sin((x * 12.9898)) * 43758.5453))

	fw_drag : I64 -> F64
	fw_drag = |kind| (if (kind == fw_k_shell) { 0.999 } else { (if (kind == fw_k_willow) { 0.984 } else { (if (kind == fw_k_glitter) { 0.988 } else { (if (kind == fw_k_smoke) { 0.96 } else { (if (kind == fw_k_trail) { 0.938 } else { 0.99 }) }) }) }) })

	fw_grav : I64 -> F64
	fw_grav = |kind| (if (kind == fw_k_smoke) { (0.0 - 0.012) } else { (if (kind == fw_k_willow) { 0.038 } else { (if (kind == fw_k_glitter) { 0.05 } else { (if (kind == fw_k_trail) { 0.026 } else { 0.045 }) }) }) })

	fw_wind_take : I64 -> F64
	fw_wind_take = |kind| (if (kind == fw_k_smoke) { 2.4 } else { (if (kind == fw_k_willow) { 1.2 } else { (if (kind == fw_k_glitter) { 0.8 } else { 0.55 }) }) })

	fw_turb : F64, F64, F64, F64 -> F64
	fw_turb = |fg, px, py, t| ((DeviceMath.real_sin((((px * 0.013) + (t * 0.021)) + (fg * 6.2832))) * 0.024) + (DeviceMath.real_sin((((py * 0.0074) - (t * 0.0163)) + (fg * 3.1416))) * 0.0155))

	fw_new_vx : F64, F64, F64, F64, F64, I64, F64 -> F64
	fw_new_vx = |vx, px, py, fg, t, kind, wind| (((vx + (wind * fw_wind_take(kind))) + fw_turb(fg, px, py, t)) * fw_drag(kind))

	fw_new_vy : F64, F64, F64, F64, F64, I64 -> F64
	fw_new_vy = |vy, px, py, fg, t, kind| (((vy + fw_grav(kind)) + (fw_turb((fg + 0.37), py, px, t) * 0.55)) * fw_drag(kind))

	fw_red : I64 -> F64
	fw_red = |c| (I64.to_f64(I64.div_trunc_by(c, 65536)) / 255.0)

	fw_green : I64 -> F64
	fw_green = |c| (I64.to_f64((I64.div_trunc_by(c, 256) - (I64.div_trunc_by(c, 65536) * 256))) / 255.0)

	fw_blue : I64 -> F64
	fw_blue = |c| (I64.to_f64((c - (I64.div_trunc_by(c, 256) * 256))) / 255.0)

	fw_sat8 : F64 -> I64
	fw_sat8 = |v| F64.to_i64_wrap(DeviceMath.real_max(0.0, DeviceMath.real_min(255.0, (v * 255.0))))

	fw_pack : F64, F64, F64 -> I64
	fw_pack = |r, g, b| (((fw_sat8(r) * 65536) + (fw_sat8(g) * 256)) + fw_sat8(b))

	fw_hot : F64 -> F64
	fw_hot = |fade| ({
		a = ((fade - 0.9) / 0.1)
		(if (a < 0.0) { 0.0 } else { ((a * a) * 0.72) })
	})

	fw_cool : F64 -> F64
	fw_cool = |fade| DeviceMath.real_min(1.0, (fade * 2.6))

	fw_shade_r : I64, F64 -> F64
	fw_shade_r = |col, fade| ({
		h = fw_hot(fade)
		((fw_red(col) * (1.0 - h)) + h)
	})

	fw_shade_g : I64, F64 -> F64
	fw_shade_g = |col, fade| ({
		h = fw_hot(fade)
		(((fw_green(col) * (1.0 - h)) + (h * 0.96)) * (0.34 + (0.66 * fw_cool(fade))))
	})

	fw_shade_b : I64, F64 -> F64
	fw_shade_b = |col, fade| ({
		h = fw_hot(fade)
		(((fw_blue(col) * (1.0 - h)) + (h * 0.86)) * (0.1 + (0.9 * fw_cool(fade))))
	})

	fw_twinkle : F64, F64, I64 -> F64
	fw_twinkle = |fg, t, kind| (if (kind == fw_k_glitter) { ({
		r = fw_rand(((fg * 91.7) + (fw_floor((t * 0.5)) * 0.731)))
		(if (r > 0.62) { (1.0 + (r * 2.4)) } else { (0.1 + (r * 0.25)) })
	}) } else { (if (kind == fw_k_willow) { (0.72 + (0.28 * fw_rand(((fg * 13.1) + (fw_floor((t * 0.34)) * 0.417))))) } else { 1.0 }) })

	fw_decay : F64, F64, F64 -> F64
	fw_decay = |fade, a, b| ({
		e = (1.0 - fade)
		(1.0 / ((1.0 + (a * e)) + ((b * e) * e)))
	})

	fw_bright : F64, F64, F64, I64 -> F64
	fw_bright = |fade, fg, t, kind| (if (kind == fw_k_dead) { 0.0 } else { (if (kind == fw_k_shell) { (0.95 + (0.3 * fw_rand((fg + (fw_floor((t * 0.5)) * 0.11))))) } else { (if (kind == fw_k_smoke) { (0.03 * fade) } else { (if (kind == fw_k_trail) { (0.8 * fw_decay(fade, 7.0, 26.0)) } else { ({
		base = (0.92 * fw_decay(fade, 3.4, 9.0))
		birth = (if (fade > 0.985) { 0.9 } else { 0.0 })
		((base + birth) * fw_twinkle(fg, t, kind))
	}) }) }) }) })

	fw_size : F64, I64 -> F64
	fw_size = |fade, kind| (if (kind == fw_k_dead) { 0.0 } else { (if (kind == fw_k_shell) { 2.6 } else { (if (kind == fw_k_smoke) { (9.0 + (30.0 * (1.0 - fade))) } else { (if (kind == fw_k_trail) { (0.55 + (1.3 * fade)) } else { (if (kind == fw_k_willow) { (1.15 + (1.55 * fade)) } else { (if (kind == fw_k_glitter) { (0.95 + (1.3 * fade)) } else { (1.45 + (2.3 * fade)) }) }) }) }) }) })

	fw_fade : I64, I64 -> F64
	fw_fade = |life, maxl| (if (maxl <= 0) { 0.0 } else { DeviceMath.real_max(0.0, DeviceMath.real_min(1.0, (I64.to_f64(life) / I64.to_f64(maxl)))) })

	fw_next_life : I64, I64 -> I64
	fw_next_life = |life, kind| (if (kind == fw_k_dead) { 0 } else { (life - 1) })

	fw_next_kind : I64, I64 -> I64
	fw_next_kind = |life, kind| (if (kind == fw_k_dead) { fw_k_dead } else { (if (life <= 1) { fw_k_dead } else { kind }) })

	fw_out_pos : F64 -> I64
	fw_out_pos = |v| F64.to_i64_wrap((v * 16.0))

	fw_out_attr : F64, F64, I64 -> I64
	fw_out_attr = |size, bright, kind| ({
		s = F64.to_i64_wrap(DeviceMath.real_max(0.0, DeviceMath.real_min(255.0, (size * 8.0))))
		b = F64.to_i64_wrap(DeviceMath.real_max(0.0, DeviceMath.real_min(255.0, (bright * 32.0))))
		(((s * 65536) + (b * 256)) + kind)
	})

	fw_sim_step : Device.Device, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	fw_sim_step = |dev, state, out, frame, wind, gid| ({
		(dev1, ipx) = Device.load(dev, state, (gid * 8))
		(dev2, ipy) = Device.load(dev1, state, ((gid * 8) + 1))
		(dev3, ivx) = Device.load(dev2, state, ((gid * 8) + 2))
		(dev4, ivy) = Device.load(dev3, state, ((gid * 8) + 3))
		(dev5, life) = Device.load(dev4, state, ((gid * 8) + 4))
		(dev6, maxl) = Device.load(dev5, state, ((gid * 8) + 5))
		(dev7, col) = Device.load(dev6, state, ((gid * 8) + 6))
		(dev8, kind) = Device.load(dev7, state, ((gid * 8) + 7))
		({
			t = I64.to_f64(frame)
			fg = fw_rand((I64.to_f64(gid) * 0.0173))
			wf = (I64.to_f64(wind) / 1000.0)
			px = (I64.to_f64(ipx) / 256.0)
			py = (I64.to_f64(ipy) / 256.0)
			vx = (I64.to_f64(ivx) / 256.0)
			vy = (I64.to_f64(ivy) / 256.0)
			held = (if (kind == fw_k_shell) { 1 } else { (if (kind == fw_k_dead) { 1 } else { 0 }) })
			nvx = (if (held == 1) { vx } else { fw_new_vx(vx, px, py, fg, t, kind, wf) })
			nvy = (if (held == 1) { vy } else { fw_new_vy(vy, px, py, fg, t, kind) })
			npx = (if (held == 1) { px } else { (px + nvx) })
			npy = (if (held == 1) { py } else { (py + nvy) })
			nlife = (if (held == 1) { life } else { fw_next_life(life, kind) })
			nkind = (if (held == 1) { kind } else { fw_next_kind(life, kind) })
			fade = fw_fade(life, maxl)
			bright = fw_bright(fade, fg, t, kind)
			({
				(dev9, _s0) = Device.store(dev8, state, (gid * 8), F64.to_i64_wrap((npx * 256.0)))
				(dev10, _s1) = Device.store(dev9, state, ((gid * 8) + 1), F64.to_i64_wrap((npy * 256.0)))
				(dev11, _s2) = Device.store(dev10, state, ((gid * 8) + 2), F64.to_i64_wrap((nvx * 256.0)))
				(dev12, _s3) = Device.store(dev11, state, ((gid * 8) + 3), F64.to_i64_wrap((nvy * 256.0)))
				(dev13, _s4) = Device.store(dev12, state, ((gid * 8) + 4), nlife)
				(dev14, _s5) = Device.store(dev13, state, ((gid * 8) + 7), nkind)
				(dev15, _o0) = Device.store(dev14, out, (gid * 4), fw_out_pos(npx))
				(dev16, _o1) = Device.store(dev15, out, ((gid * 4) + 1), fw_out_pos(npy))
				(dev17, _o2) = Device.store(dev16, out, ((gid * 4) + 2), fw_pack(fw_shade_r(col, fade), fw_shade_g(col, fade), fw_shade_b(col, fade)))
				Device.store(dev17, out, ((gid * 4) + 3), fw_out_attr(fw_size(fade, kind), bright, kind))
			})
		})
	})
}
