# What gpushow pages upload before their first dispatch, ported from the
# JavaScript that makes it: texture.html's procedural 256x256 texture,
# gltf.html's icosahedron, and the particle pages' initial states from
# their linear congruential generator. Hand-written; the gallery seeds a
# buffer with one of these where the page's plan says so.
Seeds :: [].{
	# texture.html makeTexture: 8x8 tiles of 32px with grout lines, packed
	# 0xRRGGBB, row-major, 65,536 texels.
	texture : {} -> List(I32)
	texture = |{}| texture_from(List.with_capacity(65536), 0)

	texture_from : List(I32), I32 -> List(I32)
	texture_from = |acc, i|
		if i >= 65536 { acc } else { texture_from(List.append(acc, texel(I32.rem_by(i, 256), I32.div_trunc_by(i, 256))), i + 1) }

	texel : I32, I32 -> I32
	texel = |u, v| {
		tu = I32.div_trunc_by(u, 32)
		tv = I32.div_trunc_by(v, 32)
		if I32.rem_by(u, 32) < 2 or I32.rem_by(v, 32) < 2 { 24 * 65536 + 26 * 256 + 34 } else {
			hue = I32.to_f64(I32.rem_by(tu * 5 + tv * 3, 8)) / 8.0
			c = F64.to_i32_wrap(190.0 + 60.0 * F64.sin(I32.to_f64(u + v) * 0.15))
			r = F64.to_i32_wrap(90.0 + 140.0 * F64.abs(F64.sin(hue * 6.283)))
			g = F64.to_i32_wrap(90.0 + 120.0 * F64.abs(F64.sin(hue * 6.283 + 2.1)))
			b = F64.to_i32_wrap(90.0 + 130.0 * F64.abs(F64.sin(hue * 6.283 + 4.2)))
			sparkle = |x| I32.min(255, I32.shr_wrap(x * c, 8))
			sparkle(r) * 65536 + sparkle(g) * 256 + sparkle(b)
		}
	}

	# gltf.html makeMesh: 20 triangles of 9 coordinates in 1/1024 fixed point.
	icosahedron : {} -> List(I32)
	icosahedron = |{}| {
		t = (1.0 + F64.sqrt(5.0)) / 2.0
		inv = 1.1 / F64.sqrt(1.0 + t * t)
		vs = List.map(
			[(-1.0, t, 0.0), (1.0, t, 0.0), (-1.0, -t, 0.0), (1.0, -t, 0.0), (0.0, -1.0, t), (0.0, 1.0, t), (0.0, -1.0, -t), (0.0, 1.0, -t), (t, 0.0, -1.0), (t, 0.0, 1.0), (-t, 0.0, -1.0), (-t, 0.0, 1.0)],
			|(x, y, z)| (x * inv, y * inv, z * inv),
		)
		faces = [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
		fixed = |x| F64.round_to_i32_try(x * 1024.0) ?? 0
		List.join(List.map(faces, |f| List.join(List.map(f, |vi| {
			(x, y, z) = List.get(vs, vi) ?? (0.0, 0.0, 0.0)
			[fixed(x), fixed(y), fixed(z)]
		}))))
	}

	# The pages' `rnd()`: seed = (seed * 1103515245 + 12345) & 0x7fffffff,
	# in JavaScript doubles. The product passes 2^53, so it is what the
	# double multiply rounds it to, and the mask keeps the low 31 bits of
	# that integer; F64 here rounds the same way, and the value stays under
	# 2^63, so the conversion is exact. Answers the next seed and the draw.
	lcg : F64 -> (F64, F64)
	lcg = |seed| {
		next = I64.to_f64(I64.bitwise_and(F64.to_i64_wrap(seed * 1103515245.0 + 12345.0), 2147483647))
		(next, next / 2147483647.0)
	}

	# Four words per particle, `count` particles, from a seed and a rule.
	particles : F64, I32, (F64 -> (F64, List(I32))) -> List(I32)
	particles = |seed, count, one| particles_from(List.with_capacity(I32.to_u64_wrap(count * 4)), seed, count, one)

	particles_from : List(I32), F64, I32, (F64 -> (F64, List(I32))) -> List(I32)
	particles_from = |acc, seed, left, one|
		if left <= 0 { acc } else {
			(seed1, words) = one(seed)
			particles_from(List.fold(words, acc, |a, w| List.append(a, w)), seed1, left - 1, one)
		}

	round : F64 -> I32
	round = |x| F64.round_to_i32_try(x) ?? 0

	floor : F64 -> I32
	floor = |x| F64.floor_to_i32_try(x) ?? 0

	# cpuparticles.html: 14,000 drops of a fountain, 1/16 px, seed 0x2f6b1c3.
	cpu_particles : {} -> List(I32)
	cpu_particles = |{}| particles(49721795.0, 14000, |s0| {
		(s1, r1) = lcg(s0)
		(s2, r2) = lcg(s1)
		(s3, r3) = lcg(s2)
		(s4, r4) = lcg(s3)
		(s4, [round(8192.0 + (r1 - 0.5) * 300.0), round(11600.0 - r2 * 700.0), round((r3 - 0.5) * 620.0), round(0.0 - (230.0 + r4 * 250.0))])
	})

	# nbody.html: 1,024 bodies on a spinning disc, 1/256 px, seed 0x1234567.
	nbody : {} -> List(I32)
	nbody = |{}| particles(19088743.0, 1024, |s0| {
		(s1, r1) = lcg(s0)
		(s2, r2) = lcg(s1)
		a = r1 * 6.28318
		rr = 265.0 * F64.sqrt(r2)
		(s2, [round((512.0 + rr * F64.cos(a)) * 256.0), round((384.0 + rr * F64.sin(a)) * 256.0), round((0.0 - F64.sin(a)) * 0.032 * rr * 256.0), round(F64.cos(a) * 0.032 * rr * 256.0)])
	})

	# particles.html: 20,000 particles anywhere, drifting, seed 0x1234567.
	particles_page : {} -> List(I32)
	particles_page = |{}| particles(19088743.0, 20000, |s0| {
		(s1, r1) = lcg(s0)
		(s2, r2) = lcg(s1)
		(s3, r3) = lcg(s2)
		(s4, r4) = lcg(s3)
		(s4, [floor(r1 * 1024.0), floor(r2 * 768.0), floor((r3 - 0.5) * 220.0), floor((r4 - 0.5) * 220.0)])
	})

	# swarm.html: 8,000 particles anywhere, at rest, seed 0x1234567.
	swarm : {} -> List(I32)
	swarm = |{}| particles(19088743.0, 8000, |s0| {
		(s1, r1) = lcg(s0)
		(s2, r2) = lcg(s1)
		(s2, [floor(r1 * 1024.0), floor(r2 * 768.0), 0, 0])
	})
}
