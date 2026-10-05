# Quaternion -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Quaternion :: [].{
	Quat := { w : F64, x : F64, y : F64, z : F64 }.{
		is_eq : Quaternion.Quat, Quaternion.Quat -> Bool
		is_eq = |a, b| a.w == b.w and a.x == b.x and a.y == b.y and a.z == b.z
	}
	Vec3 := { vx : F64, vy : F64, vz : F64 }.{
		is_eq : Quaternion.Vec3, Quaternion.Vec3 -> Bool
		is_eq = |a, b| a.vx == b.vx and a.vy == b.vy and a.vz == b.vz
	}

	vec3_new : F64, F64, F64 -> Quaternion.Vec3
	vec3_new = |x, y, z| Quaternion.Vec3.{ vx: x, vy: y, vz: z }

	vec3_zero : Quaternion.Vec3
	vec3_zero = Quaternion.Vec3.{ vx: 0.0, vy: 0.0, vz: 0.0 }

	vec3_add : Quaternion.Vec3, Quaternion.Vec3 -> Quaternion.Vec3
	vec3_add = |a, b| Quaternion.Vec3.{ vx: (a.vx + b.vx), vy: (a.vy + b.vy), vz: (a.vz + b.vz) }

	vec3_subtract : Quaternion.Vec3, Quaternion.Vec3 -> Quaternion.Vec3
	vec3_subtract = |a, b| Quaternion.Vec3.{ vx: (a.vx - b.vx), vy: (a.vy - b.vy), vz: (a.vz - b.vz) }

	vec3_scale : Quaternion.Vec3, F64 -> Quaternion.Vec3
	vec3_scale = |v, s| Quaternion.Vec3.{ vx: (v.vx * s), vy: (v.vy * s), vz: (v.vz * s) }

	vec3_dot : Quaternion.Vec3, Quaternion.Vec3 -> F64
	vec3_dot = |a, b| (((a.vx * b.vx) + (a.vy * b.vy)) + (a.vz * b.vz))
}
