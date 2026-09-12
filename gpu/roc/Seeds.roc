# What two gpushow pages upload before their first dispatch, ported from the
# JavaScript that makes it: texture.html's procedural 256x256 texture and
# gltf.html's icosahedron. Hand-written; the gallery seeds a buffer with one
# of these where the page's plan says so.
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
}
