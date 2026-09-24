# Noise -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import MathLib
import Perlin
import Tuple
import Wrap64

Noise :: [].{

	value_noise_1d : I64 -> I64
	value_noise_1d = |x| ({
		xi : I64
		xi = (if (x >= 0) { I64.div_trunc_by(x, 1000) } else { (I64.div_trunc_by(x, 1000) - 1) })
		frac : I64
		frac = (x - (xi * 1000))
		t : I64
		t = noise_smooth(frac)
		a : I64
		a = noise_hash_val(xi)
		b : I64
		b = noise_hash_val((xi + 1))
		(a + I64.div_trunc_by(((b - a) * t), 1000))
	})

	value_noise_2d : I64, I64 -> I64
	value_noise_2d = |x, y| ({
		xi : I64
		xi = (if (x >= 0) { I64.div_trunc_by(x, 1000) } else { (I64.div_trunc_by(x, 1000) - 1) })
		yi : I64
		yi = (if (y >= 0) { I64.div_trunc_by(y, 1000) } else { (I64.div_trunc_by(y, 1000) - 1) })
		fx : I64
		fx = noise_smooth((x - (xi * 1000)))
		fy : I64
		fy = noise_smooth((y - (yi * 1000)))
		v00 : I64
		v00 = noise_hash_val2(xi, yi)
		v10 : I64
		v10 = noise_hash_val2((xi + 1), yi)
		v01 : I64
		v01 = noise_hash_val2(xi, (yi + 1))
		v11 : I64
		v11 = noise_hash_val2((xi + 1), (yi + 1))
		a : I64
		a = (v00 + I64.div_trunc_by(((v10 - v00) * fx), 1000))
		b : I64
		b = (v01 + I64.div_trunc_by(((v11 - v01) * fx), 1000))
		(a + I64.div_trunc_by(((b - a) * fy), 1000))
	})

	worley_2d : I64, I64 -> Tuple.Tup2(I64, I64)
	worley_2d = |x, y| ({
		xi : I64
		xi = (if (x >= 0) { I64.div_trunc_by(x, 1000) } else { (I64.div_trunc_by(x, 1000) - 1) })
		yi : I64
		yi = (if (y >= 0) { I64.div_trunc_by(y, 1000) } else { (I64.div_trunc_by(y, 1000) - 1) })
		fx : I64
		fx = (x - (xi * 1000))
		fy : I64
		fy = (y - (yi * 1000))
		worley_scan(xi, yi, fx, fy, (0 - 1), (0 - 1), 999999, 999999)
	})

	worley_scan : I64, I64, I64, I64, I64, I64, I64, I64 -> Tuple.Tup2(I64, I64)
	worley_scan = |xi, yi, fx, fy, dx, dy, f1, f2| (if (dy > 1) { MkTup2(f1, f2) } else { (if (dx > 1) { worley_scan(xi, yi, fx, fy, (0 - 1), (dy + 1), f1, f2) } else { ({
		nx : I64
		nx = (xi + dx)
		ny : I64
		ny = (yi + dy)
		px : I64
		px = (((dx * 1000) - fx) + worley_point_x(nx, ny))
		py : I64
		py = (((dy * 1000) - fy) + worley_point_y(nx, ny))
		dist : I64
		dist = MathLib.math_isqrt(((px * px) + (py * py)))
		new_f1 : I64
		new_f1 = (if (dist < f1) { dist } else { f1 })
		new_f2 : I64
		new_f2 = (if (dist < f1) { f1 } else { (if (dist < f2) { dist } else { f2 }) })
		worley_scan(xi, yi, fx, fy, (dx + 1), dy, new_f1, new_f2)
	}) }) })

	worley_point_x : I64, I64 -> I64
	worley_point_x = |cx, cy| ({
		h : I64
		h = noise_hash_pair(cx, cy)
		I64.div_trunc_by((h * 1000), 65535)
	})

	worley_point_y : I64, I64 -> I64
	worley_point_y = |cx, cy| ({
		h : I64
		h = noise_hash_pair((cx + 7919), (cy + 104729))
		I64.div_trunc_by((h * 1000), 65535)
	})

	fbm_2d : I64, I64, I64, I64, I64 -> I64
	fbm_2d = |x, y, octaves, lacunarity, persistence| fbm_loop(x, y, octaves, lacunarity, persistence, 0, 1000, 1000, 0)

	fbm_loop : I64, I64, I64, I64, I64, I64, I64, I64, I64 -> I64
	fbm_loop = |x, y, octaves, lac, pers, i, freq, amp, sum| (if (i >= octaves) { sum } else { ({
		val : I64
		val = value_noise_2d(I64.div_trunc_by((x * freq), 1000), I64.div_trunc_by((y * freq), 1000))
		centered : I64
		centered = (val - 500)
		fbm_loop(x, y, octaves, lac, pers, (i + 1), I64.div_trunc_by((freq * lac), 1000), I64.div_trunc_by((amp * pers), 1000), (sum + I64.div_trunc_by((centered * amp), 1000)))
	}) })

	warp_2d : I64, I64, I64 -> I64
	warp_2d = |x, y, strength| ({
		wx : I64
		wx = (x + I64.div_trunc_by((value_noise_2d((x + 1730), (y + 5439)) * strength), 1000))
		wy : I64
		wy = (y + I64.div_trunc_by((value_noise_2d((x + 8912), (y + 2741)) * strength), 1000))
		value_noise_2d(wx, wy)
	})

	noise_map_2d : I64, I64, I64 -> List(I64)
	noise_map_2d = |width, height, scale| noise_map_loop(width, height, scale, 0, 0, [])

	noise_map_loop : I64, I64, I64, I64, I64, List(I64) -> List(I64)
	noise_map_loop = |w, h, scale, x, y, acc| (if (y >= h) { acc } else { (if (x >= w) { noise_map_loop(w, h, scale, 0, (y + 1), acc) } else { ({
		val : I64
		val = value_noise_2d((x * scale), (y * scale))
		noise_map_loop(w, h, scale, (x + 1), y, List.append(acc, val))
	}) }) })

	noise_map_min : List(I64) -> I64
	noise_map_min = |vals| noise_fold_min(vals, 0, U64.to_i64_wrap(List.len(vals)), 999999)

	noise_fold_min : List(I64), I64, I64, I64 -> I64
	noise_fold_min = |vals, i, n, best| (if (i >= n) { best } else { ({
		v : I64
		v = (List.get(vals, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		noise_fold_min(vals, (i + 1), n, (if (v < best) { v } else { best }))
	}) })

	noise_map_max : List(I64) -> I64
	noise_map_max = |vals| noise_fold_max(vals, 0, U64.to_i64_wrap(List.len(vals)), 0)

	noise_fold_max : List(I64), I64, I64, I64 -> I64
	noise_fold_max = |vals, i, n, best| (if (i >= n) { best } else { ({
		v : I64
		v = (List.get(vals, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		noise_fold_max(vals, (i + 1), n, (if (v > best) { v } else { best }))
	}) })

	noise_hash_val : I64 -> I64
	noise_hash_val = |x| ({
		h : I64
		h = Perlin.perlin_hash(x)
		masked : I64
		masked = I64.bitwise_and(h, 65535)
		I64.div_trunc_by((masked * 1000), 65535)
	})

	noise_hash_val2 : I64, I64 -> I64
	noise_hash_val2 = |x, y| ({
		h : I64
		h = Perlin.perlin_hash2(x, y)
		masked : I64
		masked = I64.bitwise_and(h, 65535)
		I64.div_trunc_by((masked * 1000), 65535)
	})

	noise_hash_pair : I64, I64 -> I64
	noise_hash_pair = |x, y| ({
		h : I64
		h = I64.bitwise_xor(I64.times_wrap(x, 2654435761), I64.times_wrap(y, 2246822519))
		h2 : I64
		h2 = I64.bitwise_xor(h, I64.shr_zf_wrap(h, I64.to_u8_wrap(13)))
		h3 : I64
		h3 = I64.plus_wrap(Wrap64.w64_mul(h2, 1103515245), 12345)
		positive : I64
		positive = (if (h3 < 0) { I64.minus_wrap(0, h3) } else { h3 })
		I64.bitwise_and(positive, 65535)
	})

	noise_smooth : I64 -> I64
	noise_smooth = |t| I64.div_trunc_by(((t * t) * (3000 - (2 * t))), 1000000)
}
