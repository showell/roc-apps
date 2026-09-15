# Quaternion -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Prelude

Quaternion :: [].{
	Quat : { w : F64, x : F64, y : F64, z : F64 }
	Vec3 : { vx : F64, vy : F64, vz : F64 }

	quat_identity : Quaternion.Quat
	quat_identity = { w: 1.0, x: 0.0, y: 0.0, z: 0.0 }

	quat_new : F64, F64, F64, F64 -> Quaternion.Quat
	quat_new = |w, x, y, z| { w: w, x: x, y: y, z: z }

	vec3_new : F64, F64, F64 -> Quaternion.Vec3
	vec3_new = |x, y, z| { vx: x, vy: y, vz: z }

	vec3_zero : Quaternion.Vec3
	vec3_zero = { vx: 0.0, vy: 0.0, vz: 0.0 }

	quat_multiply : Quaternion.Quat, Quaternion.Quat -> Quaternion.Quat
	quat_multiply = |a, b| { w: ((((a.w * b.w) - (a.x * b.x)) - (a.y * b.y)) - (a.z * b.z)), x: ((((a.w * b.x) + (a.x * b.w)) + (a.y * b.z)) - (a.z * b.y)), y: ((((a.w * b.y) - (a.x * b.z)) + (a.y * b.w)) + (a.z * b.x)), z: ((((a.w * b.z) + (a.x * b.y)) - (a.y * b.x)) + (a.z * b.w)) }

	quat_conjugate : Quaternion.Quat -> Quaternion.Quat
	quat_conjugate = |q| { w: q.w, x: (-q.x), y: (-q.y), z: (-q.z) }

	quat_add : Quaternion.Quat, Quaternion.Quat -> Quaternion.Quat
	quat_add = |a, b| { w: (a.w + b.w), x: (a.x + b.x), y: (a.y + b.y), z: (a.z + b.z) }

	quat_scale_by : Quaternion.Quat, F64 -> Quaternion.Quat
	quat_scale_by = |q, s| { w: (q.w * s), x: (q.x * s), y: (q.y * s), z: (q.z * s) }

	quat_norm_squared : Quaternion.Quat -> F64
	quat_norm_squared = |q| ((((q.w * q.w) + (q.x * q.x)) + (q.y * q.y)) + (q.z * q.z))

	quat_dot : Quaternion.Quat, Quaternion.Quat -> F64
	quat_dot = |a, b| ((((a.w * b.w) + (a.x * b.x)) + (a.y * b.y)) + (a.z * b.z))

	quat_from_axis_angle : Quaternion.Vec3, F64 -> Quaternion.Quat
	quat_from_axis_angle = |axis, angle| ({
		half = (angle / 2.0)
		sin_h = quat_sin_approx(half)
		cos_h = quat_cos_approx(half)
		{ w: cos_h, x: (axis.vx * sin_h), y: (axis.vy * sin_h), z: (axis.vz * sin_h) }
	})

	quat_rotate_vec : Quaternion.Quat, Quaternion.Vec3 -> Quaternion.Vec3
	quat_rotate_vec = |q, v| ({
		p = { w: 0.0, x: v.vx, y: v.vy, z: v.vz }
		qp = quat_multiply(q, p)
		result = quat_multiply(qp, quat_conjugate(q))
		{ vx: result.x, vy: result.y, vz: result.z }
	})

	quat_sin_approx : F64 -> F64
	quat_sin_approx = |rad| ({
		x = rad
		x3 = ((x * x) * x)
		(x - (x3 / 6.0))
	})

	quat_cos_approx : F64 -> F64
	quat_cos_approx = |rad| ({
		x2 = (rad * rad)
		x4 = (x2 * x2)
		((1.0 - (x2 / 2.0)) + (x4 / 24.0))
	})

	quat_real_sqrt : F64 -> F64
	quat_real_sqrt = |n| if n <= 0.0 { 0.0 } else { F64.sqrt(n) }

	quat_real_sqrt_loop : F64, F64 -> F64
	quat_real_sqrt_loop = |n, guess| ({
		next = ((guess + (n / guess)) / 2.0)
		(if Prelude.approx_eq(next, guess) { next } else { quat_real_sqrt_loop(n, next) })
	})

	quat_normalize : Quaternion.Quat -> Quaternion.Quat
	quat_normalize = |q| ({
		len_sq = ((((q.w * q.w) + (q.x * q.x)) + (q.y * q.y)) + (q.z * q.z))
		len = quat_real_sqrt(len_sq)
		(if Prelude.approx_eq(len, 0.0) { quat_identity } else { { w: (q.w / len), x: (q.x / len), y: (q.y / len), z: (q.z / len) } })
	})

	quat_slerp : Quaternion.Quat, Quaternion.Quat, F64 -> Quaternion.Quat
	quat_slerp = |a, b, t| ({
		dot = quat_dot(a, b)
		b2 = (if (dot < 0.0) { { w: (0.0 - b.w), x: (0.0 - b.x), y: (0.0 - b.y), z: (0.0 - b.z) } } else { b })
		dot2 = (if (dot < 0.0) { (0.0 - dot) } else { dot })
		(if (dot2 > 0.95) { quat_nlerp(a, b2, t) } else { ({
			inv_t = (1.0 - t)
			result = quat_add(quat_scale_by(a, inv_t), quat_scale_by(b2, t))
			quat_normalize(result)
		}) })
	})

	quat_nlerp : Quaternion.Quat, Quaternion.Quat, F64 -> Quaternion.Quat
	quat_nlerp = |a, b, t| ({
		inv_t = (1.0 - t)
		quat_normalize(quat_add(quat_scale_by(a, inv_t), quat_scale_by(b, t)))
	})

	quat_rotate_x : F64 -> Quaternion.Quat
	quat_rotate_x = |angle| quat_from_axis_angle(vec3_new(1.0, 0.0, 0.0), angle)

	quat_rotate_y : F64 -> Quaternion.Quat
	quat_rotate_y = |angle| quat_from_axis_angle(vec3_new(0.0, 1.0, 0.0), angle)

	quat_rotate_z : F64 -> Quaternion.Quat
	quat_rotate_z = |angle| quat_from_axis_angle(vec3_new(0.0, 0.0, 1.0), angle)

	vec3_add : Quaternion.Vec3, Quaternion.Vec3 -> Quaternion.Vec3
	vec3_add = |a, b| { vx: (a.vx + b.vx), vy: (a.vy + b.vy), vz: (a.vz + b.vz) }

	vec3_subtract : Quaternion.Vec3, Quaternion.Vec3 -> Quaternion.Vec3
	vec3_subtract = |a, b| { vx: (a.vx - b.vx), vy: (a.vy - b.vy), vz: (a.vz - b.vz) }

	vec3_scale : Quaternion.Vec3, F64 -> Quaternion.Vec3
	vec3_scale = |v, s| { vx: (v.vx * s), vy: (v.vy * s), vz: (v.vz * s) }

	vec3_dot : Quaternion.Vec3, Quaternion.Vec3 -> F64
	vec3_dot = |a, b| (((a.vx * b.vx) + (a.vy * b.vy)) + (a.vz * b.vz))

	vec3_cross : Quaternion.Vec3, Quaternion.Vec3 -> Quaternion.Vec3
	vec3_cross = |a, b| { vx: ((a.vy * b.vz) - (a.vz * b.vy)), vy: ((a.vz * b.vx) - (a.vx * b.vz)), vz: ((a.vx * b.vy) - (a.vy * b.vx)) }

	vec3_length_squared : Quaternion.Vec3 -> F64
	vec3_length_squared = |v| (((v.vx * v.vx) + (v.vy * v.vy)) + (v.vz * v.vz))

	format_quat : Quaternion.Quat -> Str
	format_quat = |q| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("(", Prelude.real_to_str(q.w)), ","), Prelude.real_to_str(q.x)), ","), Prelude.real_to_str(q.y)), ","), Prelude.real_to_str(q.z)), ")")

	format_vec3 : Quaternion.Vec3 -> Str
	format_vec3 = |v| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("(", Prelude.real_to_str(v.vx)), ","), Prelude.real_to_str(v.vy)), ","), Prelude.real_to_str(v.vz)), ")")
}
