# Matrix4 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Prelude
import Quaternion

Matrix4 :: [].{
	Mat4 : { m : List(F64) }
	Vec4 : { v4x : F64, v4y : F64, v4z : F64, v4w : F64 }

	mat4_identity : Matrix4.Mat4
	mat4_identity = { m: [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0] }

	mat4_zero : Matrix4.Mat4
	mat4_zero = { m: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0] }

	mat4_at : Matrix4.Mat4, I64, I64 -> F64
	mat4_at = |a, row, col| (List.get(a.m, I64.to_u64_wrap(((col * 4) + row))) ?? crash("list-at out of range"))

	mat4_set : Matrix4.Mat4, I64, I64, F64 -> Matrix4.Mat4
	mat4_set = |a, row, col, val| { m: (List.set(a.m, I64.to_u64_wrap(((col * 4) + row)), val) ?? crash("list-set-at past the end")) }

	mat4_mul : Matrix4.Mat4, Matrix4.Mat4 -> Matrix4.Mat4
	mat4_mul = |a, b| mat4_mul_build(a, b, 0, 0, [])

	mat4_mul_build : Matrix4.Mat4, Matrix4.Mat4, I64, I64, List(F64) -> Matrix4.Mat4
	mat4_mul_build = |a, b, col, row, acc| (if (col >= 4) { { m: acc } } else { (if (row >= 4) { mat4_mul_build(a, b, (col + 1), 0, acc) } else { ({
		val = mat4_dot_rc(a, b, row, col)
		mat4_mul_build(a, b, col, (row + 1), List.append(acc, val))
	}) }) })

	mat4_dot_rc : Matrix4.Mat4, Matrix4.Mat4, I64, I64 -> F64
	mat4_dot_rc = |a, b, row, col| ({
		s0 = (mat4_at(a, row, 0) * mat4_at(b, 0, col))
		s1 = (mat4_at(a, row, 1) * mat4_at(b, 1, col))
		s2 = (mat4_at(a, row, 2) * mat4_at(b, 2, col))
		s3 = (mat4_at(a, row, 3) * mat4_at(b, 3, col))
		(((s0 + s1) + s2) + s3)
	})

	mat4_transpose : Matrix4.Mat4 -> Matrix4.Mat4
	mat4_transpose = |a| { m: [mat4_at(a, 0, 0), mat4_at(a, 1, 0), mat4_at(a, 2, 0), mat4_at(a, 3, 0), mat4_at(a, 0, 1), mat4_at(a, 1, 1), mat4_at(a, 2, 1), mat4_at(a, 3, 1), mat4_at(a, 0, 2), mat4_at(a, 1, 2), mat4_at(a, 2, 2), mat4_at(a, 3, 2), mat4_at(a, 0, 3), mat4_at(a, 1, 3), mat4_at(a, 2, 3), mat4_at(a, 3, 3)] }

	mat4_translate : F64, F64, F64 -> Matrix4.Mat4
	mat4_translate = |x, y, z| { m: [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, x, y, z, 1.0] }

	mat4_scale : F64, F64, F64 -> Matrix4.Mat4
	mat4_scale = |x, y, z| { m: [x, 0.0, 0.0, 0.0, 0.0, y, 0.0, 0.0, 0.0, 0.0, z, 0.0, 0.0, 0.0, 0.0, 1.0] }

	mat4_from_quat : Quaternion.Quat -> Matrix4.Mat4
	mat4_from_quat = |q| ({
		xx = (q.x * q.x)
		yy = (q.y * q.y)
		zz = (q.z * q.z)
		xy = (q.x * q.y)
		xz = (q.x * q.z)
		yz = (q.y * q.z)
		wx = (q.w * q.x)
		wy = (q.w * q.y)
		wz = (q.w * q.z)
		{ m: [(1.0 - (2.0 * (yy + zz))), (2.0 * (xy + wz)), (2.0 * (xz - wy)), 0.0, (2.0 * (xy - wz)), (1.0 - (2.0 * (xx + zz))), (2.0 * (yz + wx)), 0.0, (2.0 * (xz + wy)), (2.0 * (yz - wx)), (1.0 - (2.0 * (xx + yy))), 0.0, 0.0, 0.0, 0.0, 1.0] }
	})

	mat4_transform_point : Matrix4.Mat4, Quaternion.Vec3 -> Quaternion.Vec3
	mat4_transform_point = |m, v| ({
		x = ((((mat4_at(m, 0, 0) * v.vx) + (mat4_at(m, 0, 1) * v.vy)) + (mat4_at(m, 0, 2) * v.vz)) + mat4_at(m, 0, 3))
		y = ((((mat4_at(m, 1, 0) * v.vx) + (mat4_at(m, 1, 1) * v.vy)) + (mat4_at(m, 1, 2) * v.vz)) + mat4_at(m, 1, 3))
		z = ((((mat4_at(m, 2, 0) * v.vx) + (mat4_at(m, 2, 1) * v.vy)) + (mat4_at(m, 2, 2) * v.vz)) + mat4_at(m, 2, 3))
		{ vx: x, vy: y, vz: z }
	})

	mat4_perspective : F64, F64, F64, F64 -> Matrix4.Mat4
	mat4_perspective = |fov, aspect, near, far| ({
		half_fov = (fov / 2.0)
		sin_h = mat4_sin_approx(half_fov)
		cos_h = mat4_cos_approx(half_fov)
		f = (if Prelude.approx_eq(sin_h, 0.0) { 1000.0 } else { (cos_h / sin_h) })
		fx = (if Prelude.approx_eq(aspect, 0.0) { f } else { (f / aspect) })
		dz = (near - far)
		a = (if Prelude.approx_eq(dz, 0.0) { 0.0 } else { ((far + near) / dz) })
		b = (if Prelude.approx_eq(dz, 0.0) { 0.0 } else { (((2.0 * far) * near) / dz) })
		{ m: [fx, 0.0, 0.0, 0.0, 0.0, f, 0.0, 0.0, 0.0, 0.0, a, (-1.0), 0.0, 0.0, b, 0.0] }
	})

	mat4_ortho : F64, F64, F64, F64, F64, F64 -> Matrix4.Mat4
	mat4_ortho = |left, right, bottom, top, near, far| ({
		dx = (right - left)
		dy = (top - bottom)
		dz = (far - near)
		sx = (if Prelude.approx_eq(dx, 0.0) { 0.0 } else { (2.0 / dx) })
		sy = (if Prelude.approx_eq(dy, 0.0) { 0.0 } else { (2.0 / dy) })
		sz = (if Prelude.approx_eq(dz, 0.0) { 0.0 } else { ((-2.0) / dz) })
		tx = (if Prelude.approx_eq(dx, 0.0) { 0.0 } else { ((-(right + left)) / dx) })
		ty = (if Prelude.approx_eq(dy, 0.0) { 0.0 } else { ((-(top + bottom)) / dy) })
		tz = (if Prelude.approx_eq(dz, 0.0) { 0.0 } else { ((-(far + near)) / dz) })
		{ m: [sx, 0.0, 0.0, 0.0, 0.0, sy, 0.0, 0.0, 0.0, 0.0, sz, 0.0, tx, ty, tz, 1.0] }
	})

	mat4_look_at : Quaternion.Vec3, Quaternion.Vec3, Quaternion.Vec3 -> Matrix4.Mat4
	mat4_look_at = |eye, target, up| ({
		fwd = mat4_v3_normalize(Quaternion.vec3_subtract(target, eye))
		right = mat4_v3_normalize(Quaternion.vec3_cross(fwd, up))
		cam_up = Quaternion.vec3_cross(right, fwd)
		tx = (-Quaternion.vec3_dot(right, eye))
		ty = (-Quaternion.vec3_dot(cam_up, eye))
		tz = Quaternion.vec3_dot(fwd, eye)
		{ m: [right.vx, cam_up.vx, (-fwd.vx), 0.0, right.vy, cam_up.vy, (-fwd.vy), 0.0, right.vz, cam_up.vz, (-fwd.vz), 0.0, tx, ty, tz, 1.0] }
	})

	mat4_inverse : Matrix4.Mat4 -> Matrix4.Mat4
	mat4_inverse = |a| ({
		s0 = ((mat4_at(a, 0, 0) * mat4_at(a, 1, 1)) - (mat4_at(a, 1, 0) * mat4_at(a, 0, 1)))
		s1 = ((mat4_at(a, 0, 0) * mat4_at(a, 1, 2)) - (mat4_at(a, 1, 0) * mat4_at(a, 0, 2)))
		s2 = ((mat4_at(a, 0, 0) * mat4_at(a, 1, 3)) - (mat4_at(a, 1, 0) * mat4_at(a, 0, 3)))
		s3 = ((mat4_at(a, 0, 1) * mat4_at(a, 1, 2)) - (mat4_at(a, 1, 1) * mat4_at(a, 0, 2)))
		s4 = ((mat4_at(a, 0, 1) * mat4_at(a, 1, 3)) - (mat4_at(a, 1, 1) * mat4_at(a, 0, 3)))
		s5 = ((mat4_at(a, 0, 2) * mat4_at(a, 1, 3)) - (mat4_at(a, 1, 2) * mat4_at(a, 0, 3)))
		c5 = ((mat4_at(a, 2, 2) * mat4_at(a, 3, 3)) - (mat4_at(a, 3, 2) * mat4_at(a, 2, 3)))
		c4 = ((mat4_at(a, 2, 1) * mat4_at(a, 3, 3)) - (mat4_at(a, 3, 1) * mat4_at(a, 2, 3)))
		c3 = ((mat4_at(a, 2, 1) * mat4_at(a, 3, 2)) - (mat4_at(a, 3, 1) * mat4_at(a, 2, 2)))
		c2 = ((mat4_at(a, 2, 0) * mat4_at(a, 3, 3)) - (mat4_at(a, 3, 0) * mat4_at(a, 2, 3)))
		c1 = ((mat4_at(a, 2, 0) * mat4_at(a, 3, 2)) - (mat4_at(a, 3, 0) * mat4_at(a, 2, 2)))
		c0 = ((mat4_at(a, 2, 0) * mat4_at(a, 3, 1)) - (mat4_at(a, 3, 0) * mat4_at(a, 2, 1)))
		det = ((((((s0 * c5) - (s1 * c4)) + (s2 * c3)) + (s3 * c2)) - (s4 * c1)) + (s5 * c0))
		(if Prelude.approx_eq(det, 0.0) { mat4_identity } else { ({
			inv_det = (1.0 / det)
			r00 = ((((mat4_at(a, 1, 1) * c5) - (mat4_at(a, 1, 2) * c4)) + (mat4_at(a, 1, 3) * c3)) * inv_det)
			r01 = (((((-mat4_at(a, 0, 1)) * c5) + (mat4_at(a, 0, 2) * c4)) - (mat4_at(a, 0, 3) * c3)) * inv_det)
			r02 = ((((mat4_at(a, 3, 1) * s5) - (mat4_at(a, 3, 2) * s4)) + (mat4_at(a, 3, 3) * s3)) * inv_det)
			r03 = (((((-mat4_at(a, 2, 1)) * s5) + (mat4_at(a, 2, 2) * s4)) - (mat4_at(a, 2, 3) * s3)) * inv_det)
			r10 = (((((-mat4_at(a, 1, 0)) * c5) + (mat4_at(a, 1, 2) * c2)) - (mat4_at(a, 1, 3) * c1)) * inv_det)
			r11 = ((((mat4_at(a, 0, 0) * c5) - (mat4_at(a, 0, 2) * c2)) + (mat4_at(a, 0, 3) * c1)) * inv_det)
			r12 = (((((-mat4_at(a, 3, 0)) * s5) + (mat4_at(a, 3, 2) * s2)) - (mat4_at(a, 3, 3) * s1)) * inv_det)
			r13 = ((((mat4_at(a, 2, 0) * s5) - (mat4_at(a, 2, 2) * s2)) + (mat4_at(a, 2, 3) * s1)) * inv_det)
			r20 = ((((mat4_at(a, 1, 0) * c4) - (mat4_at(a, 1, 1) * c2)) + (mat4_at(a, 1, 3) * c0)) * inv_det)
			r21 = (((((-mat4_at(a, 0, 0)) * c4) + (mat4_at(a, 0, 1) * c2)) - (mat4_at(a, 0, 3) * c0)) * inv_det)
			r22 = ((((mat4_at(a, 3, 0) * s4) - (mat4_at(a, 3, 1) * s2)) + (mat4_at(a, 3, 3) * s0)) * inv_det)
			r23 = (((((-mat4_at(a, 2, 0)) * s4) + (mat4_at(a, 2, 1) * s2)) - (mat4_at(a, 2, 3) * s0)) * inv_det)
			r30 = (((((-mat4_at(a, 1, 0)) * c3) + (mat4_at(a, 1, 1) * c1)) - (mat4_at(a, 1, 2) * c0)) * inv_det)
			r31 = ((((mat4_at(a, 0, 0) * c3) - (mat4_at(a, 0, 1) * c1)) + (mat4_at(a, 0, 2) * c0)) * inv_det)
			r32 = (((((-mat4_at(a, 3, 0)) * s3) + (mat4_at(a, 3, 1) * s1)) - (mat4_at(a, 3, 2) * s0)) * inv_det)
			r33 = ((((mat4_at(a, 2, 0) * s3) - (mat4_at(a, 2, 1) * s1)) + (mat4_at(a, 2, 2) * s0)) * inv_det)
			{ m: [r00, r01, r02, r03, r10, r11, r12, r13, r20, r21, r22, r23, r30, r31, r32, r33] }
		}) })
	})

	mat4_transform_vec4 : Matrix4.Mat4, Matrix4.Vec4 -> Matrix4.Vec4
	mat4_transform_vec4 = |m, v| ({
		x = ((((mat4_at(m, 0, 0) * v.v4x) + (mat4_at(m, 0, 1) * v.v4y)) + (mat4_at(m, 0, 2) * v.v4z)) + (mat4_at(m, 0, 3) * v.v4w))
		y = ((((mat4_at(m, 1, 0) * v.v4x) + (mat4_at(m, 1, 1) * v.v4y)) + (mat4_at(m, 1, 2) * v.v4z)) + (mat4_at(m, 1, 3) * v.v4w))
		z = ((((mat4_at(m, 2, 0) * v.v4x) + (mat4_at(m, 2, 1) * v.v4y)) + (mat4_at(m, 2, 2) * v.v4z)) + (mat4_at(m, 2, 3) * v.v4w))
		w = ((((mat4_at(m, 3, 0) * v.v4x) + (mat4_at(m, 3, 1) * v.v4y)) + (mat4_at(m, 3, 2) * v.v4z)) + (mat4_at(m, 3, 3) * v.v4w))
		{ v4x: x, v4y: y, v4z: z, v4w: w }
	})

	mat4_sin_approx : F64 -> F64
	mat4_sin_approx = |rad| ({
		x = rad
		x3 = ((x * x) * x)
		(x - (x3 / 6.0))
	})

	mat4_cos_approx : F64 -> F64
	mat4_cos_approx = |rad| ({
		x2 = (rad * rad)
		x4 = (x2 * x2)
		((1.0 - (x2 / 2.0)) + (x4 / 24.0))
	})

	mat4_v3_length : Quaternion.Vec3 -> F64
	mat4_v3_length = |v| ({
		sq = (((v.vx * v.vx) + (v.vy * v.vy)) + (v.vz * v.vz))
		mat4_sqrt(sq)
	})

	mat4_v3_normalize : Quaternion.Vec3 -> Quaternion.Vec3
	mat4_v3_normalize = |v| ({
		len = mat4_v3_length(v)
		(if Prelude.approx_eq(len, 0.0) { Quaternion.vec3_zero } else { { vx: (v.vx / len), vy: (v.vy / len), vz: (v.vz / len) } })
	})

	mat4_sqrt : F64 -> F64
	mat4_sqrt = |n| (if (n <= 0.0) { 0.0 } else { mat4_sqrt_loop(n, ((n / 2.0) + 1.0)) })

	mat4_sqrt_loop : F64, F64 -> F64
	mat4_sqrt_loop = |n, guess| ({
		next = ((guess + (n / guess)) / 2.0)
		(if Prelude.approx_eq(next, guess) { next } else { mat4_sqrt_loop(n, next) })
	})

	format_mat4_row : Matrix4.Mat4, I64 -> Str
	format_mat4_row = |a, row| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Prelude.real_to_str(mat4_at(a, row, 0)), " "), Prelude.real_to_str(mat4_at(a, row, 1))), " "), Prelude.real_to_str(mat4_at(a, row, 2))), " "), Prelude.real_to_str(mat4_at(a, row, 3)))
}
