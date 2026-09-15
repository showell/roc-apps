# Geometry -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Prelude
import Quaternion

Geometry :: [].{
	Vec2 : { v2x : F64, v2y : F64 }
	Seg2 : { seg_a : Geometry.Vec2, seg_b : Geometry.Vec2 }
	SegIntersect : { si_hit : Bool, si_point : Geometry.Vec2, si_t : F64 }
	Tri2 : { tri_a : Geometry.Vec2, tri_b : Geometry.Vec2, tri_c : Geometry.Vec2 }
	Bary : { bary_u : F64, bary_v : F64, bary_w : F64 }
	Ray2 : { ray_origin : Geometry.Vec2, ray_dir : Geometry.Vec2 }
	RayHit : { rh_hit : Bool, rh_t : F64, rh_point : Geometry.Vec2 }
	Ray3 : { r3_origin : Quaternion.Vec3, r3_dir : Quaternion.Vec3 }
	RayHit3 : { rh3_hit : Bool, rh3_t : F64, rh3_point : Quaternion.Vec3 }

	vec2_new : F64, F64 -> Geometry.Vec2
	vec2_new = |x, y| { v2x: x, v2y: y }

	vec2_zero : Geometry.Vec2
	vec2_zero = { v2x: 0.0, v2y: 0.0 }

	vec2_add : Geometry.Vec2, Geometry.Vec2 -> Geometry.Vec2
	vec2_add = |a, b| { v2x: (a.v2x + b.v2x), v2y: (a.v2y + b.v2y) }

	vec2_sub : Geometry.Vec2, Geometry.Vec2 -> Geometry.Vec2
	vec2_sub = |a, b| { v2x: (a.v2x - b.v2x), v2y: (a.v2y - b.v2y) }

	vec2_scale : Geometry.Vec2, F64 -> Geometry.Vec2
	vec2_scale = |v, s| { v2x: (v.v2x * s), v2y: (v.v2y * s) }

	vec2_dot : Geometry.Vec2, Geometry.Vec2 -> F64
	vec2_dot = |a, b| ((a.v2x * b.v2x) + (a.v2y * b.v2y))

	vec2_cross : Geometry.Vec2, Geometry.Vec2 -> F64
	vec2_cross = |a, b| ((a.v2x * b.v2y) - (a.v2y * b.v2x))

	vec2_length_sq : Geometry.Vec2 -> F64
	vec2_length_sq = |v| ((v.v2x * v.v2x) + (v.v2y * v.v2y))

	vec2_length : Geometry.Vec2 -> F64
	vec2_length = |v| geo_sqrt(((v.v2x * v.v2x) + (v.v2y * v.v2y)))

	vec2_normalize : Geometry.Vec2 -> Geometry.Vec2
	vec2_normalize = |v| ({
		len = vec2_length(v)
		(if (F64.to_bits(len) == F64.to_bits(0.0)) { vec2_zero } else { { v2x: (v.v2x / len), v2y: (v.v2y / len) } })
	})

	vec2_negate : Geometry.Vec2 -> Geometry.Vec2
	vec2_negate = |v| { v2x: (-v.v2x), v2y: (-v.v2y) }

	vec2_perp : Geometry.Vec2 -> Geometry.Vec2
	vec2_perp = |v| { v2x: (-v.v2y), v2y: v.v2x }

	vec2_lerp : Geometry.Vec2, Geometry.Vec2, F64 -> Geometry.Vec2
	vec2_lerp = |a, b, t| { v2x: ((a.v2x * (1.0 - t)) + (b.v2x * t)), v2y: ((a.v2y * (1.0 - t)) + (b.v2y * t)) }

	vec2_distance_sq : Geometry.Vec2, Geometry.Vec2 -> F64
	vec2_distance_sq = |a, b| ({
		dx = (b.v2x - a.v2x)
		dy = (b.v2y - a.v2y)
		((dx * dx) + (dy * dy))
	})

	vec2_distance : Geometry.Vec2, Geometry.Vec2 -> F64
	vec2_distance = |a, b| ({
		dx = (b.v2x - a.v2x)
		dy = (b.v2y - a.v2y)
		geo_sqrt(((dx * dx) + (dy * dy)))
	})

	seg2_new : Geometry.Vec2, Geometry.Vec2 -> Geometry.Seg2
	seg2_new = |a, b| { seg_a: a, seg_b: b }

	seg2_length : Geometry.Seg2 -> F64
	seg2_length = |s| vec2_distance(s.seg_a, s.seg_b)

	seg2_midpoint : Geometry.Seg2 -> Geometry.Vec2
	seg2_midpoint = |s| { v2x: ((s.seg_a.v2x + s.seg_b.v2x) / 2.0), v2y: ((s.seg_a.v2y + s.seg_b.v2y) / 2.0) }

	seg2_closest_point : Geometry.Seg2, Geometry.Vec2 -> Geometry.Vec2
	seg2_closest_point = |s, p| ({
		d = vec2_sub(s.seg_b, s.seg_a)
		len_sq = ((d.v2x * d.v2x) + (d.v2y * d.v2y))
		(if (F64.to_bits(len_sq) == F64.to_bits(0.0)) { s.seg_a } else { ({
			t_raw = (((p.v2x - s.seg_a.v2x) * d.v2x) + ((p.v2y - s.seg_a.v2y) * d.v2y))
			t = geo_clamp((t_raw / len_sq), 0.0, 1.0)
			vec2_lerp(s.seg_a, s.seg_b, t)
		}) })
	})

	seg2_distance : Geometry.Seg2, Geometry.Vec2 -> F64
	seg2_distance = |s, p| vec2_distance(seg2_closest_point(s, p), p)

	seg2_intersect : Geometry.Seg2, Geometry.Seg2 -> Geometry.SegIntersect
	seg2_intersect = |s1, s2| ({
		d1 = vec2_sub(s1.seg_b, s1.seg_a)
		d2 = vec2_sub(s2.seg_b, s2.seg_a)
		cross = ((d1.v2x * d2.v2y) - (d1.v2y * d2.v2x))
		(if (geo_abs(cross) < 0.001) { { si_hit: False, si_point: vec2_zero, si_t: 0.0 } } else { ({
			dp = vec2_sub(s2.seg_a, s1.seg_a)
			t = (((dp.v2x * d2.v2y) - (dp.v2y * d2.v2x)) / cross)
			u = (((dp.v2x * d1.v2y) - (dp.v2y * d1.v2x)) / cross)
			(if (t < 0.0) { { si_hit: False, si_point: vec2_zero, si_t: 0.0 } } else { (if (t > 1.0) { { si_hit: False, si_point: vec2_zero, si_t: 0.0 } } else { (if (u < 0.0) { { si_hit: False, si_point: vec2_zero, si_t: 0.0 } } else { (if (u > 1.0) { { si_hit: False, si_point: vec2_zero, si_t: 0.0 } } else { ({
				pt = vec2_lerp(s1.seg_a, s1.seg_b, t)
				{ si_hit: True, si_point: pt, si_t: t }
			}) }) }) }) })
		}) })
	})

	tri2_new : Geometry.Vec2, Geometry.Vec2, Geometry.Vec2 -> Geometry.Tri2
	tri2_new = |a, b, c| { tri_a: a, tri_b: b, tri_c: c }

	tri2_area_2x : Geometry.Tri2 -> F64
	tri2_area_2x = |t| ({
		ab = vec2_sub(t.tri_b, t.tri_a)
		ac = vec2_sub(t.tri_c, t.tri_a)
		((ab.v2x * ac.v2y) - (ab.v2y * ac.v2x))
	})

	tri2_area : Geometry.Tri2 -> F64
	tri2_area = |t| (geo_abs(tri2_area_2x(t)) / 2.0)

	tri2_contains : Geometry.Tri2, Geometry.Vec2 -> Bool
	tri2_contains = |tri, p| ({
		d1 = geo_tri_sign(p, tri.tri_a, tri.tri_b)
		d2 = geo_tri_sign(p, tri.tri_b, tri.tri_c)
		d3 = geo_tri_sign(p, tri.tri_c, tri.tri_a)
		has_neg = (((d1 < 0.0) or (d2 < 0.0)) or (d3 < 0.0))
		has_pos = (((d1 > 0.0) or (d2 > 0.0)) or (d3 > 0.0))
		(if (has_neg and has_pos) { False } else { True })
	})

	geo_tri_sign : Geometry.Vec2, Geometry.Vec2, Geometry.Vec2 -> F64
	geo_tri_sign = |p, a, b| (((p.v2x - b.v2x) * (a.v2y - b.v2y)) - ((a.v2x - b.v2x) * (p.v2y - b.v2y)))

	tri2_barycentric : Geometry.Tri2, Geometry.Vec2 -> Geometry.Bary
	tri2_barycentric = |tri, p| ({
		v0 = vec2_sub(tri.tri_b, tri.tri_a)
		v1 = vec2_sub(tri.tri_c, tri.tri_a)
		v2 = vec2_sub(p, tri.tri_a)
		d00 = ((v0.v2x * v0.v2x) + (v0.v2y * v0.v2y))
		d01 = ((v0.v2x * v1.v2x) + (v0.v2y * v1.v2y))
		d11 = ((v1.v2x * v1.v2x) + (v1.v2y * v1.v2y))
		d20 = ((v2.v2x * v0.v2x) + (v2.v2y * v0.v2y))
		d21 = ((v2.v2x * v1.v2x) + (v2.v2y * v1.v2y))
		denom = ((d00 * d11) - (d01 * d01))
		(if (F64.to_bits(denom) == F64.to_bits(0.0)) { { bary_u: 0.0, bary_v: 0.0, bary_w: 1.0 } } else { ({
			bv = (((d11 * d20) - (d01 * d21)) / denom)
			bw = (((d00 * d21) - (d01 * d20)) / denom)
			bu = ((1.0 - bv) - bw)
			{ bary_u: bu, bary_v: bv, bary_w: bw }
		}) })
	})

	tri2_circumcenter : Geometry.Tri2 -> Geometry.Vec2
	tri2_circumcenter = |tri| ({
		ax = tri.tri_a.v2x
		ay = tri.tri_a.v2y
		bx = tri.tri_b.v2x
		by = tri.tri_b.v2y
		cx = tri.tri_c.v2x
		cy = tri.tri_c.v2y
		d = (2.0 * (((ax * (by - cy)) + (bx * (cy - ay))) + (cx * (ay - by))))
		(if (F64.to_bits(d) == F64.to_bits(0.0)) { tri.tri_a } else { ({
			a2 = ((ax * ax) + (ay * ay))
			b2 = ((bx * bx) + (by * by))
			c2 = ((cx * cx) + (cy * cy))
			ux = ((((a2 * (by - cy)) + (b2 * (cy - ay))) + (c2 * (ay - by))) / d)
			uy = ((((a2 * (cx - bx)) + (b2 * (ax - cx))) + (c2 * (bx - ax))) / d)
			vec2_new(ux, uy)
		}) })
	})

	poly_area_2x : List(Geometry.Vec2) -> F64
	poly_area_2x = |pts| geo_poly_area_loop(pts, 0, U64.to_i64_wrap(List.len(pts)), 0.0)

	geo_poly_area_loop : List(Geometry.Vec2), I64, I64, F64 -> F64
	geo_poly_area_loop = |pts, i, n, acc| (if (i >= n) { acc } else { ({
		j = (if ((i + 1) >= n) { 0 } else { (i + 1) })
		pi = (List.get(pts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		pj = (List.get(pts, I64.to_u64_wrap(j)) ?? crash("list-at out of range"))
		geo_poly_area_loop(pts, (i + 1), n, ((acc + (pi.v2x * pj.v2y)) - (pj.v2x * pi.v2y)))
	}) })

	poly_area : List(Geometry.Vec2) -> F64
	poly_area = |pts| (geo_abs(poly_area_2x(pts)) / 2.0)

	poly_perimeter : List(Geometry.Vec2) -> F64
	poly_perimeter = |pts| geo_poly_perim_loop(pts, 0, U64.to_i64_wrap(List.len(pts)), 0.0)

	geo_poly_perim_loop : List(Geometry.Vec2), I64, I64, F64 -> F64
	geo_poly_perim_loop = |pts, i, n, acc| (if (i >= n) { acc } else { ({
		j = (if ((i + 1) >= n) { 0 } else { (i + 1) })
		geo_poly_perim_loop(pts, (i + 1), n, (acc + vec2_distance((List.get(pts, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), (List.get(pts, I64.to_u64_wrap(j)) ?? crash("list-at out of range")))))
	}) })

	poly_contains : List(Geometry.Vec2), Geometry.Vec2 -> Bool
	poly_contains = |pts, p| geo_pip_loop(pts, p, 0, U64.to_i64_wrap(List.len(pts)), False)

	geo_pip_loop : List(Geometry.Vec2), Geometry.Vec2, I64, I64, Bool -> Bool
	geo_pip_loop = |pts, p, i, n, inside| (if (i >= n) { inside } else { ({
		j = (if ((i + 1) >= n) { 0 } else { (i + 1) })
		pi = (List.get(pts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		pj = (List.get(pts, I64.to_u64_wrap(j)) ?? crash("list-at out of range"))
		crosses = (if (pi.v2y <= p.v2y) { ((pj.v2y > p.v2y) and (geo_pip_side(pi, pj, p) > 0.0)) } else { ((pj.v2y <= p.v2y) and (geo_pip_side(pi, pj, p) < 0.0)) })
		next = (if crosses { (if inside { False } else { True }) } else { inside })
		geo_pip_loop(pts, p, (i + 1), n, next)
	}) })

	geo_pip_side : Geometry.Vec2, Geometry.Vec2, Geometry.Vec2 -> F64
	geo_pip_side = |a, b, p| (((b.v2x - a.v2x) * (p.v2y - a.v2y)) - ((p.v2x - a.v2x) * (b.v2y - a.v2y)))

	poly_centroid : List(Geometry.Vec2) -> Geometry.Vec2
	poly_centroid = |pts| ({
		n = U64.to_i64_wrap(List.len(pts))
		(if (n == 0) { vec2_zero } else { ({
			sums = geo_centroid_loop(pts, 0, n, 0.0, 0.0)
			vec2_new((geo_fst(sums) / I64.to_f64(n)), (geo_snd(sums) / I64.to_f64(n)))
		}) })
	})

	geo_centroid_loop : List(Geometry.Vec2), I64, I64, F64, F64 -> Geometry.Vec2
	geo_centroid_loop = |pts, i, n, sx, sy| (if (i >= n) { vec2_new(sx, sy) } else { ({
		p = (List.get(pts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		geo_centroid_loop(pts, (i + 1), n, (sx + p.v2x), (sy + p.v2y))
	}) })

	geo_fst : Geometry.Vec2 -> F64
	geo_fst = |v| v.v2x

	geo_snd : Geometry.Vec2 -> F64
	geo_snd = |v| v.v2y

	convex_hull : List(Geometry.Vec2) -> List(Geometry.Vec2)
	convex_hull = |pts| ({
		sorted = geo_sort_pts(pts)
		n = U64.to_i64_wrap(List.len(sorted))
		(if (n <= 2) { sorted } else { ({
			lower = geo_hull_half(sorted, 0, n, [])
			upper = geo_hull_half_rev(sorted, (n - 1), [])
			geo_hull_merge(lower, upper)
		}) })
	})

	geo_hull_half : List(Geometry.Vec2), I64, I64, List(Geometry.Vec2) -> List(Geometry.Vec2)
	geo_hull_half = |pts, i, n, hull| (if (i >= n) { hull } else { ({
		p = (List.get(pts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		trimmed = geo_hull_trim(hull, p)
		geo_hull_half(pts, (i + 1), n, List.append(trimmed, p))
	}) })

	geo_hull_half_rev : List(Geometry.Vec2), I64, List(Geometry.Vec2) -> List(Geometry.Vec2)
	geo_hull_half_rev = |pts, i, hull| (if (i < 0) { hull } else { ({
		p = (List.get(pts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		trimmed = geo_hull_trim(hull, p)
		geo_hull_half_rev(pts, (i - 1), List.append(trimmed, p))
	}) })

	geo_hull_trim : List(Geometry.Vec2), Geometry.Vec2 -> List(Geometry.Vec2)
	geo_hull_trim = |hull, p| ({
		n = U64.to_i64_wrap(List.len(hull))
		(if (n < 2) { hull } else { ({
			a = (List.get(hull, I64.to_u64_wrap((n - 2))) ?? crash("list-at out of range"))
			b = (List.get(hull, I64.to_u64_wrap((n - 1))) ?? crash("list-at out of range"))
			cross = (((b.v2x - a.v2x) * (p.v2y - a.v2y)) - ((b.v2y - a.v2y) * (p.v2x - a.v2x)))
			(if (cross <= 0.0) { geo_hull_trim(geo_list_drop_last(hull), p) } else { hull })
		}) })
	})

	geo_hull_merge : List(Geometry.Vec2), List(Geometry.Vec2) -> List(Geometry.Vec2)
	geo_hull_merge = |lower, upper| ({
		l = geo_list_drop_last(lower)
		u = geo_list_drop_last(upper)
		List.concat(l, u)
	})

	ray2_new : Geometry.Vec2, Geometry.Vec2 -> Geometry.Ray2
	ray2_new = |origin, dir| { ray_origin: origin, ray_dir: vec2_normalize(dir) }

	ray2_seg : Geometry.Ray2, Geometry.Seg2 -> Geometry.RayHit
	ray2_seg = |ray, seg| ({
		d = ray.ray_dir
		e = vec2_sub(seg.seg_b, seg.seg_a)
		cross = ((d.v2x * e.v2y) - (d.v2y * e.v2x))
		(if (geo_abs(cross) < 0.001) { { rh_hit: False, rh_t: 0.0, rh_point: vec2_zero } } else { ({
			f = vec2_sub(seg.seg_a, ray.ray_origin)
			t = (((f.v2x * e.v2y) - (f.v2y * e.v2x)) / cross)
			u = (((f.v2x * d.v2y) - (f.v2y * d.v2x)) / cross)
			(if (t < 0.0) { { rh_hit: False, rh_t: 0.0, rh_point: vec2_zero } } else { (if (u < 0.0) { { rh_hit: False, rh_t: 0.0, rh_point: vec2_zero } } else { (if (u > 1.0) { { rh_hit: False, rh_t: 0.0, rh_point: vec2_zero } } else { ({
				pt = vec2_add(ray.ray_origin, vec2_scale(d, t))
				{ rh_hit: True, rh_t: t, rh_point: pt }
			}) }) }) })
		}) })
	})

	ray2_circle : Geometry.Ray2, Geometry.Vec2, F64 -> Geometry.RayHit
	ray2_circle = |ray, center, radius| ({
		oc = vec2_sub(ray.ray_origin, center)
		a = vec2_dot(ray.ray_dir, ray.ray_dir)
		b = (2.0 * vec2_dot(oc, ray.ray_dir))
		c = (vec2_dot(oc, oc) - (radius * radius))
		disc = ((b * b) - ((4.0 * a) * c))
		(if (disc < 0.0) { { rh_hit: False, rh_t: 0.0, rh_point: vec2_zero } } else { ({
			sqrt_d = geo_sqrt(disc)
			t = (((-b) - sqrt_d) / (2.0 * a))
			(if (t < 0.0) { ({
				t2 = (((-b) + sqrt_d) / (2.0 * a))
				(if (t2 < 0.0) { { rh_hit: False, rh_t: 0.0, rh_point: vec2_zero } } else { ({
					pt = vec2_add(ray.ray_origin, vec2_scale(ray.ray_dir, t2))
					{ rh_hit: True, rh_t: t2, rh_point: pt }
				}) })
			}) } else { ({
				pt = vec2_add(ray.ray_origin, vec2_scale(ray.ray_dir, t))
				{ rh_hit: True, rh_t: t, rh_point: pt }
			}) })
		}) })
	})

	ray3_new : Quaternion.Vec3, Quaternion.Vec3 -> Geometry.Ray3
	ray3_new = |origin, dir| { r3_origin: origin, r3_dir: dir }

	ray3_plane : Geometry.Ray3, Quaternion.Vec3, Quaternion.Vec3 -> Geometry.RayHit3
	ray3_plane = |ray, plane_point, plane_normal| ({
		denom = Quaternion.vec3_dot(ray.r3_dir, plane_normal)
		(if (geo_abs(denom) < 0.001) { { rh3_hit: False, rh3_t: 0.0, rh3_point: Quaternion.vec3_zero } } else { ({
			diff = Quaternion.vec3_subtract(plane_point, ray.r3_origin)
			t = (Quaternion.vec3_dot(diff, plane_normal) / denom)
			(if (t < 0.0) { { rh3_hit: False, rh3_t: 0.0, rh3_point: Quaternion.vec3_zero } } else { ({
				pt = Quaternion.vec3_add(ray.r3_origin, Quaternion.vec3_scale(ray.r3_dir, t))
				{ rh3_hit: True, rh3_t: t, rh3_point: pt }
			}) })
		}) })
	})

	ray3_sphere_hit : Geometry.Ray3, F64 -> Geometry.RayHit3
	ray3_sphere_hit = |ray, t| ({
		pt = Quaternion.vec3_add(ray.r3_origin, Quaternion.vec3_scale(ray.r3_dir, t))
		{ rh3_hit: True, rh3_t: t, rh3_point: pt }
	})

	ray3_sphere_miss : Geometry.RayHit3
	ray3_sphere_miss = { rh3_hit: False, rh3_t: 0.0, rh3_point: Quaternion.vec3_zero }

	ray3_sphere : Geometry.Ray3, Quaternion.Vec3, F64 -> Geometry.RayHit3
	ray3_sphere = |ray, center, radius| ({
		oc = Quaternion.vec3_subtract(ray.r3_origin, center)
		a = Quaternion.vec3_dot(ray.r3_dir, ray.r3_dir)
		b = (2.0 * Quaternion.vec3_dot(oc, ray.r3_dir))
		c = (Quaternion.vec3_dot(oc, oc) - (radius * radius))
		disc = ((b * b) - ((4.0 * a) * c))
		(if (disc < 0.0) { ray3_sphere_miss } else { ray3_sphere_solve(ray, a, b, disc) })
	})

	ray3_sphere_solve : Geometry.Ray3, F64, F64, F64 -> Geometry.RayHit3
	ray3_sphere_solve = |ray, a, b, disc| ({
		sqrt_d = geo_sqrt(disc)
		neg_b = (0.0 - b)
		denom = (2.0 * a)
		t = ((neg_b - sqrt_d) / denom)
		(if (t < 0.0) { ({
			t2 = ((neg_b + sqrt_d) / denom)
			(if (t2 < 0.0) { ray3_sphere_miss } else { ray3_sphere_hit(ray, t2) })
		}) } else { ray3_sphere_hit(ray, t) })
	})

	geo_sort_pts : List(Geometry.Vec2) -> List(Geometry.Vec2)
	geo_sort_pts = |pts| ({
		n = U64.to_i64_wrap(List.len(pts))
		(if (n <= 1) { pts } else { ({
			mid = I64.div_trunc_by(n, 2)
			left = geo_sort_pts(geo_list_take(pts, mid))
			right = geo_sort_pts(geo_list_drop(pts, mid))
			geo_merge_pts(left, right)
		}) })
	})

	# geo_merge_pts builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	geo_merge_pts : List(Geometry.Vec2), List(Geometry.Vec2) -> List(Geometry.Vec2)
	geo_merge_pts = |left, right| geo_merge_pts_acc(left, right, [])

	geo_merge_pts_acc : List(Geometry.Vec2), List(Geometry.Vec2), List(Geometry.Vec2) -> List(Geometry.Vec2)
	geo_merge_pts_acc = |left, right, acc| (if (U64.to_i64_wrap(List.len(left)) == 0) { List.concat(acc, right) } else { (if (U64.to_i64_wrap(List.len(right)) == 0) { List.concat(acc, left) } else { ({
		l = (List.get(left, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
		r = (List.get(right, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
		(if (l.v2x < r.v2x) { geo_merge_pts_acc(geo_list_drop(left, 1), right, List.append(acc, l)) } else { (if (l.v2x > r.v2x) { geo_merge_pts_acc(left, geo_list_drop(right, 1), List.append(acc, r)) } else { (if (l.v2y <= r.v2y) { geo_merge_pts_acc(geo_list_drop(left, 1), right, List.append(acc, l)) } else { geo_merge_pts_acc(left, geo_list_drop(right, 1), List.append(acc, r)) }) }) })
	}) }) })

	geo_list_take : List(Geometry.Vec2), I64 -> List(Geometry.Vec2)
	geo_list_take = |xs, n| geo_list_take_loop(xs, 0, n, [])

	geo_list_take_loop : List(Geometry.Vec2), I64, I64, List(Geometry.Vec2) -> List(Geometry.Vec2)
	geo_list_take_loop = |xs, i, n, acc| (if (i >= n) { acc } else { (if (i >= U64.to_i64_wrap(List.len(xs))) { acc } else { geo_list_take_loop(xs, (i + 1), n, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) }) })

	geo_list_drop : List(Geometry.Vec2), I64 -> List(Geometry.Vec2)
	geo_list_drop = |xs, n| geo_list_drop_loop(xs, n, U64.to_i64_wrap(List.len(xs)), [])

	geo_list_drop_loop : List(Geometry.Vec2), I64, I64, List(Geometry.Vec2) -> List(Geometry.Vec2)
	geo_list_drop_loop = |xs, i, len, acc| (if (i >= len) { acc } else { geo_list_drop_loop(xs, (i + 1), len, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	geo_list_drop_last : List(Geometry.Vec2) -> List(Geometry.Vec2)
	geo_list_drop_last = |xs| geo_list_take(xs, (U64.to_i64_wrap(List.len(xs)) - 1))

	geo_abs : F64 -> F64
	geo_abs = |n| (if (n < 0.0) { (-n) } else { n })

	geo_sqrt : F64 -> F64
	geo_sqrt = |n| if n <= 0.0 { 0.0 } else { F64.sqrt(n) }

	geo_sqrt_loop : F64, F64 -> F64
	geo_sqrt_loop = |n, guess| ({
		next = ((guess + (n / guess)) / 2.0)
		(if Prelude.approx_eq(next, guess) { next } else { geo_sqrt_loop(n, next) })
	})

	geo_clamp : F64, F64, F64 -> F64
	geo_clamp = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	geo_min : F64, F64 -> F64
	geo_min = |a, b| (if (a < b) { a } else { b })

	geo_max : F64, F64 -> F64
	geo_max = |a, b| (if (a > b) { a } else { b })

	format_vec2 : Geometry.Vec2 -> Str
	format_vec2 = |v| Str.concat(Str.concat(Str.concat(Str.concat("(", Prelude.real_to_str(v.v2x)), ","), Prelude.real_to_str(v.v2y)), ")")

	format_seg2 : Geometry.Seg2 -> Str
	format_seg2 = |s| Str.concat(Str.concat(format_vec2(s.seg_a), "->"), format_vec2(s.seg_b))

	format_tri2 : Geometry.Tri2 -> Str
	format_tri2 = |t| Str.concat(Str.concat(Str.concat(Str.concat(format_vec2(t.tri_a), " "), format_vec2(t.tri_b)), " "), format_vec2(t.tri_c))

	format_ray_hit : Geometry.RayHit -> Str
	format_ray_hit = |h| (if h.rh_hit { Str.concat(Str.concat(Str.concat("HIT t=", Prelude.real_to_str(h.rh_t)), " at "), format_vec2(h.rh_point)) } else { "MISS" })

	format_bary : Geometry.Bary -> Str
	format_bary = |b| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("(", Prelude.real_to_str(b.bary_u)), ","), Prelude.real_to_str(b.bary_v)), ","), Prelude.real_to_str(b.bary_w)), ")")
}
