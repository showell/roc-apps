# Geometry -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Prelude
import Quaternion

Geometry :: [].{
	Vec2 := { v2x : F64, v2y : F64 }.{
		is_eq : Geometry.Vec2, Geometry.Vec2 -> Bool
		is_eq = |a, b| a.v2x == b.v2x and a.v2y == b.v2y
	}
	Seg2 := { seg_a : Geometry.Vec2, seg_b : Geometry.Vec2 }.{
		is_eq : Geometry.Seg2, Geometry.Seg2 -> Bool
		is_eq = |a, b| a.seg_a == b.seg_a and a.seg_b == b.seg_b
	}
	SegIntersect := { si_hit : Bool, si_point : Geometry.Vec2, si_t : F64 }.{
		is_eq : Geometry.SegIntersect, Geometry.SegIntersect -> Bool
		is_eq = |a, b| a.si_hit == b.si_hit and a.si_point == b.si_point and a.si_t == b.si_t
	}
	Tri2 := { tri_a : Geometry.Vec2, tri_b : Geometry.Vec2, tri_c : Geometry.Vec2 }.{
		is_eq : Geometry.Tri2, Geometry.Tri2 -> Bool
		is_eq = |a, b| a.tri_a == b.tri_a and a.tri_b == b.tri_b and a.tri_c == b.tri_c
	}
	Bary := { bary_u : F64, bary_v : F64, bary_w : F64 }.{
		is_eq : Geometry.Bary, Geometry.Bary -> Bool
		is_eq = |a, b| a.bary_u == b.bary_u and a.bary_v == b.bary_v and a.bary_w == b.bary_w
	}
	Ray2 := { ray_origin : Geometry.Vec2, ray_dir : Geometry.Vec2 }.{
		is_eq : Geometry.Ray2, Geometry.Ray2 -> Bool
		is_eq = |a, b| a.ray_origin == b.ray_origin and a.ray_dir == b.ray_dir
	}
	RayHit := { rh_hit : Bool, rh_t : F64, rh_point : Geometry.Vec2 }.{
		is_eq : Geometry.RayHit, Geometry.RayHit -> Bool
		is_eq = |a, b| a.rh_hit == b.rh_hit and a.rh_t == b.rh_t and a.rh_point == b.rh_point
	}
	Ray3 := { r3_origin : Quaternion.Vec3, r3_dir : Quaternion.Vec3 }.{
		is_eq : Geometry.Ray3, Geometry.Ray3 -> Bool
		is_eq = |a, b| a.r3_origin == b.r3_origin and a.r3_dir == b.r3_dir
	}
	RayHit3 := { rh3_hit : Bool, rh3_t : F64, rh3_point : Quaternion.Vec3 }.{
		is_eq : Geometry.RayHit3, Geometry.RayHit3 -> Bool
		is_eq = |a, b| a.rh3_hit == b.rh3_hit and a.rh3_t == b.rh3_t and a.rh3_point == b.rh3_point
	}

	ray3_new : Quaternion.Vec3, Quaternion.Vec3 -> Geometry.Ray3
	ray3_new = |origin, dir| Geometry.Ray3.{ r3_origin: origin, r3_dir: dir }

	ray3_plane : Geometry.Ray3, Quaternion.Vec3, Quaternion.Vec3 -> Geometry.RayHit3
	ray3_plane = |ray, plane_point, plane_normal| ({
		denom : F64
		denom = Quaternion.vec3_dot(ray.r3_dir, plane_normal)
		(if (geo_abs(denom) < 0.001) { Geometry.RayHit3.{ rh3_hit: False, rh3_t: 0.0, rh3_point: Quaternion.vec3_zero } } else { ({
			diff = Quaternion.vec3_subtract(plane_point, ray.r3_origin)
			t : F64
			t = (Quaternion.vec3_dot(diff, plane_normal) / denom)
			(if (t < 0.0) { Geometry.RayHit3.{ rh3_hit: False, rh3_t: 0.0, rh3_point: Quaternion.vec3_zero } } else { ({
				pt = Quaternion.vec3_add(ray.r3_origin, Quaternion.vec3_scale(ray.r3_dir, t))
				Geometry.RayHit3.{ rh3_hit: True, rh3_t: t, rh3_point: pt }
			}) })
		}) })
	})

	ray3_sphere_hit : Geometry.Ray3, F64 -> Geometry.RayHit3
	ray3_sphere_hit = |ray, t| ({
		pt = Quaternion.vec3_add(ray.r3_origin, Quaternion.vec3_scale(ray.r3_dir, t))
		Geometry.RayHit3.{ rh3_hit: True, rh3_t: t, rh3_point: pt }
	})

	ray3_sphere_miss : Geometry.RayHit3
	ray3_sphere_miss = Geometry.RayHit3.{ rh3_hit: False, rh3_t: 0.0, rh3_point: Quaternion.vec3_zero }

	ray3_sphere : Geometry.Ray3, Quaternion.Vec3, F64 -> Geometry.RayHit3
	ray3_sphere = |ray, center, radius| ({
		oc = Quaternion.vec3_subtract(ray.r3_origin, center)
		a : F64
		a = Quaternion.vec3_dot(ray.r3_dir, ray.r3_dir)
		b : F64
		b = (2.0 * Quaternion.vec3_dot(oc, ray.r3_dir))
		c : F64
		c = (Quaternion.vec3_dot(oc, oc) - (radius * radius))
		disc : F64
		disc = ((b * b) - ((4.0 * a) * c))
		(if (disc < 0.0) { ray3_sphere_miss } else { ray3_sphere_solve(ray, a, b, disc) })
	})

	ray3_sphere_solve : Geometry.Ray3, F64, F64, F64 -> Geometry.RayHit3
	ray3_sphere_solve = |ray, a, b, disc| ({
		sqrt_d : F64
		sqrt_d = geo_sqrt(disc)
		neg_b : F64
		neg_b = (0.0 - b)
		denom : F64
		denom = (2.0 * a)
		t : F64
		t = ((neg_b - sqrt_d) / denom)
		(if (t < 0.0) { ({
			t2 : F64
			t2 = ((neg_b + sqrt_d) / denom)
			(if (t2 < 0.0) { ray3_sphere_miss } else { ray3_sphere_hit(ray, t2) })
		}) } else { ray3_sphere_hit(ray, t) })
	})

	geo_abs : F64 -> F64
	geo_abs = |n| (if (n < 0.0) { (-n) } else { n })

	geo_sqrt : F64 -> F64
	geo_sqrt = |n| if n <= 0.0 { 0.0 } else { F64.sqrt(n) }

	geo_sqrt_loop : F64, F64 -> F64
	geo_sqrt_loop = |n, guess| ({
		next : F64
		next = ((guess + (n / guess)) / 2.0)
		(if Prelude.approx_eq(next, guess) { next } else { geo_sqrt_loop(n, next) })
	})
}
