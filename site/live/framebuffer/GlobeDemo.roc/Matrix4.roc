# Matrix4 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Prelude
import Quaternion

Matrix4 :: [].{
	Mat4 := { m : List(F64) }.{
		is_eq : Matrix4.Mat4, Matrix4.Mat4 -> Bool
		is_eq = |a, b| a.m == b.m
	}
	Vec4 := { v4x : F64, v4y : F64, v4z : F64, v4w : F64 }.{
		is_eq : Matrix4.Vec4, Matrix4.Vec4 -> Bool
		is_eq = |a, b| a.v4x == b.v4x and a.v4y == b.v4y and a.v4z == b.v4z and a.v4w == b.v4w
	}

	mat4_at : Matrix4.Mat4, I64, I64 -> F64
	mat4_at = |a, row, col| (List.get(a.m, I64.to_u64_wrap(((col * 4) + row))) ?? crash("list-at out of range"))

	mat4_mul : Matrix4.Mat4, Matrix4.Mat4 -> Matrix4.Mat4
	mat4_mul = |a, b| mat4_mul_build(a, b, 0, 0, [])

	mat4_mul_build : Matrix4.Mat4, Matrix4.Mat4, I64, I64, List(F64) -> Matrix4.Mat4
	mat4_mul_build = |a, b, col, row, acc| (if (col >= 4) { Matrix4.Mat4.{ m: acc } } else { (if (row >= 4) { mat4_mul_build(a, b, (col + 1), 0, acc) } else { ({
		val : F64
		val = mat4_dot_rc(a, b, row, col)
		mat4_mul_build(a, b, col, (row + 1), List.append(acc, val))
	}) }) })

	mat4_dot_rc : Matrix4.Mat4, Matrix4.Mat4, I64, I64 -> F64
	mat4_dot_rc = |a, b, row, col| ({
		s0 : F64
		s0 = (mat4_at(a, row, 0) * mat4_at(b, 0, col))
		s1 : F64
		s1 = (mat4_at(a, row, 1) * mat4_at(b, 1, col))
		s2 : F64
		s2 = (mat4_at(a, row, 2) * mat4_at(b, 2, col))
		s3 : F64
		s3 = (mat4_at(a, row, 3) * mat4_at(b, 3, col))
		(((s0 + s1) + s2) + s3)
	})

	mat4_perspective : F64, F64, F64, F64 -> Matrix4.Mat4
	mat4_perspective = |fov, aspect, near, far| ({
		half_fov : F64
		half_fov = (fov / 2.0)
		sin_h : F64
		sin_h = mat4_sin_approx(half_fov)
		cos_h : F64
		cos_h = mat4_cos_approx(half_fov)
		f : F64
		f = (if Prelude.approx_eq(sin_h, 0.0) { 1000.0 } else { (cos_h / sin_h) })
		fx : F64
		fx = (if Prelude.approx_eq(aspect, 0.0) { f } else { (f / aspect) })
		dz : F64
		dz = (near - far)
		a : F64
		a = (if Prelude.approx_eq(dz, 0.0) { 0.0 } else { ((far + near) / dz) })
		b : F64
		b = (if Prelude.approx_eq(dz, 0.0) { 0.0 } else { (((2.0 * far) * near) / dz) })
		Matrix4.Mat4.{ m: [fx, 0.0, 0.0, 0.0, 0.0, f, 0.0, 0.0, 0.0, 0.0, a, (-1.0), 0.0, 0.0, b, 0.0] }
	})

	mat4_look_at : Quaternion.Vec3, Quaternion.Vec3, Quaternion.Vec3 -> Matrix4.Mat4
	mat4_look_at = |eye, target, up| ({
		fwd = mat4_v3_normalize(Quaternion.vec3_subtract(target, eye))
		right = mat4_v3_normalize(Quaternion.vec3_cross(fwd, up))
		cam_up = Quaternion.vec3_cross(right, fwd)
		tx : F64
		tx = (-Quaternion.vec3_dot(right, eye))
		ty : F64
		ty = (-Quaternion.vec3_dot(cam_up, eye))
		tz : F64
		tz = Quaternion.vec3_dot(fwd, eye)
		Matrix4.Mat4.{ m: [right.vx, cam_up.vx, (-fwd.vx), 0.0, right.vy, cam_up.vy, (-fwd.vy), 0.0, right.vz, cam_up.vz, (-fwd.vz), 0.0, tx, ty, tz, 1.0] }
	})

	mat4_transform_vec4 : Matrix4.Mat4, Matrix4.Vec4 -> Matrix4.Vec4
	mat4_transform_vec4 = |m, v| ({
		x : F64
		x = ((((mat4_at(m, 0, 0) * v.v4x) + (mat4_at(m, 0, 1) * v.v4y)) + (mat4_at(m, 0, 2) * v.v4z)) + (mat4_at(m, 0, 3) * v.v4w))
		y : F64
		y = ((((mat4_at(m, 1, 0) * v.v4x) + (mat4_at(m, 1, 1) * v.v4y)) + (mat4_at(m, 1, 2) * v.v4z)) + (mat4_at(m, 1, 3) * v.v4w))
		z : F64
		z = ((((mat4_at(m, 2, 0) * v.v4x) + (mat4_at(m, 2, 1) * v.v4y)) + (mat4_at(m, 2, 2) * v.v4z)) + (mat4_at(m, 2, 3) * v.v4w))
		w : F64
		w = ((((mat4_at(m, 3, 0) * v.v4x) + (mat4_at(m, 3, 1) * v.v4y)) + (mat4_at(m, 3, 2) * v.v4z)) + (mat4_at(m, 3, 3) * v.v4w))
		Matrix4.Vec4.{ v4x: x, v4y: y, v4z: z, v4w: w }
	})

	mat4_sin_approx : F64 -> F64
	mat4_sin_approx = |rad| ({
		x : F64
		x = rad
		x3 : F64
		x3 = ((x * x) * x)
		(x - (x3 / 6.0))
	})

	mat4_cos_approx : F64 -> F64
	mat4_cos_approx = |rad| ({
		x2 : F64
		x2 = (rad * rad)
		x4 : F64
		x4 = (x2 * x2)
		((1.0 - (x2 / 2.0)) + (x4 / 24.0))
	})

	mat4_v3_length : Quaternion.Vec3 -> F64
	mat4_v3_length = |v| ({
		sq : F64
		sq = (((v.vx * v.vx) + (v.vy * v.vy)) + (v.vz * v.vz))
		mat4_sqrt(sq)
	})

	mat4_v3_normalize : Quaternion.Vec3 -> Quaternion.Vec3
	mat4_v3_normalize = |v| ({
		len : F64
		len = mat4_v3_length(v)
		(if Prelude.approx_eq(len, 0.0) { Quaternion.vec3_zero } else { Quaternion.Vec3.{ vx: (v.vx / len), vy: (v.vy / len), vz: (v.vz / len) } })
	})

	mat4_sqrt : F64 -> F64
	mat4_sqrt = |n| (if (n <= 0.0) { 0.0 } else { mat4_sqrt_loop(n, ((n / 2.0) + 1.0)) })

	mat4_sqrt_loop : F64, F64 -> F64
	mat4_sqrt_loop = |n, guess| ({
		next : F64
		next = ((guess + (n / guess)) / 2.0)
		(if Prelude.approx_eq(next, guess) { next } else { mat4_sqrt_loop(n, next) })
	})
}
