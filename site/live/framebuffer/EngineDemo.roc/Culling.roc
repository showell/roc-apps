# Culling -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Matrix4
import Mesh
import Prelude

Culling :: [].{
	FrustumPlane : { fp_a : F64, fp_b : F64, fp_c : F64, fp_d : F64 }
	Frustum : { fr_left : Culling.FrustumPlane, fr_right : Culling.FrustumPlane, fr_bottom : Culling.FrustumPlane, fr_top : Culling.FrustumPlane, fr_near : Culling.FrustumPlane, fr_far : Culling.FrustumPlane }
	FrustumResult : [FrInside, FrIntersect, FrOutside]

	frustum_extract : Matrix4.Mat4 -> Culling.Frustum
	frustum_extract = |vp| ({
		m00 = Matrix4.mat4_at(vp, 0, 0)
		m01 = Matrix4.mat4_at(vp, 0, 1)
		m02 = Matrix4.mat4_at(vp, 0, 2)
		m03 = Matrix4.mat4_at(vp, 0, 3)
		m10 = Matrix4.mat4_at(vp, 1, 0)
		m11 = Matrix4.mat4_at(vp, 1, 1)
		m12 = Matrix4.mat4_at(vp, 1, 2)
		m13 = Matrix4.mat4_at(vp, 1, 3)
		m20 = Matrix4.mat4_at(vp, 2, 0)
		m21 = Matrix4.mat4_at(vp, 2, 1)
		m22 = Matrix4.mat4_at(vp, 2, 2)
		m23 = Matrix4.mat4_at(vp, 2, 3)
		m30 = Matrix4.mat4_at(vp, 3, 0)
		m31 = Matrix4.mat4_at(vp, 3, 1)
		m32 = Matrix4.mat4_at(vp, 3, 2)
		m33 = Matrix4.mat4_at(vp, 3, 3)
		{ fr_left: fp_normalize({ fp_a: (m30 + m00), fp_b: (m31 + m01), fp_c: (m32 + m02), fp_d: (m33 + m03) }), fr_right: fp_normalize({ fp_a: (m30 - m00), fp_b: (m31 - m01), fp_c: (m32 - m02), fp_d: (m33 - m03) }), fr_bottom: fp_normalize({ fp_a: (m30 + m10), fp_b: (m31 + m11), fp_c: (m32 + m12), fp_d: (m33 + m13) }), fr_top: fp_normalize({ fp_a: (m30 - m10), fp_b: (m31 - m11), fp_c: (m32 - m12), fp_d: (m33 - m13) }), fr_near: fp_normalize({ fp_a: (m30 + m20), fp_b: (m31 + m21), fp_c: (m32 + m22), fp_d: (m33 + m23) }), fr_far: fp_normalize({ fp_a: (m30 - m20), fp_b: (m31 - m21), fp_c: (m32 - m22), fp_d: (m33 - m23) }) }
	})

	fp_normalize : Culling.FrustumPlane -> Culling.FrustumPlane
	fp_normalize = |p| ({
		len = Matrix4.mat4_sqrt((((p.fp_a * p.fp_a) + (p.fp_b * p.fp_b)) + (p.fp_c * p.fp_c)))
		(if Prelude.approx_eq(len, 0.0) { p } else { { fp_a: (p.fp_a / len), fp_b: (p.fp_b / len), fp_c: (p.fp_c / len), fp_d: (p.fp_d / len) } })
	})

	frustum_test_aabb : Culling.Frustum, Mesh.MeshBounds -> Culling.FrustumResult
	frustum_test_aabb = |fr, b| ({
		r0 = fp_test_aabb(fr.fr_left, b)
		(if (r0 == (0 - 1)) { FrOutside } else { ({
			r1 = fp_test_aabb(fr.fr_right, b)
			(if (r1 == (0 - 1)) { FrOutside } else { ({
				r2 = fp_test_aabb(fr.fr_bottom, b)
				(if (r2 == (0 - 1)) { FrOutside } else { ({
					r3 = fp_test_aabb(fr.fr_top, b)
					(if (r3 == (0 - 1)) { FrOutside } else { ({
						r4 = fp_test_aabb(fr.fr_near, b)
						(if (r4 == (0 - 1)) { FrOutside } else { ({
							r5 = fp_test_aabb(fr.fr_far, b)
							(if (r5 == (0 - 1)) { FrOutside } else { (if ((((((r0 + r1) + r2) + r3) + r4) + r5) == 6) { FrInside } else { FrIntersect }) })
						}) })
					}) })
				}) })
			}) })
		}) })
	})

	fp_test_aabb : Culling.FrustumPlane, Mesh.MeshBounds -> I64
	fp_test_aabb = |p, b| ({
		px = (if (p.fp_a >= 0.0) { b.mb_max_x } else { b.mb_min_x })
		py = (if (p.fp_b >= 0.0) { b.mb_max_y } else { b.mb_min_y })
		pz = (if (p.fp_c >= 0.0) { b.mb_max_z } else { b.mb_min_z })
		nx = (if (p.fp_a >= 0.0) { b.mb_min_x } else { b.mb_max_x })
		ny = (if (p.fp_b >= 0.0) { b.mb_min_y } else { b.mb_max_y })
		nz = (if (p.fp_c >= 0.0) { b.mb_min_z } else { b.mb_max_z })
		d_pos = ((((p.fp_a * I64.to_f64(px)) + (p.fp_b * I64.to_f64(py))) + (p.fp_c * I64.to_f64(pz))) + p.fp_d)
		(if (d_pos < 0.0) { (0 - 1) } else { ({
			d_neg = ((((p.fp_a * I64.to_f64(nx)) + (p.fp_b * I64.to_f64(ny))) + (p.fp_c * I64.to_f64(nz))) + p.fp_d)
			(if (d_neg >= 0.0) { 1 } else { 0 })
		}) })
	})

	cull_backface : I64, I64, I64, I64, I64, I64 -> Bool
	cull_backface = |ax, ay, bx, by, cx, cy| ({
		cross = (((bx - ax) * (cy - ay)) - ((by - ay) * (cx - ax)))
		(cross > 0)
	})

	format_frustum_result : Culling.FrustumResult -> Str
	format_frustum_result = |r| (match r {
		FrInside => "inside"
		FrIntersect => "intersect"
		FrOutside => "outside"
	})

	eq_FrustumResult : Culling.FrustumResult, Culling.FrustumResult -> Bool
	eq_FrustumResult = |ex, ey| (match ex {
		FrInside => (match ey {
			FrInside => True
			_ => False
		})
		FrIntersect => (match ey {
			FrIntersect => True
			_ => False
		})
		FrOutside => (match ey {
			FrOutside => True
			_ => False
		})
	})
}
