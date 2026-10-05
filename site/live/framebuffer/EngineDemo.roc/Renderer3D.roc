# Renderer3D -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Matrix4
import Maybe
import Mesh
import Quaternion
import Texture

Renderer3D :: [].{
	R3dTriState := { r3t_base : I64, r3t_depth : I64, r3t_w : I64, r3t_h : I64, r3t_stride : I64, r3t_service : (I64 -> I64) }
	ProjVert := { pv_sx : I64, pv_sy : I64, pv_depth : I64, pv_nx : I64, pv_ny : I64, pv_nz : I64, pv_wu : I64, pv_wv : I64, pv_wx : F64, pv_wy : F64, pv_wz : F64, pv_lx : I64, pv_ly : I64, pv_ld : I64, pv_iw : I64 }.{
		is_eq : Renderer3D.ProjVert, Renderer3D.ProjVert -> Bool
		is_eq = |a, b| a.pv_sx == b.pv_sx and a.pv_sy == b.pv_sy and a.pv_depth == b.pv_depth and a.pv_nx == b.pv_nx and a.pv_ny == b.pv_ny and a.pv_nz == b.pv_nz and a.pv_wu == b.pv_wu and a.pv_wv == b.pv_wv and a.pv_wx == b.pv_wx and a.pv_wy == b.pv_wy and a.pv_wz == b.pv_wz and a.pv_lx == b.pv_lx and a.pv_ly == b.pv_ly and a.pv_ld == b.pv_ld and a.pv_iw == b.pv_iw
	}
	ClipVert := { cv_cx : F64, cv_cy : F64, cv_cz : F64, cv_cw : F64, cv_nx : I64, cv_ny : I64, cv_nz : I64, cv_wu : I64, cv_wv : I64, cv_wx : F64, cv_wy : F64, cv_wz : F64 }.{
		is_eq : Renderer3D.ClipVert, Renderer3D.ClipVert -> Bool
		is_eq = |a, b| a.cv_cx == b.cv_cx and a.cv_cy == b.cv_cy and a.cv_cz == b.cv_cz and a.cv_cw == b.cv_cw and a.cv_nx == b.cv_nx and a.cv_ny == b.cv_ny and a.cv_nz == b.cv_nz and a.cv_wu == b.cv_wu and a.cv_wv == b.cv_wv and a.cv_wx == b.cv_wx and a.cv_wy == b.cv_wy and a.cv_wz == b.cv_wz
	}
	R3dBary := { bw0 : I64, bw1 : I64, bw2 : I64, bw_sum : I64 }.{
		is_eq : Renderer3D.R3dBary, Renderer3D.R3dBary -> Bool
		is_eq = |a, b| eq_R3dBary(a, b)
	}
	R3dLightPre := { lp_lx : I64, lp_ly : I64, lp_lz : I64, lp_scale : I64, lp_cr : I64, lp_cg : I64, lp_cb : I64 }.{
		is_eq : Renderer3D.R3dLightPre, Renderer3D.R3dLightPre -> Bool
		is_eq = |a, b| eq_R3dLightPre(a, b)
	}
	R3dShadeCtx := { sc_mode : I64, sc_g0 : I64, sc_g1 : I64, sc_g2 : I64, sc_base : I64, sc_ar : I64, sc_ag : I64, sc_ab : I64, sc_diffuse : I64, sc_specular : I64, sc_shininess : I64, sc_ex : I64, sc_ey : I64, sc_ez : I64, sc_lights : List(Renderer3D.R3dLightPre), sc_amb : I64, sc_sh_base : I64, sc_sh_size : I64, sc_sh_bias : I64, sc_tex : Maybe.Maybe(Texture.EngineTexture) }.{
		is_eq : Renderer3D.R3dShadeCtx, Renderer3D.R3dShadeCtx -> Bool
		is_eq = |a, b| eq_R3dShadeCtx(a, b)
	}
	R3dShadow := { rs_base : I64, rs_size : I64, rs_bias : I64, rs_vp : Matrix4.Mat4 }.{
		is_eq : Renderer3D.R3dShadow, Renderer3D.R3dShadow -> Bool
		is_eq = |a, b| a.rs_base == b.rs_base and a.rs_size == b.rs_size and a.rs_bias == b.rs_bias and a.rs_vp == b.rs_vp
	}

	r3d_inv_w : F64 -> I64
	r3d_inv_w = |w| ({
		q : F64
		q = (1000000000.0 / w)
		(if (q >= 1000000000.0) { 1000000000 } else { (if (q < 1.0) { 1 } else { F64.to_i64_wrap(q) }) })
	})

	r3d_world_bounds : Mesh.MeshBounds, Matrix4.Mat4 -> Mesh.MeshBounds
	r3d_world_bounds = |b, model| ({
		c0 = Matrix4.mat4_transform_point(model, Quaternion.vec3_new(I64.to_f64(b.mb_min_x), I64.to_f64(b.mb_min_y), I64.to_f64(b.mb_min_z)))
		c1 = Matrix4.mat4_transform_point(model, Quaternion.vec3_new(I64.to_f64(b.mb_max_x), I64.to_f64(b.mb_min_y), I64.to_f64(b.mb_min_z)))
		c2 = Matrix4.mat4_transform_point(model, Quaternion.vec3_new(I64.to_f64(b.mb_min_x), I64.to_f64(b.mb_max_y), I64.to_f64(b.mb_min_z)))
		c3 = Matrix4.mat4_transform_point(model, Quaternion.vec3_new(I64.to_f64(b.mb_max_x), I64.to_f64(b.mb_max_y), I64.to_f64(b.mb_min_z)))
		c4 = Matrix4.mat4_transform_point(model, Quaternion.vec3_new(I64.to_f64(b.mb_min_x), I64.to_f64(b.mb_min_y), I64.to_f64(b.mb_max_z)))
		c5 = Matrix4.mat4_transform_point(model, Quaternion.vec3_new(I64.to_f64(b.mb_max_x), I64.to_f64(b.mb_min_y), I64.to_f64(b.mb_max_z)))
		c6 = Matrix4.mat4_transform_point(model, Quaternion.vec3_new(I64.to_f64(b.mb_min_x), I64.to_f64(b.mb_max_y), I64.to_f64(b.mb_max_z)))
		c7 = Matrix4.mat4_transform_point(model, Quaternion.vec3_new(I64.to_f64(b.mb_max_x), I64.to_f64(b.mb_max_y), I64.to_f64(b.mb_max_z)))
		Mesh.MeshBounds.{ mb_min_x: F64.to_i64_wrap(r3d_rmin8(c0.vx, c1.vx, c2.vx, c3.vx, c4.vx, c5.vx, c6.vx, c7.vx)), mb_min_y: F64.to_i64_wrap(r3d_rmin8(c0.vy, c1.vy, c2.vy, c3.vy, c4.vy, c5.vy, c6.vy, c7.vy)), mb_min_z: F64.to_i64_wrap(r3d_rmin8(c0.vz, c1.vz, c2.vz, c3.vz, c4.vz, c5.vz, c6.vz, c7.vz)), mb_max_x: F64.to_i64_wrap(r3d_rmax8(c0.vx, c1.vx, c2.vx, c3.vx, c4.vx, c5.vx, c6.vx, c7.vx)), mb_max_y: F64.to_i64_wrap(r3d_rmax8(c0.vy, c1.vy, c2.vy, c3.vy, c4.vy, c5.vy, c6.vy, c7.vy)), mb_max_z: F64.to_i64_wrap(r3d_rmax8(c0.vz, c1.vz, c2.vz, c3.vz, c4.vz, c5.vz, c6.vz, c7.vz)) }
	})

	r3d_rmin : F64, F64 -> F64
	r3d_rmin = |a, b| (if (a < b) { a } else { b })

	r3d_rmax : F64, F64 -> F64
	r3d_rmax = |a, b| (if (a > b) { a } else { b })

	r3d_rmin8 : F64, F64, F64, F64, F64, F64, F64, F64 -> F64
	r3d_rmin8 = |a, b, c, d, e, f, g, h| r3d_rmin(r3d_rmin(r3d_rmin(a, b), r3d_rmin(c, d)), r3d_rmin(r3d_rmin(e, f), r3d_rmin(g, h)))

	r3d_rmax8 : F64, F64, F64, F64, F64, F64, F64, F64 -> F64
	r3d_rmax8 = |a, b, c, d, e, f, g, h| r3d_rmax(r3d_rmax(r3d_rmax(a, b), r3d_rmax(c, d)), r3d_rmax(r3d_rmax(e, f), r3d_rmax(g, h)))

	eq_R3dBary : Renderer3D.R3dBary, Renderer3D.R3dBary -> Bool
	eq_R3dBary = |ex, ey| ((((ex.bw0 == ey.bw0) and (ex.bw1 == ey.bw1)) and (ex.bw2 == ey.bw2)) and (ex.bw_sum == ey.bw_sum))

	eq_R3dLightPre : Renderer3D.R3dLightPre, Renderer3D.R3dLightPre -> Bool
	eq_R3dLightPre = |ex, ey| (((((((ex.lp_lx == ey.lp_lx) and (ex.lp_ly == ey.lp_ly)) and (ex.lp_lz == ey.lp_lz)) and (ex.lp_scale == ey.lp_scale)) and (ex.lp_cr == ey.lp_cr)) and (ex.lp_cg == ey.lp_cg)) and (ex.lp_cb == ey.lp_cb))

	eq_R3dShadeCtx : Renderer3D.R3dShadeCtx, Renderer3D.R3dShadeCtx -> Bool
	eq_R3dShadeCtx = |ex, ey| ((((((((((((((((((((ex.sc_mode == ey.sc_mode) and (ex.sc_g0 == ey.sc_g0)) and (ex.sc_g1 == ey.sc_g1)) and (ex.sc_g2 == ey.sc_g2)) and (ex.sc_base == ey.sc_base)) and (ex.sc_ar == ey.sc_ar)) and (ex.sc_ag == ey.sc_ag)) and (ex.sc_ab == ey.sc_ab)) and (ex.sc_diffuse == ey.sc_diffuse)) and (ex.sc_specular == ey.sc_specular)) and (ex.sc_shininess == ey.sc_shininess)) and (ex.sc_ex == ey.sc_ex)) and (ex.sc_ey == ey.sc_ey)) and (ex.sc_ez == ey.sc_ez)) and (ex.sc_lights == ey.sc_lights)) and (ex.sc_amb == ey.sc_amb)) and (ex.sc_sh_base == ey.sc_sh_base)) and (ex.sc_sh_size == ey.sc_sh_size)) and (ex.sc_sh_bias == ey.sc_sh_bias)) and Maybe.eq_Maybe(ex.sc_tex, ey.sc_tex))
}
