# Spline -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Quaternion

Spline :: [].{

	catmull_rom : Quaternion.Vec3, Quaternion.Vec3, Quaternion.Vec3, Quaternion.Vec3, F64 -> Quaternion.Vec3
	catmull_rom = |p0, p1, p2, p3, t| ({
		t2 = (t * t)
		t3 = (t2 * t)
		c0 = ((((-t3) / 2.0) + t2) - (t / 2.0))
		c1 = ((((3.0 * t3) / 2.0) - ((5.0 * t2) / 2.0)) + 1.0)
		c2 = (((0.0 - ((3.0 * t3) / 2.0)) + (2.0 * t2)) + (t / 2.0))
		c3 = ((t3 / 2.0) - (t2 / 2.0))
		Quaternion.vec3_new(((((c0 * p0.vx) + (c1 * p1.vx)) + (c2 * p2.vx)) + (c3 * p3.vx)), ((((c0 * p0.vy) + (c1 * p1.vy)) + (c2 * p2.vy)) + (c3 * p3.vy)), ((((c0 * p0.vz) + (c1 * p1.vz)) + (c2 * p2.vz)) + (c3 * p3.vz)))
	})

	spline_eval : List(Quaternion.Vec3), F64 -> Quaternion.Vec3
	spline_eval = |points, t_global| ({
		num_segments = (U64.to_i64_wrap(List.len(points)) - 3)
		(if (num_segments <= 0) { Quaternion.vec3_zero } else { ({
			ns = I64.to_f64(num_segments)
			segment = F64.to_i64_wrap((t_global * ns))
			seg_idx = (if (segment >= num_segments) { (num_segments - 1) } else { segment })
			local_t = ((t_global * ns) - I64.to_f64(seg_idx))
			catmull_rom((List.get(points, I64.to_u64_wrap(seg_idx)) ?? crash("list-at out of range")), (List.get(points, I64.to_u64_wrap((seg_idx + 1))) ?? crash("list-at out of range")), (List.get(points, I64.to_u64_wrap((seg_idx + 2))) ?? crash("list-at out of range")), (List.get(points, I64.to_u64_wrap((seg_idx + 3))) ?? crash("list-at out of range")), local_t)
		}) })
	})
}
