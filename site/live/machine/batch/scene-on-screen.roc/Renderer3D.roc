# Renderer3D -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Color
import Culling
import Machine
import Material
import Matrix4
import Maybe
import Mesh
import Quaternion
import Rasterizer
import Scene3D
import Texture

Renderer3D :: [].{
	R3dTriState : { r3t_base : I64, r3t_depth : I64, r3t_w : I64, r3t_h : I64, r3t_stride : I64 }
	ProjVert : { pv_sx : I64, pv_sy : I64, pv_depth : I64, pv_nx : I64, pv_ny : I64, pv_nz : I64, pv_wu : I64, pv_wv : I64, pv_wx : F64, pv_wy : F64, pv_wz : F64, pv_lx : I64, pv_ly : I64, pv_ld : I64 }
	ClipVert : { cv_cx : F64, cv_cy : F64, cv_cz : F64, cv_cw : F64, cv_nx : I64, cv_ny : I64, cv_nz : I64, cv_wu : I64, cv_wv : I64, cv_wx : F64, cv_wy : F64, cv_wz : F64 }
	R3dBary : { bw0 : I64, bw1 : I64, bw2 : I64, bw_sum : I64 }
	R3dLightPre : { lp_lx : I64, lp_ly : I64, lp_lz : I64, lp_scale : I64, lp_cr : I64, lp_cg : I64, lp_cb : I64 }
	R3dShadeCtx : { sc_mode : I64, sc_g0 : I64, sc_g1 : I64, sc_g2 : I64, sc_base : I64, sc_ar : I64, sc_ag : I64, sc_ab : I64, sc_diffuse : I64, sc_specular : I64, sc_shininess : I64, sc_ex : I64, sc_ey : I64, sc_ez : I64, sc_lights : List(Renderer3D.R3dLightPre), sc_amb : I64, sc_sh_base : I64, sc_sh_size : I64, sc_sh_bias : I64, sc_tex : Maybe.Maybe(Texture.EngineTexture) }
	R3dShadow : { rs_base : I64, rs_size : I64, rs_bias : I64, rs_vp : Matrix4.Mat4 }

	r3d_far_depth : I64
	r3d_far_depth = 999999999

	r3d_min_base : I64
	r3d_min_base = 1048576

	r3d_refused : I64
	r3d_refused = (0 - 1)

	r3d_base_ok : I64 -> Bool
	r3d_base_ok = |base| (base >= r3d_min_base)

	r3d_fill_32! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_fill_32! = |machine, base, value, i, n| (if (r3d_base_ok(base) == False) { (machine, r3d_refused) } else { r3d_fill_32_at!(machine, base, value, i, n) })

	r3d_fill_32_at! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_fill_32_at! = |machine, base, value, i, n| (if (i >= n) { (machine, 0) } else { ({
		(machine1, _d) = Machine.store!(machine, base, (i * 4), value, 4)
		r3d_fill_32_at!(machine1, base, value, (i + 1), n)
	}) })

	r3d_fill_span! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_fill_span! = |machine, base, off, w, color, i| (if (r3d_base_ok(base) == False) { (machine, r3d_refused) } else { r3d_fill_span_at!(machine, base, off, w, color, i) })

	r3d_fill_span_at! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_fill_span_at! = |machine, base, off, w, color, i| (if (i >= w) { (machine, 0) } else { ({
		(machine1, _d) = Machine.store!(machine, base, ((off + i) * 4), color, 4)
		r3d_fill_span_at!(machine1, base, off, w, color, (i + 1))
	}) })

	r3d_fill_rows! : Machine.Machine, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_fill_rows! = |machine, base, stride, w, h, color, y| (if (r3d_base_ok(base) == False) { (machine, r3d_refused) } else { r3d_fill_rows_at!(machine, base, stride, w, h, color, y) })

	r3d_fill_rows_at! : Machine.Machine, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_fill_rows_at! = |machine, base, stride, w, h, color, y| (if (y >= h) { (machine, 0) } else { ({
		(machine1, _d) = r3d_fill_span_at!(machine, base, (y * stride), w, color, 0)
		r3d_fill_rows_at!(machine1, base, stride, w, h, color, (y + 1))
	}) })

	r3d_target_new! : Machine.Machine, I64, I64, I64 => (Machine.Machine, Renderer3D.R3dTriState)
	r3d_target_new! = |machine, w, h, bg| ({
		(machine5, machine__1) = ({
		(machine1, px) = Machine.alloc(machine, ((w * h) * 4))
		(machine2, dp) = Machine.alloc(machine1, ((w * h) * 4))
		(machine3, _c1) = r3d_fill_32!(machine2, px, bg, 0, (w * h))
		(machine4, _c2) = r3d_fill_32!(machine3, dp, r3d_far_depth, 0, (w * h))
		(machine4, { r3t_base: px, r3t_depth: dp, r3t_w: w, r3t_h: h, r3t_stride: w })
	})
		(machine5, machine__1)
	})

	r3d_target_at! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, Renderer3D.R3dTriState)
	r3d_target_at! = |machine, base, stride, w, h, bg| ({
		(machine4, machine__2) = ({
		(machine1, dp) = Machine.alloc(machine, ((w * h) * 4))
		(machine2, _c1) = r3d_fill_rows!(machine1, base, stride, w, h, bg, 0)
		(machine3, _c2) = r3d_fill_32!(machine2, dp, r3d_far_depth, 0, (w * h))
		(machine3, { r3t_base: base, r3t_depth: dp, r3t_w: w, r3t_h: h, r3t_stride: stride })
	})
		(machine4, machine__2)
	})

	r3d_target_clear! : Machine.Machine, Renderer3D.R3dTriState, I64 => (Machine.Machine, I64)
	r3d_target_clear! = |machine, st, bg| (if (r3d_base_ok(st.r3t_base) == False) { (machine, r3d_refused) } else { (if (r3d_base_ok(st.r3t_depth) == False) { (machine, r3d_refused) } else { ({
		(machine1, _c1) = r3d_fill_rows!(machine, st.r3t_base, st.r3t_stride, st.r3t_w, st.r3t_h, bg, 0)
		r3d_fill_32!(machine1, st.r3t_depth, r3d_far_depth, 0, (st.r3t_w * st.r3t_h))
	}) }) })

	r3d_plot! : Machine.Machine, Renderer3D.R3dTriState, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_plot! = |machine, st, x, y, depth, color| ({
		(machine10, machine__10) = (if (x < 0) { (machine, 0) } else { ({
		(machine9, machine__9) = (if (y < 0) { (machine, 0) } else { ({
		(machine8, machine__8) = (if (x >= st.r3t_w) { (machine, 0) } else { ({
		(machine7, machine__7) = (if (y >= st.r3t_h) { (machine, 0) } else { ({
		(machine6, machine__6) = ({
		di = (((y * st.r3t_w) + x) * 4)
		({
			(machine1, machine__3) = Machine.load!(machine, st.r3t_depth, di, 4)
			(machine5, machine__5) = (if (depth >= machine__3) { (machine1, 0) } else { ({
			(machine4, machine__4) = ({
			(machine2, _d1) = Machine.store!(machine1, st.r3t_depth, di, depth, 4)
			(machine3, _d2) = Machine.store!(machine2, st.r3t_base, (((y * st.r3t_stride) + x) * 4), color, 4)
			(machine3, 1)
		})
			(machine4, machine__4)
		}) })
			(machine5, machine__5)
		})
	})
		(machine6, machine__6)
	}) })
		(machine7, machine__7)
	}) })
		(machine8, machine__8)
	}) })
		(machine9, machine__9)
	}) })
		(machine10, machine__10)
	})

	r3d_clip_vertex : Mesh.Vertex, Matrix4.Mat4, Matrix4.Mat4 -> Renderer3D.ClipVert
	r3d_clip_vertex = |v, mvp, model| ({
		clip = Matrix4.mat4_transform_vec4(mvp, { v4x: I64.to_f64(v.vp_x), v4y: I64.to_f64(v.vp_y), v4z: I64.to_f64(v.vp_z), v4w: 1.0 })
		world = Matrix4.mat4_transform_point(model, Quaternion.vec3_new(I64.to_f64(v.vp_x), I64.to_f64(v.vp_y), I64.to_f64(v.vp_z)))
		{ cv_cx: clip.v4x, cv_cy: clip.v4y, cv_cz: clip.v4z, cv_cw: clip.v4w, cv_nx: v.vn_x, cv_ny: v.vn_y, cv_nz: v.vn_z, cv_wu: v.vu, cv_wv: v.vv, cv_wx: world.vx, cv_wy: world.vy, cv_wz: world.vz }
	})

	r3d_near_eps : F64
	r3d_near_eps = F64.from_bits(4517329193108106637)

	r3d_near_dist : Renderer3D.ClipVert -> F64
	r3d_near_dist = |v| (v.cv_cz + v.cv_cw)

	r3d_lerp_real : F64, F64, F64 -> F64
	r3d_lerp_real = |a, b, t| (a + ((b - a) * t))

	r3d_lerp_int : I64, I64, F64 -> I64
	r3d_lerp_int = |a, b, t| (a + F64.to_i64_wrap((I64.to_f64((b - a)) * t)))

	r3d_clip_lerp : Renderer3D.ClipVert, Renderer3D.ClipVert, F64 -> Renderer3D.ClipVert
	r3d_clip_lerp = |a, b, t| { cv_cx: r3d_lerp_real(a.cv_cx, b.cv_cx, t), cv_cy: r3d_lerp_real(a.cv_cy, b.cv_cy, t), cv_cz: r3d_lerp_real(a.cv_cz, b.cv_cz, t), cv_cw: r3d_lerp_real(a.cv_cw, b.cv_cw, t), cv_nx: r3d_lerp_int(a.cv_nx, b.cv_nx, t), cv_ny: r3d_lerp_int(a.cv_ny, b.cv_ny, t), cv_nz: r3d_lerp_int(a.cv_nz, b.cv_nz, t), cv_wu: r3d_lerp_int(a.cv_wu, b.cv_wu, t), cv_wv: r3d_lerp_int(a.cv_wv, b.cv_wv, t), cv_wx: r3d_lerp_real(a.cv_wx, b.cv_wx, t), cv_wy: r3d_lerp_real(a.cv_wy, b.cv_wy, t), cv_wz: r3d_lerp_real(a.cv_wz, b.cv_wz, t) }

	r3d_clip_edge : Renderer3D.ClipVert, Renderer3D.ClipVert, List(Renderer3D.ClipVert) -> List(Renderer3D.ClipVert)
	r3d_clip_edge = |cur, nxt, acc| ({
		dc = r3d_near_dist(cur)
		dn = r3d_near_dist(nxt)
		(if (dc >= r3d_near_eps) { (if (dn >= r3d_near_eps) { List.append(acc, nxt) } else { List.append(acc, r3d_clip_lerp(cur, nxt, (dc / (dc - dn)))) }) } else { (if (dn >= r3d_near_eps) { List.append(List.append(acc, r3d_clip_lerp(cur, nxt, (dc / (dc - dn)))), nxt) } else { acc }) })
	})

	r3d_clip_tri : Renderer3D.ClipVert, Renderer3D.ClipVert, Renderer3D.ClipVert -> List(Renderer3D.ClipVert)
	r3d_clip_tri = |a, b, c| r3d_clip_edge(b, c, r3d_clip_edge(a, b, r3d_clip_edge(c, a, [])))

	r3d_project_clip : Renderer3D.ClipVert, I64, I64 -> Renderer3D.ProjVert
	r3d_project_clip = |v, half_w, half_h| ({
		w = v.cv_cw
		(if (w <= 0.0) { { pv_sx: (-9999), pv_sy: (-9999), pv_depth: 999999999, pv_nx: v.cv_nx, pv_ny: v.cv_ny, pv_nz: v.cv_nz, pv_wu: v.cv_wu, pv_wv: v.cv_wv, pv_wx: v.cv_wx, pv_wy: v.cv_wy, pv_wz: v.cv_wz, pv_lx: 0, pv_ly: 0, pv_ld: 0 } } else { ({
			ndc_x = (v.cv_cx / w)
			ndc_y = (v.cv_cy / w)
			ndc_z = (v.cv_cz / w)
			fhw = I64.to_f64(half_w)
			fhh = I64.to_f64(half_h)
			sx = F64.to_i64_wrap((fhw + (ndc_x * fhw)))
			sy = F64.to_i64_wrap((fhh - (ndc_y * fhh)))
			depth = F64.to_i64_wrap(((ndc_z + 1.0) * 500000.0))
			{ pv_sx: sx, pv_sy: sy, pv_depth: depth, pv_nx: v.cv_nx, pv_ny: v.cv_ny, pv_nz: v.cv_nz, pv_wu: v.cv_wu, pv_wv: v.cv_wv, pv_wx: v.cv_wx, pv_wy: v.cv_wy, pv_wz: v.cv_wz, pv_lx: 0, pv_ly: 0, pv_ld: 0 }
		}) })
	})

	r3d_raster_fan! : Machine.Machine, Renderer3D.R3dTriState, List(Renderer3D.ClipVert), I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_raster_fan! = |machine, st, poly, i, color, half_w, half_h| (if ((i + 1) >= U64.to_i64_wrap(List.len(poly))) { (machine, 0) } else { ({
		p0 = r3d_project_clip((List.get(poly, I64.to_u64_wrap(0)) ?? crash("list-at out of range")), half_w, half_h)
		pa = r3d_project_clip((List.get(poly, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), half_w, half_h)
		pb = r3d_project_clip((List.get(poly, I64.to_u64_wrap((i + 1))) ?? crash("list-at out of range")), half_w, half_h)
		(machine1, _hit) = (if Culling.cull_backface(p0.pv_sx, p0.pv_sy, pa.pv_sx, pa.pv_sy, pb.pv_sx, pb.pv_sy) { (machine, 0) } else { r3d_rasterize_tri!(machine, st, p0, pa, pb, color) })
		r3d_raster_fan!(machine1, st, poly, (i + 1), color, half_w, half_h)
	}) })

	r3d_rasterize_tri! : Machine.Machine, Renderer3D.R3dTriState, Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.ProjVert, I64 => (Machine.Machine, I64)
	r3d_rasterize_tri! = |machine, st, a, b, c, color| ({
		min_y = r3d_max(0, r3d_min3(a.pv_sy, b.pv_sy, c.pv_sy))
		max_y = r3d_min((st.r3t_h - 1), r3d_max3(a.pv_sy, b.pv_sy, c.pv_sy))
		min_x = r3d_max(0, r3d_min3(a.pv_sx, b.pv_sx, c.pv_sx))
		max_x = r3d_min((st.r3t_w - 1), r3d_max3(a.pv_sx, b.pv_sx, c.pv_sx))
		r3d_scan_rows!(machine, st, a, b, c, color, min_y, max_y, min_x, max_x)
	})

	r3d_scan_rows! : Machine.Machine, Renderer3D.R3dTriState, Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.ProjVert, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_scan_rows! = |machine, st, a, b, c, color, y, max_y, min_x, max_x| (if (y > max_y) { (machine, 0) } else { ({
		(machine1, _n) = r3d_scan_cols!(machine, st, a, b, c, color, y, min_x, max_x)
		r3d_scan_rows!(machine1, st, a, b, c, color, (y + 1), max_y, min_x, max_x)
	}) })

	r3d_scan_cols! : Machine.Machine, Renderer3D.R3dTriState, Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.ProjVert, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_scan_cols! = |machine, st, a, b, c, color, y, x, max_x| (if (x > max_x) { (machine, 0) } else { ({
		v0x = (c.pv_sx - a.pv_sx)
		v0y = (c.pv_sy - a.pv_sy)
		v1x = (b.pv_sx - a.pv_sx)
		v1y = (b.pv_sy - a.pv_sy)
		v2x = (x - a.pv_sx)
		v2y = (y - a.pv_sy)
		d00 = ((v0x * v0x) + (v0y * v0y))
		d01 = ((v0x * v1x) + (v0y * v1y))
		d02 = ((v0x * v2x) + (v0y * v2y))
		d11 = ((v1x * v1x) + (v1y * v1y))
		d12 = ((v1x * v2x) + (v1y * v2y))
		denom = ((d00 * d11) - (d01 * d01))
		u = (if (denom == 0) { (0 - 1) } else { I64.div_trunc_by((((d11 * d02) - (d01 * d12)) * 1000), denom) })
		v = (if (denom == 0) { (0 - 1) } else { I64.div_trunc_by((((d00 * d12) - (d01 * d02)) * 1000), denom) })
		w = (if (denom == 0) { (0 - 1) } else { ((1000 - u) - v) })
		(machine1, _hit) = r3d_cover!(machine, st, a, b, c, w, v, u, x, y, color)
		r3d_scan_cols!(machine1, st, a, b, c, color, y, (x + 1), max_x)
	}) })

	r3d_cover! : Machine.Machine, Renderer3D.R3dTriState, Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.ProjVert, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_cover! = |machine, st, a, b, c, w0, w1, w2, x, y, color| (if (w0 < 0) { (machine, 0) } else { (if (w1 < 0) { (machine, 0) } else { (if (w2 < 0) { (machine, 0) } else { ({
		depth = r3d_interp_depth(a, b, c, w0, w1, w2, 1000)
		r3d_plot!(machine, st, x, y, depth, color)
	}) }) }) })

	r3d_barycentric : Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.ProjVert, I64, I64 -> Renderer3D.R3dBary
	r3d_barycentric = |a, b, c, px, py| ({
		v0x = (c.pv_sx - a.pv_sx)
		v0y = (c.pv_sy - a.pv_sy)
		v1x = (b.pv_sx - a.pv_sx)
		v1y = (b.pv_sy - a.pv_sy)
		v2x = (px - a.pv_sx)
		v2y = (py - a.pv_sy)
		d00 = ((v0x * v0x) + (v0y * v0y))
		d01 = ((v0x * v1x) + (v0y * v1y))
		d02 = ((v0x * v2x) + (v0y * v2y))
		d11 = ((v1x * v1x) + (v1y * v1y))
		d12 = ((v1x * v2x) + (v1y * v2y))
		denom = ((d00 * d11) - (d01 * d01))
		(if (denom == 0) { { bw0: (-1), bw1: (-1), bw2: (-1), bw_sum: 1 } } else { ({
			u = I64.div_trunc_by((((d11 * d02) - (d01 * d12)) * 1000), denom)
			v = I64.div_trunc_by((((d00 * d12) - (d01 * d02)) * 1000), denom)
			w = ((1000 - u) - v)
			{ bw0: w, bw1: v, bw2: u, bw_sum: 1000 }
		}) })
	})

	r3d_interp_depth : Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.ProjVert, I64, I64, I64, I64 -> I64
	r3d_interp_depth = |a, b, c, w0, w1, w2, wsum| (if (wsum == 0) { 999999999 } else { I64.div_trunc_by((((a.pv_depth * w0) + (b.pv_depth * w1)) + (c.pv_depth * w2)), wsum) })

	r3d_shade_phong : Quaternion.Vec3, Quaternion.Vec3, Quaternion.Vec3, Material.EngineMaterial, List(Scene3D.Light3D), I64, I64, I64 -> Color.Rgb
	r3d_shade_phong = |world_pos, normal, eye_pos, mat, lights, light_idx, light_count, ambient| ({
		base = Color.rgb_scale(mat.emat_albedo, ambient)
		r3d_accum_lights(world_pos, normal, eye_pos, mat, lights, light_idx, light_count, base)
	})

	r3d_accum_lights : Quaternion.Vec3, Quaternion.Vec3, Quaternion.Vec3, Material.EngineMaterial, List(Scene3D.Light3D), I64, I64, Color.Rgb -> Color.Rgb
	r3d_accum_lights = |world_pos, normal, eye_pos, mat, lights, i, n, acc| (if (i >= n) { acc } else { ({
		light = (List.get(lights, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		contrib = r3d_light_contrib(world_pos, normal, eye_pos, mat, light)
		r3d_accum_lights(world_pos, normal, eye_pos, mat, lights, (i + 1), n, Color.rgb_add(acc, contrib))
	}) })

	r3d_light_contrib : Quaternion.Vec3, Quaternion.Vec3, Quaternion.Vec3, Material.EngineMaterial, Scene3D.Light3D -> Color.Rgb
	r3d_light_contrib = |world_pos, normal, eye_pos, mat, light| (match light {
		DirLight(dir, col, intensity) => ({
			to_light = Matrix4.mat4_v3_normalize(dir)
			n_dot_l = r3d_unit_to_milli(Quaternion.vec3_dot(normal, to_light))
			diffuse = (if (n_dot_l > 0) { I64.div_trunc_by((n_dot_l * mat.emat_diffuse), 1000) } else { 0 })
			reflect = r3d_reflect(r3d_negate_vec(to_light), normal)
			to_eye = Matrix4.mat4_v3_normalize(Quaternion.vec3_subtract(eye_pos, world_pos))
			r_dot_v = r3d_unit_to_milli(Quaternion.vec3_dot(reflect, to_eye))
			spec_raw = (if (r_dot_v > 0) { r_dot_v } else { 0 })
			specular = I64.div_trunc_by((r3d_pow_int(spec_raw, mat.emat_shininess) * mat.emat_specular), 1000)
			total = I64.div_trunc_by(((diffuse + specular) * intensity), 1000)
			Color.rgb_scale(Color.rgb_multiply(mat.emat_albedo, col), r3d_clamp(total, 0, 1000))
		})
		PtLight(pos, col, intensity, radius) => ({
			delta = Quaternion.vec3_subtract(pos, world_pos)
			dist = r3d_vec_len(delta)
			(if (dist > radius) { Color.rgb(0, 0, 0) } else { ({
				to_light = Matrix4.mat4_v3_normalize(delta)
				atten = (1000 - I64.div_trunc_by((dist * 1000), radius))
				n_dot_l = r3d_unit_to_milli(Quaternion.vec3_dot(normal, to_light))
				diffuse = (if (n_dot_l > 0) { I64.div_trunc_by(((n_dot_l * mat.emat_diffuse) * atten), 1000000) } else { 0 })
				total = I64.div_trunc_by((diffuse * intensity), 1000)
				Color.rgb_scale(Color.rgb_multiply(mat.emat_albedo, col), r3d_clamp(total, 0, 1000))
			}) })
		})
		SpotLight3D(pos, dir, col, intensity, angle, falloff) => ({
			to_light = Matrix4.mat4_v3_normalize(Quaternion.vec3_subtract(pos, world_pos))
			axis = Matrix4.mat4_v3_normalize(dir)
			cos_frag = r3d_unit_to_milli(Quaternion.vec3_dot(r3d_negate_vec(to_light), axis))
			cone = r3d_spot_cone(cos_frag, angle, falloff)
			(if (cone == 0) { Color.rgb(0, 0, 0) } else { ({
				n_dot_l = r3d_unit_to_milli(Quaternion.vec3_dot(normal, to_light))
				diffuse = (if (n_dot_l > 0) { I64.div_trunc_by((n_dot_l * mat.emat_diffuse), 1000) } else { 0 })
				reflect = r3d_reflect(r3d_negate_vec(to_light), normal)
				to_eye = Matrix4.mat4_v3_normalize(Quaternion.vec3_subtract(eye_pos, world_pos))
				r_dot_v = r3d_unit_to_milli(Quaternion.vec3_dot(reflect, to_eye))
				spec_raw = (if (r_dot_v > 0) { r_dot_v } else { 0 })
				specular = I64.div_trunc_by((r3d_pow_int(spec_raw, mat.emat_shininess) * mat.emat_specular), 1000)
				total = I64.div_trunc_by((I64.div_trunc_by(((diffuse + specular) * intensity), 1000) * cone), 1000)
				Color.rgb_scale(Color.rgb_multiply(mat.emat_albedo, col), r3d_clamp(total, 0, 1000))
			}) })
		})
	})

	r3d_spot_cone : I64, I64, I64 -> I64
	r3d_spot_cone = |cos_frag, angle, falloff| (if (cos_frag >= angle) { 1000 } else { (if (falloff <= 0) { 0 } else { (if (cos_frag > (angle - falloff)) { I64.div_trunc_by(((cos_frag - (angle - falloff)) * 1000), falloff) } else { 0 }) }) })

	r3d_pre_light : Quaternion.Vec3, Quaternion.Vec3, Scene3D.Light3D -> Renderer3D.R3dLightPre
	r3d_pre_light = |center, _eye, light| (match light {
		DirLight(dir, col, intensity) => ({
			l = Matrix4.mat4_v3_normalize(dir)
			{ lp_lx: r3d_unit_to_milli(l.vx), lp_ly: r3d_unit_to_milli(l.vy), lp_lz: r3d_unit_to_milli(l.vz), lp_scale: intensity, lp_cr: col.cr, lp_cg: col.cg, lp_cb: col.cb }
		})
		PtLight(pos, col, intensity, radius) => ({
			delta = Quaternion.vec3_subtract(pos, center)
			dist = r3d_vec_len(delta)
			l = Matrix4.mat4_v3_normalize(delta)
			atten = (if (dist > radius) { 0 } else { (1000 - I64.div_trunc_by((dist * 1000), radius)) })
			{ lp_lx: r3d_unit_to_milli(l.vx), lp_ly: r3d_unit_to_milli(l.vy), lp_lz: r3d_unit_to_milli(l.vz), lp_scale: I64.div_trunc_by((intensity * atten), 1000), lp_cr: col.cr, lp_cg: col.cg, lp_cb: col.cb }
		})
		SpotLight3D(pos, dir, col, intensity, angle, falloff) => ({
			l = Matrix4.mat4_v3_normalize(Quaternion.vec3_subtract(pos, center))
			axis = Matrix4.mat4_v3_normalize(dir)
			cos_frag = r3d_unit_to_milli(Quaternion.vec3_dot(r3d_negate_vec(l), axis))
			cone = r3d_spot_cone(cos_frag, angle, falloff)
			{ lp_lx: r3d_unit_to_milli(l.vx), lp_ly: r3d_unit_to_milli(l.vy), lp_lz: r3d_unit_to_milli(l.vz), lp_scale: I64.div_trunc_by((intensity * cone), 1000), lp_cr: col.cr, lp_cg: col.cg, lp_cb: col.cb }
		})
	})

	r3d_pre_lights : Quaternion.Vec3, Quaternion.Vec3, List(Scene3D.Light3D), I64, I64, List(Renderer3D.R3dLightPre) -> List(Renderer3D.R3dLightPre)
	r3d_pre_lights = |center, eye, lights, i, n, acc| (if (i >= n) { acc } else { r3d_pre_lights(center, eye, lights, (i + 1), n, List.append(acc, r3d_pre_light(center, eye, (List.get(lights, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	r3d_shade_ctx_phong : Renderer3D.ClipVert, Renderer3D.ClipVert, Renderer3D.ClipVert, Material.EngineMaterial, List(Scene3D.Light3D), Quaternion.Vec3, I64 -> Renderer3D.R3dShadeCtx
	r3d_shade_ctx_phong = |c0, c1, c2, mat, lights, eye, ambient| ({
		center = Quaternion.vec3_new((((c0.cv_wx + c1.cv_wx) + c2.cv_wx) / 3.0), (((c0.cv_wy + c1.cv_wy) + c2.cv_wy) / 3.0), (((c0.cv_wz + c1.cv_wz) + c2.cv_wz) / 3.0))
		to_eye = Matrix4.mat4_v3_normalize(Quaternion.vec3_subtract(eye, center))
		base = Color.rgb_to_packed(Color.rgb_scale(mat.emat_albedo, ambient))
		{ sc_mode: 2, sc_g0: 0, sc_g1: 0, sc_g2: 0, sc_base: base, sc_ar: mat.emat_albedo.cr, sc_ag: mat.emat_albedo.cg, sc_ab: mat.emat_albedo.cb, sc_diffuse: mat.emat_diffuse, sc_specular: mat.emat_specular, sc_shininess: mat.emat_shininess, sc_ex: r3d_unit_to_milli(to_eye.vx), sc_ey: r3d_unit_to_milli(to_eye.vy), sc_ez: r3d_unit_to_milli(to_eye.vz), sc_lights: r3d_pre_lights(center, eye, lights, 0, U64.to_i64_wrap(List.len(lights)), []), sc_amb: base, sc_sh_base: 0, sc_sh_size: 0, sc_sh_bias: 0, sc_tex: mat.emat_texture }
	})

	r3d_shade_ctx_gouraud : I64, I64, I64 -> Renderer3D.R3dShadeCtx
	r3d_shade_ctx_gouraud = |g0, g1, g2| { sc_mode: 1, sc_g0: g0, sc_g1: g1, sc_g2: g2, sc_base: 0, sc_ar: 0, sc_ag: 0, sc_ab: 0, sc_diffuse: 0, sc_specular: 0, sc_shininess: 0, sc_ex: 0, sc_ey: 0, sc_ez: 0, sc_lights: [], sc_amb: 0, sc_sh_base: 0, sc_sh_size: 0, sc_sh_bias: 0, sc_tex: None }

	r3d_chan : I64, I64 -> I64
	r3d_chan = |packed, shift| I64.bitwise_and(I64.shr_zf_wrap(packed, I64.to_u8_wrap(shift)), 255)

	r3d_gouraud_px : I64, I64, I64, I64, I64, I64 -> I64
	r3d_gouraud_px = |g0, g1, g2, w0, w1, w2| ({
		r = I64.div_trunc_by((((r3d_chan(g0, 16) * w0) + (r3d_chan(g1, 16) * w1)) + (r3d_chan(g2, 16) * w2)), 1000)
		g = I64.div_trunc_by((((r3d_chan(g0, 8) * w0) + (r3d_chan(g1, 8) * w1)) + (r3d_chan(g2, 8) * w2)), 1000)
		b = I64.div_trunc_by((((r3d_chan(g0, 0) * w0) + (r3d_chan(g1, 0) * w1)) + (r3d_chan(g2, 0) * w2)), 1000)
		I64.bitwise_or(I64.shl_wrap(r3d_clamp(r, 0, 255), I64.to_u8_wrap(16)), I64.bitwise_or(I64.shl_wrap(r3d_clamp(g, 0, 255), I64.to_u8_wrap(8)), r3d_clamp(b, 0, 255)))
	})

	r3d_phong_px : Renderer3D.R3dShadeCtx, I64, I64, I64 -> I64
	r3d_phong_px = |ctx, nx, ny, nz| r3d_phong_accum(ctx, nx, ny, nz, 0, U64.to_i64_wrap(List.len(ctx.sc_lights)), r3d_chan(ctx.sc_base, 16), r3d_chan(ctx.sc_base, 8), r3d_chan(ctx.sc_base, 0))

	r3d_phong_accum : Renderer3D.R3dShadeCtx, I64, I64, I64, I64, I64, I64, I64, I64 -> I64
	r3d_phong_accum = |ctx, nx, ny, nz, i, n, ar, ag, ab| (if (i >= n) { I64.bitwise_or(I64.shl_wrap(r3d_clamp(ar, 0, 255), I64.to_u8_wrap(16)), I64.bitwise_or(I64.shl_wrap(r3d_clamp(ag, 0, 255), I64.to_u8_wrap(8)), r3d_clamp(ab, 0, 255))) } else { ({
		lp = (List.get(ctx.sc_lights, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		ndl = I64.div_trunc_by((((nx * lp.lp_lx) + (ny * lp.lp_ly)) + (nz * lp.lp_lz)), 1000)
		diffuse = (if (ndl > 0) { I64.div_trunc_by((ndl * ctx.sc_diffuse), 1000) } else { 0 })
		rx = (I64.div_trunc_by(((2 * ndl) * nx), 1000) - lp.lp_lx)
		ry = (I64.div_trunc_by(((2 * ndl) * ny), 1000) - lp.lp_ly)
		rz = (I64.div_trunc_by(((2 * ndl) * nz), 1000) - lp.lp_lz)
		rdv = I64.div_trunc_by((((rx * ctx.sc_ex) + (ry * ctx.sc_ey)) + (rz * ctx.sc_ez)), 1000)
		specular = (if (rdv > 0) { I64.div_trunc_by((r3d_pow_int(rdv, ctx.sc_shininess) * ctx.sc_specular), 1000) } else { 0 })
		total = r3d_clamp(I64.div_trunc_by(((diffuse + specular) * lp.lp_scale), 1000), 0, 1000)
		r3d_phong_accum(ctx, nx, ny, nz, (i + 1), n, (ar + I64.div_trunc_by((I64.div_trunc_by((ctx.sc_ar * lp.lp_cr), 255) * total), 1000)), (ag + I64.div_trunc_by((I64.div_trunc_by((ctx.sc_ag * lp.lp_cg), 255) * total), 1000)), (ab + I64.div_trunc_by((I64.div_trunc_by((ctx.sc_ab * lp.lp_cb), 255) * total), 1000)))
	}) })

	r3d_rasterize_tri_sh! : Machine.Machine, Renderer3D.R3dTriState, Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.R3dShadeCtx => (Machine.Machine, I64)
	r3d_rasterize_tri_sh! = |machine, st, a, b, c, ctx| ({
		min_y = r3d_max(0, r3d_min3(a.pv_sy, b.pv_sy, c.pv_sy))
		max_y = r3d_min((st.r3t_h - 1), r3d_max3(a.pv_sy, b.pv_sy, c.pv_sy))
		min_x = r3d_max(0, r3d_min3(a.pv_sx, b.pv_sx, c.pv_sx))
		max_x = r3d_min((st.r3t_w - 1), r3d_max3(a.pv_sx, b.pv_sx, c.pv_sx))
		r3d_scan_rows_sh!(machine, st, a, b, c, ctx, r3d_slope_bias(a, b, c, ctx), min_y, max_y, min_x, max_x)
	})

	r3d_slope_bias : Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.R3dShadeCtx -> I64
	r3d_slope_bias = |a, b, c, ctx| ({
		dlo = r3d_min(r3d_min(a.pv_ld, b.pv_ld), c.pv_ld)
		dhi = r3d_max(r3d_max(a.pv_ld, b.pv_ld), c.pv_ld)
		xlo = r3d_min(r3d_min(a.pv_lx, b.pv_lx), c.pv_lx)
		xhi = r3d_max(r3d_max(a.pv_lx, b.pv_lx), c.pv_lx)
		ylo = r3d_min(r3d_min(a.pv_ly, b.pv_ly), c.pv_ly)
		yhi = r3d_max(r3d_max(a.pv_ly, b.pv_ly), c.pv_ly)
		span = r3d_max(I64.div_trunc_by((xhi - xlo), 1000), I64.div_trunc_by((yhi - ylo), 1000))
		slope = I64.div_trunc_by((dhi - dlo), r3d_max(span, 1))
		(ctx.sc_sh_bias + (slope * r3d_shadow_slope))
	})

	r3d_scan_rows_sh! : Machine.Machine, Renderer3D.R3dTriState, Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.R3dShadeCtx, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_scan_rows_sh! = |machine, st, a, b, c, ctx, bias, y, max_y, min_x, max_x| (if (y > max_y) { (machine, 0) } else { ({
		(machine1, _n) = r3d_scan_cols_sh!(machine, st, a, b, c, ctx, bias, y, min_x, max_x)
		r3d_scan_rows_sh!(machine1, st, a, b, c, ctx, bias, (y + 1), max_y, min_x, max_x)
	}) })

	r3d_scan_cols_sh! : Machine.Machine, Renderer3D.R3dTriState, Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.R3dShadeCtx, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_scan_cols_sh! = |machine, st, a, b, c, ctx, bias, y, x, max_x| (if (x > max_x) { (machine, 0) } else { ({
		v0x = (c.pv_sx - a.pv_sx)
		v0y = (c.pv_sy - a.pv_sy)
		v1x = (b.pv_sx - a.pv_sx)
		v1y = (b.pv_sy - a.pv_sy)
		v2x = (x - a.pv_sx)
		v2y = (y - a.pv_sy)
		d00 = ((v0x * v0x) + (v0y * v0y))
		d01 = ((v0x * v1x) + (v0y * v1y))
		d02 = ((v0x * v2x) + (v0y * v2y))
		d11 = ((v1x * v1x) + (v1y * v1y))
		d12 = ((v1x * v2x) + (v1y * v2y))
		denom = ((d00 * d11) - (d01 * d01))
		u = (if (denom == 0) { (0 - 1) } else { I64.div_trunc_by((((d11 * d02) - (d01 * d12)) * 1000), denom) })
		v = (if (denom == 0) { (0 - 1) } else { I64.div_trunc_by((((d00 * d12) - (d01 * d02)) * 1000), denom) })
		w = (if (denom == 0) { (0 - 1) } else { ((1000 - u) - v) })
		(machine1, _hit) = r3d_cover_sh!(machine, st, a, b, c, w, v, u, x, y, ctx, bias)
		r3d_scan_cols_sh!(machine1, st, a, b, c, ctx, bias, y, (x + 1), max_x)
	}) })

	r3d_cover_sh! : Machine.Machine, Renderer3D.R3dTriState, Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.ProjVert, I64, I64, I64, I64, I64, Renderer3D.R3dShadeCtx, I64 => (Machine.Machine, I64)
	r3d_cover_sh! = |machine, st, a, b, c, w0, w1, w2, x, y, ctx, bias| (if (w0 < 0) { (machine, 0) } else { (if (w1 < 0) { (machine, 0) } else { (if (w2 < 0) { (machine, 0) } else { ({
		depth = r3d_interp_depth(a, b, c, w0, w1, w2, 1000)
		(machine1, lit) = (if (ctx.sc_sh_base == 0) { (machine, r3d_pcf_taps) } else { r3d_shadow_lit!(machine, ctx, a, b, c, w0, w1, w2, bias) })
		color = (if (lit == 0) { ctx.sc_amb } else { (if (lit >= r3d_pcf_taps) { r3d_shade_px(ctx, a, b, c, w0, w1, w2) } else { r3d_blend_sh(r3d_shade_px(ctx, a, b, c, w0, w1, w2), ctx.sc_amb, lit) }) })
		final = (match ctx.sc_tex {
			None => color
			Just(tex) => r3d_tex_px(tex, a, b, c, w0, w1, w2, color)
		})
		r3d_plot!(machine1, st, x, y, depth, final)
	}) }) }) })

	r3d_tex_px : Texture.EngineTexture, Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.ProjVert, I64, I64, I64, I64 -> I64
	r3d_tex_px = |tex, a, b, c, w0, w1, w2, color| ({
		u = I64.div_trunc_by((((a.pv_wu * w0) + (b.pv_wu * w1)) + (c.pv_wu * w2)), 1000)
		v = I64.div_trunc_by((((a.pv_wv * w0) + (b.pv_wv * w1)) + (c.pv_wv * w2)), 1000)
		pw = tex.etx_width
		ph = tex.etx_height
		px0 = I64.div_trunc_by((u * pw), 1000)
		py0 = I64.div_trunc_by((v * ph), 1000)
		pxm = (px0 - (I64.div_trunc_by(px0, pw) * pw))
		px = (if (pxm < 0) { (pxm + pw) } else { pxm })
		pym = (py0 - (I64.div_trunc_by(py0, ph) * ph))
		py = (if (pym < 0) { (pym + ph) } else { pym })
		t = Texture.etx_get(tex, px, py)
		r = I64.div_trunc_by((r3d_chan(color, 16) * r3d_chan(t, 16)), 255)
		g = I64.div_trunc_by((r3d_chan(color, 8) * r3d_chan(t, 8)), 255)
		bl = I64.div_trunc_by((r3d_chan(color, 0) * r3d_chan(t, 0)), 255)
		I64.bitwise_or(I64.shl_wrap(r, I64.to_u8_wrap(16)), I64.bitwise_or(I64.shl_wrap(g, I64.to_u8_wrap(8)), bl))
	})

	r3d_ctx_with_tex : Renderer3D.R3dShadeCtx, Material.EngineMaterial -> Renderer3D.R3dShadeCtx
	r3d_ctx_with_tex = |ctx, mat| { ..ctx, sc_tex: mat.emat_texture }

	r3d_shade_px : Renderer3D.R3dShadeCtx, Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.ProjVert, I64, I64, I64 -> I64
	r3d_shade_px = |ctx, a, b, c, w0, w1, w2| (if (ctx.sc_mode == 1) { r3d_gouraud_px(ctx.sc_g0, ctx.sc_g1, ctx.sc_g2, w0, w1, w2) } else { (if (ctx.sc_mode == 3) { ctx.sc_g0 } else { r3d_phong_px(ctx, I64.div_trunc_by((((a.pv_nx * w0) + (b.pv_nx * w1)) + (c.pv_nx * w2)), 1000), I64.div_trunc_by((((a.pv_ny * w0) + (b.pv_ny * w1)) + (c.pv_ny * w2)), 1000), I64.div_trunc_by((((a.pv_nz * w0) + (b.pv_nz * w1)) + (c.pv_nz * w2)), 1000)) }) })

	r3d_sh_tap! : Machine.Machine, Renderer3D.R3dShadeCtx, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_sh_tap! = |machine, ctx, ld, sx, sy, bias| ({
		(machine6, machine__15) = (if (sx < 0) { (machine, 1) } else { ({
		(machine5, machine__14) = (if (sy < 0) { (machine, 1) } else { ({
		(machine4, machine__13) = (if (sx >= ctx.sc_sh_size) { (machine, 1) } else { ({
		(machine3, machine__12) = (if (sy >= ctx.sc_sh_size) { (machine, 1) } else { ({
		(machine2, machine__11) = ({
		(machine1, md) = Machine.load!(machine, ctx.sc_sh_base, (((sy * ctx.sc_sh_size) + sx) * 4), 4)
		(machine1, (if (ld <= (md + bias)) { 1 } else { 0 }))
	})
		(machine2, machine__11)
	}) })
		(machine3, machine__12)
	}) })
		(machine4, machine__13)
	}) })
		(machine5, machine__14)
	}) })
		(machine6, machine__15)
	})

	r3d_sh_taps! : Machine.Machine, Renderer3D.R3dShadeCtx, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_sh_taps! = |machine, ctx, ld, tx, ty, bias, oy, ox, acc| (if (oy > r3d_pcf_radius) { (machine, acc) } else { (if (ox > r3d_pcf_radius) { r3d_sh_taps!(machine, ctx, ld, tx, ty, bias, (oy + 1), (0 - r3d_pcf_radius), acc) } else { ({
		(machine1, h) = r3d_sh_tap!(machine, ctx, ld, (tx + ox), (ty + oy), bias)
		r3d_sh_taps!(machine1, ctx, ld, tx, ty, bias, oy, (ox + 1), (acc + h))
	}) }) })

	r3d_shadow_lit! : Machine.Machine, Renderer3D.R3dShadeCtx, Renderer3D.ProjVert, Renderer3D.ProjVert, Renderer3D.ProjVert, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_shadow_lit! = |machine, ctx, a, b, c, w0, w1, w2, bias| ({
		tx = I64.div_trunc_by((((a.pv_lx * w0) + (b.pv_lx * w1)) + (c.pv_lx * w2)), 1000000)
		ty = I64.div_trunc_by((((a.pv_ly * w0) + (b.pv_ly * w1)) + (c.pv_ly * w2)), 1000000)
		(if (tx < 0) { (machine, r3d_pcf_taps) } else { (if (ty < 0) { (machine, r3d_pcf_taps) } else { (if (tx >= ctx.sc_sh_size) { (machine, r3d_pcf_taps) } else { (if (ty >= ctx.sc_sh_size) { (machine, r3d_pcf_taps) } else { ({
			ld = I64.div_trunc_by((((a.pv_ld * w0) + (b.pv_ld * w1)) + (c.pv_ld * w2)), 1000)
			r3d_sh_taps!(machine, ctx, ld, tx, ty, bias, (0 - r3d_pcf_radius), (0 - r3d_pcf_radius), 0)
		}) }) }) }) })
	})

	r3d_blend_sh : I64, I64, I64 -> I64
	r3d_blend_sh = |lit_color, sh_color, lit| ({
		r = (r3d_chan(sh_color, 16) + I64.div_trunc_by(((r3d_chan(lit_color, 16) - r3d_chan(sh_color, 16)) * lit), r3d_pcf_taps))
		g = (r3d_chan(sh_color, 8) + I64.div_trunc_by(((r3d_chan(lit_color, 8) - r3d_chan(sh_color, 8)) * lit), r3d_pcf_taps))
		bl = (r3d_chan(sh_color, 0) + I64.div_trunc_by(((r3d_chan(lit_color, 0) - r3d_chan(sh_color, 0)) * lit), r3d_pcf_taps))
		I64.bitwise_or(I64.shl_wrap(r, I64.to_u8_wrap(16)), I64.bitwise_or(I64.shl_wrap(g, I64.to_u8_wrap(8)), bl))
	})

	r3d_raster_fan_sh! : Machine.Machine, Renderer3D.R3dTriState, List(Renderer3D.ClipVert), I64, Renderer3D.R3dShadeCtx, I64, I64 => (Machine.Machine, I64)
	r3d_raster_fan_sh! = |machine, st, poly, i, ctx, half_w, half_h| (if ((i + 1) >= U64.to_i64_wrap(List.len(poly))) { (machine, 0) } else { ({
		p0 = r3d_project_clip((List.get(poly, I64.to_u64_wrap(0)) ?? crash("list-at out of range")), half_w, half_h)
		pa = r3d_project_clip((List.get(poly, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), half_w, half_h)
		pb = r3d_project_clip((List.get(poly, I64.to_u64_wrap((i + 1))) ?? crash("list-at out of range")), half_w, half_h)
		(machine1, _hit) = (if Culling.cull_backface(p0.pv_sx, p0.pv_sy, pa.pv_sx, pa.pv_sy, pb.pv_sx, pb.pv_sy) { (machine, 0) } else { r3d_rasterize_tri_sh!(machine, st, p0, pa, pb, ctx) })
		r3d_raster_fan_sh!(machine1, st, poly, (i + 1), ctx, half_w, half_h)
	}) })

	r3d_shade_clip_vert : Renderer3D.ClipVert, Material.EngineMaterial, List(Scene3D.Light3D), Quaternion.Vec3, I64 -> I64
	r3d_shade_clip_vert = |cv, mat, lights, eye, ambient| ({
		normal = Matrix4.mat4_v3_normalize(Quaternion.vec3_new((I64.to_f64(cv.cv_nx) / 1000.0), (I64.to_f64(cv.cv_ny) / 1000.0), (I64.to_f64(cv.cv_nz) / 1000.0)))
		world = Quaternion.vec3_new(cv.cv_wx, cv.cv_wy, cv.cv_wz)
		Color.rgb_to_packed(r3d_shade_phong(world, normal, eye, mat, lights, 0, U64.to_i64_wrap(List.len(lights)), ambient))
	})

	r3d_gouraud_fan! : Machine.Machine, Renderer3D.R3dTriState, List(Renderer3D.ClipVert), I64, Material.EngineMaterial, List(Scene3D.Light3D), Quaternion.Vec3, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_gouraud_fan! = |machine, st, poly, i, mat, lights, eye, ambient, g0, half_w, half_h| (if ((i + 1) >= U64.to_i64_wrap(List.len(poly))) { (machine, 0) } else { ({
		gi = r3d_shade_clip_vert((List.get(poly, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), mat, lights, eye, ambient)
		gj = r3d_shade_clip_vert((List.get(poly, I64.to_u64_wrap((i + 1))) ?? crash("list-at out of range")), mat, lights, eye, ambient)
		ctx = r3d_ctx_with_tex(r3d_shade_ctx_gouraud(g0, gi, gj), mat)
		(machine1, _hit) = r3d_raster_fan_single!(machine, st, poly, i, ctx, half_w, half_h)
		r3d_gouraud_fan!(machine1, st, poly, (i + 1), mat, lights, eye, ambient, g0, half_w, half_h)
	}) })

	r3d_raster_fan_single! : Machine.Machine, Renderer3D.R3dTriState, List(Renderer3D.ClipVert), I64, Renderer3D.R3dShadeCtx, I64, I64 => (Machine.Machine, I64)
	r3d_raster_fan_single! = |machine, st, poly, i, ctx, half_w, half_h| ({
		p0 = r3d_project_clip((List.get(poly, I64.to_u64_wrap(0)) ?? crash("list-at out of range")), half_w, half_h)
		pa = r3d_project_clip((List.get(poly, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), half_w, half_h)
		pb = r3d_project_clip((List.get(poly, I64.to_u64_wrap((i + 1))) ?? crash("list-at out of range")), half_w, half_h)
		(if Culling.cull_backface(p0.pv_sx, p0.pv_sy, pa.pv_sx, pa.pv_sy, pb.pv_sx, pb.pv_sy) { (machine, 0) } else { r3d_rasterize_tri_sh!(machine, st, p0, pa, pb, ctx) })
	})

	r3d_render_tris_gouraud! : Machine.Machine, Renderer3D.R3dTriState, Mesh.Mesh, Matrix4.Mat4, Matrix4.Mat4, Material.EngineMaterial, List(Scene3D.Light3D), Quaternion.Vec3, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_render_tris_gouraud! = |machine, st, mesh, model, mvp, mat, lights, eye, ambient, half_w, half_h, i, n| (if (i >= n) { (machine, 0) } else { ({
		i0 = Mesh.mesh_index_at(mesh, i)
		i1 = Mesh.mesh_index_at(mesh, (i + 1))
		i2 = Mesh.mesh_index_at(mesh, (i + 2))
		c0 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, i0), mvp, model)
		c1 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, i1), mvp, model)
		c2 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, i2), mvp, model)
		poly = r3d_clip_tri(c0, c1, c2)
		(if (U64.to_i64_wrap(List.len(poly)) < 3) { r3d_render_tris_gouraud!(machine, st, mesh, model, mvp, mat, lights, eye, ambient, half_w, half_h, (i + 3), n) } else { ({
			g0 = r3d_shade_clip_vert((List.get(poly, I64.to_u64_wrap(0)) ?? crash("list-at out of range")), mat, lights, eye, ambient)
			(machine1, _hit) = r3d_gouraud_fan!(machine, st, poly, 1, mat, lights, eye, ambient, g0, half_w, half_h)
			r3d_render_tris_gouraud!(machine1, st, mesh, model, mvp, mat, lights, eye, ambient, half_w, half_h, (i + 3), n)
		}) })
	}) })

	r3d_render_tris_phong! : Machine.Machine, Renderer3D.R3dTriState, Mesh.Mesh, Matrix4.Mat4, Matrix4.Mat4, Material.EngineMaterial, List(Scene3D.Light3D), Quaternion.Vec3, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_render_tris_phong! = |machine, st, mesh, model, mvp, mat, lights, eye, ambient, half_w, half_h, i, n| (if (i >= n) { (machine, 0) } else { ({
		i0 = Mesh.mesh_index_at(mesh, i)
		i1 = Mesh.mesh_index_at(mesh, (i + 1))
		i2 = Mesh.mesh_index_at(mesh, (i + 2))
		c0 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, i0), mvp, model)
		c1 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, i1), mvp, model)
		c2 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, i2), mvp, model)
		poly = r3d_clip_tri(c0, c1, c2)
		(if (U64.to_i64_wrap(List.len(poly)) < 3) { r3d_render_tris_phong!(machine, st, mesh, model, mvp, mat, lights, eye, ambient, half_w, half_h, (i + 3), n) } else { ({
			ctx = r3d_shade_ctx_phong(c0, c1, c2, mat, lights, eye, ambient)
			(machine1, _hit) = r3d_raster_fan_sh!(machine, st, poly, 1, ctx, half_w, half_h)
			r3d_render_tris_phong!(machine1, st, mesh, model, mvp, mat, lights, eye, ambient, half_w, half_h, (i + 3), n)
		}) })
	}) })

	r3d_shadow_bias : I64
	r3d_shadow_bias = 500

	r3d_shadow_slope : I64
	r3d_shadow_slope = 6

	r3d_pcf_radius : I64
	r3d_pcf_radius = 1

	r3d_pcf_taps : I64
	r3d_pcf_taps = (((2 * r3d_pcf_radius) + 1) * ((2 * r3d_pcf_radius) + 1))

	r3d_first_dir : List(Scene3D.Light3D), I64, I64 -> Maybe.Maybe(Quaternion.Vec3)
	r3d_first_dir = |lights, i, n| (if (i >= n) { None } else { (match (List.get(lights, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) {
		DirLight(dir, _col, _intensity) => Just(dir)
		_ => r3d_first_dir(lights, (i + 1), n)
	}) })

	r3d_bounds_union : Mesh.MeshBounds, Mesh.MeshBounds -> Mesh.MeshBounds
	r3d_bounds_union = |a, b| { mb_min_x: r3d_min(a.mb_min_x, b.mb_min_x), mb_min_y: r3d_min(a.mb_min_y, b.mb_min_y), mb_min_z: r3d_min(a.mb_min_z, b.mb_min_z), mb_max_x: r3d_max(a.mb_max_x, b.mb_max_x), mb_max_y: r3d_max(a.mb_max_y, b.mb_max_y), mb_max_z: r3d_max(a.mb_max_z, b.mb_max_z) }

	r3d_scene_bounds : Scene3D.Scene3DState, I64, I64, Mesh.MeshBounds, Bool -> Mesh.MeshBounds
	r3d_scene_bounds = |scene, i, n, acc, found| (if (i >= n) { acc } else { ({
		node = (List.get(scene.s3_nodes, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(match node.sn3_mesh {
			None => r3d_scene_bounds(scene, (i + 1), n, acc, found)
			Just(mesh) => ({
				wb = r3d_world_bounds(Mesh.mesh_bounds(mesh), Scene3D.scene3d_world_matrix(scene, i))
				r3d_scene_bounds(scene, (i + 1), n, (if found { r3d_bounds_union(acc, wb) } else { wb }), True)
			})
		})
	}) })

	r3d_light_vp : Scene3D.Scene3DState, Quaternion.Vec3 -> Matrix4.Mat4
	r3d_light_vp = |scene, dir| ({
		b = r3d_scene_bounds(scene, 0, scene.s3_count, { mb_min_x: 0, mb_min_y: 0, mb_min_z: 0, mb_max_x: 0, mb_max_y: 0, mb_max_z: 0 }, False)
		cx = (I64.to_f64((b.mb_min_x + b.mb_max_x)) / 2.0)
		cy = (I64.to_f64((b.mb_min_y + b.mb_max_y)) / 2.0)
		cz = (I64.to_f64((b.mb_min_z + b.mb_max_z)) / 2.0)
		hx = (I64.to_f64((b.mb_max_x - b.mb_min_x)) / 2.0)
		hy = (I64.to_f64((b.mb_max_y - b.mb_min_y)) / 2.0)
		hz = (I64.to_f64((b.mb_max_z - b.mb_min_z)) / 2.0)
		radius = (Matrix4.mat4_sqrt((((hx * hx) + (hy * hy)) + (hz * hz))) + 1.0)
		l = Matrix4.mat4_v3_normalize(dir)
		vertical = (if (l.vx < 0.01) { (if (l.vx > (-0.01)) { (if (l.vz < 0.01) { (if (l.vz > (-0.01)) { True } else { False }) } else { False }) } else { False }) } else { False })
		up = (if vertical { Quaternion.vec3_new(0.0, 0.0, 1.0) } else { Quaternion.vec3_new(0.0, 1.0, 0.0) })
		center = Quaternion.vec3_new(cx, cy, cz)
		eye = Quaternion.vec3_new((cx + ((l.vx * radius) * 2.0)), (cy + ((l.vy * radius) * 2.0)), (cz + ((l.vz * radius) * 2.0)))
		view = Matrix4.mat4_look_at(eye, center, up)
		proj = Matrix4.mat4_ortho((0.0 - radius), radius, (0.0 - radius), radius, (radius * 0.1), (radius * 4.0))
		Matrix4.mat4_mul(proj, view)
	})

	r3d_shadow_pass! : Machine.Machine, Renderer3D.R3dTriState, Scene3D.Scene3DState, Matrix4.Mat4 => (Machine.Machine, I64)
	r3d_shadow_pass! = |machine, st, scene, lvp| r3d_shadow_pass_nodes!(machine, st, scene, lvp, 0, scene.s3_count)

	r3d_shadow_pass_nodes! : Machine.Machine, Renderer3D.R3dTriState, Scene3D.Scene3DState, Matrix4.Mat4, I64, I64 => (Machine.Machine, I64)
	r3d_shadow_pass_nodes! = |machine, st, scene, lvp, i, n| (if (i >= n) { (machine, 0) } else { ({
		node = (List.get(scene.s3_nodes, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(machine1, _d) = (if node.sn3_visible { r3d_shadow_pass_node!(machine, st, scene, lvp, node, i) } else { (machine, 0) })
		r3d_shadow_pass_nodes!(machine1, st, scene, lvp, (i + 1), n)
	}) })

	r3d_shadow_pass_node! : Machine.Machine, Renderer3D.R3dTriState, Scene3D.Scene3DState, Matrix4.Mat4, Scene3D.SceneNode3D, I64 => (Machine.Machine, I64)
	r3d_shadow_pass_node! = |machine, st, scene, lvp, node, idx| (match node.sn3_mesh {
		None => (machine, 0)
		Just(mesh) => ({
			lmvp = Matrix4.mat4_mul(lvp, Scene3D.scene3d_world_matrix(scene, idx))
			r3d_render_tris_caster!(machine, st, mesh, lmvp, node.sn3_material, I64.div_trunc_by(st.r3t_w, 2), I64.div_trunc_by(st.r3t_h, 2), 0, mesh.mesh_index_count)
		})
	})

	r3d_project_clip_sw : Renderer3D.ClipVert, I64, I64, Renderer3D.R3dShadow -> Renderer3D.ProjVert
	r3d_project_clip_sw = |v, half_w, half_h, sh| ({
		p = r3d_project_clip(v, half_w, half_h)
		lc = Matrix4.mat4_transform_vec4(sh.rs_vp, { v4x: v.cv_wx, v4y: v.cv_wy, v4z: v.cv_wz, v4w: 1.0 })
		lw = lc.v4w
		(if (lw <= 0.0) { p } else { ({
			fs = I64.to_f64(sh.rs_size)
			lx = F64.to_i64_wrap((((((lc.v4x / lw) * 0.5) + 0.5) * fs) * 1000.0))
			ly = F64.to_i64_wrap((((0.5 - ((lc.v4y / lw) * 0.5)) * fs) * 1000.0))
			ld = F64.to_i64_wrap((((lc.v4z / lw) + 1.0) * 500000.0))
			{ ..{ ..{ ..p, pv_lx: lx }, pv_ly: ly }, pv_ld: ld }
		}) })
	})

	r3d_ctx_with_shadow : Renderer3D.R3dShadeCtx, Renderer3D.R3dShadow, I64 -> Renderer3D.R3dShadeCtx
	r3d_ctx_with_shadow = |ctx, sh, amb| { ..{ ..{ ..{ ..ctx, sc_amb: amb }, sc_sh_base: sh.rs_base }, sc_sh_size: sh.rs_size }, sc_sh_bias: sh.rs_bias }

	r3d_shade_ctx_flat : I64 -> Renderer3D.R3dShadeCtx
	r3d_shade_ctx_flat = |color| { sc_mode: 3, sc_g0: color, sc_g1: 0, sc_g2: 0, sc_base: 0, sc_ar: 0, sc_ag: 0, sc_ab: 0, sc_diffuse: 0, sc_specular: 0, sc_shininess: 0, sc_ex: 0, sc_ey: 0, sc_ez: 0, sc_lights: [], sc_amb: 0, sc_sh_base: 0, sc_sh_size: 0, sc_sh_bias: 0, sc_tex: None }

	r3d_raster_fan_sw! : Machine.Machine, Renderer3D.R3dTriState, List(Renderer3D.ClipVert), I64, Renderer3D.R3dShadeCtx, I64, I64, Renderer3D.R3dShadow => (Machine.Machine, I64)
	r3d_raster_fan_sw! = |machine, st, poly, i, ctx, half_w, half_h, sh| (if ((i + 1) >= U64.to_i64_wrap(List.len(poly))) { (machine, 0) } else { ({
		(machine1, _hit) = r3d_fan_one_sw!(machine, st, poly, i, ctx, half_w, half_h, sh)
		r3d_raster_fan_sw!(machine1, st, poly, (i + 1), ctx, half_w, half_h, sh)
	}) })

	r3d_fan_one_sw! : Machine.Machine, Renderer3D.R3dTriState, List(Renderer3D.ClipVert), I64, Renderer3D.R3dShadeCtx, I64, I64, Renderer3D.R3dShadow => (Machine.Machine, I64)
	r3d_fan_one_sw! = |machine, st, poly, i, ctx, half_w, half_h, sh| ({
		p0 = r3d_project_clip_sw((List.get(poly, I64.to_u64_wrap(0)) ?? crash("list-at out of range")), half_w, half_h, sh)
		pa = r3d_project_clip_sw((List.get(poly, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), half_w, half_h, sh)
		pb = r3d_project_clip_sw((List.get(poly, I64.to_u64_wrap((i + 1))) ?? crash("list-at out of range")), half_w, half_h, sh)
		(if Culling.cull_backface(p0.pv_sx, p0.pv_sy, pa.pv_sx, pa.pv_sy, pb.pv_sx, pb.pv_sy) { (machine, 0) } else { r3d_rasterize_tri_sh!(machine, st, p0, pa, pb, ctx) })
	})

	r3d_render_tris_flat_sw! : Machine.Machine, Renderer3D.R3dTriState, Mesh.Mesh, Matrix4.Mat4, Matrix4.Mat4, Material.EngineMaterial, List(Scene3D.Light3D), Quaternion.Vec3, I64, Renderer3D.R3dShadow, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_render_tris_flat_sw! = |machine, st, mesh, model, mvp, mat, lights, eye, ambient, sh, half_w, half_h, i, n| (if (i >= n) { (machine, 0) } else { ({
		c0 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, i)), mvp, model)
		c1 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, (i + 1))), mvp, model)
		c2 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, (i + 2))), mvp, model)
		poly = r3d_clip_tri(c0, c1, c2)
		(if (U64.to_i64_wrap(List.len(poly)) < 3) { r3d_render_tris_flat_sw!(machine, st, mesh, model, mvp, mat, lights, eye, ambient, sh, half_w, half_h, (i + 3), n) } else { ({
			face_normal = Matrix4.mat4_v3_normalize(Quaternion.vec3_new((I64.to_f64(((c0.cv_nx + c1.cv_nx) + c2.cv_nx)) / 3.0), (I64.to_f64(((c0.cv_ny + c1.cv_ny) + c2.cv_ny)) / 3.0), (I64.to_f64(((c0.cv_nz + c1.cv_nz) + c2.cv_nz)) / 3.0)))
			center = Quaternion.vec3_new((((c0.cv_wx + c1.cv_wx) + c2.cv_wx) / 3.0), (((c0.cv_wy + c1.cv_wy) + c2.cv_wy) / 3.0), (((c0.cv_wz + c1.cv_wz) + c2.cv_wz) / 3.0))
			lit = Color.rgb_to_packed(r3d_shade_phong(center, face_normal, eye, mat, lights, 0, U64.to_i64_wrap(List.len(lights)), ambient))
			amb = Color.rgb_to_packed(Color.rgb_scale(mat.emat_albedo, ambient))
			ctx = r3d_ctx_with_tex(r3d_ctx_with_shadow(r3d_shade_ctx_flat(lit), sh, amb), mat)
			(machine1, _hit) = r3d_raster_fan_sw!(machine, st, poly, 1, ctx, half_w, half_h, sh)
			r3d_render_tris_flat_sw!(machine1, st, mesh, model, mvp, mat, lights, eye, ambient, sh, half_w, half_h, (i + 3), n)
		}) })
	}) })

	r3d_render_tris_gouraud_sw! : Machine.Machine, Renderer3D.R3dTriState, Mesh.Mesh, Matrix4.Mat4, Matrix4.Mat4, Material.EngineMaterial, List(Scene3D.Light3D), Quaternion.Vec3, I64, Renderer3D.R3dShadow, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_render_tris_gouraud_sw! = |machine, st, mesh, model, mvp, mat, lights, eye, ambient, sh, half_w, half_h, i, n| (if (i >= n) { (machine, 0) } else { ({
		c0 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, i)), mvp, model)
		c1 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, (i + 1))), mvp, model)
		c2 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, (i + 2))), mvp, model)
		poly = r3d_clip_tri(c0, c1, c2)
		(if (U64.to_i64_wrap(List.len(poly)) < 3) { r3d_render_tris_gouraud_sw!(machine, st, mesh, model, mvp, mat, lights, eye, ambient, sh, half_w, half_h, (i + 3), n) } else { ({
			amb = Color.rgb_to_packed(Color.rgb_scale(mat.emat_albedo, ambient))
			g0 = r3d_shade_clip_vert((List.get(poly, I64.to_u64_wrap(0)) ?? crash("list-at out of range")), mat, lights, eye, ambient)
			(machine1, _hit) = r3d_gouraud_fan_sw!(machine, st, poly, 1, mat, lights, eye, ambient, g0, amb, sh, half_w, half_h)
			r3d_render_tris_gouraud_sw!(machine1, st, mesh, model, mvp, mat, lights, eye, ambient, sh, half_w, half_h, (i + 3), n)
		}) })
	}) })

	r3d_gouraud_fan_sw! : Machine.Machine, Renderer3D.R3dTriState, List(Renderer3D.ClipVert), I64, Material.EngineMaterial, List(Scene3D.Light3D), Quaternion.Vec3, I64, I64, I64, Renderer3D.R3dShadow, I64, I64 => (Machine.Machine, I64)
	r3d_gouraud_fan_sw! = |machine, st, poly, i, mat, lights, eye, ambient, g0, amb, sh, half_w, half_h| (if ((i + 1) >= U64.to_i64_wrap(List.len(poly))) { (machine, 0) } else { ({
		gi = r3d_shade_clip_vert((List.get(poly, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), mat, lights, eye, ambient)
		gj = r3d_shade_clip_vert((List.get(poly, I64.to_u64_wrap((i + 1))) ?? crash("list-at out of range")), mat, lights, eye, ambient)
		ctx = r3d_ctx_with_tex(r3d_ctx_with_shadow(r3d_shade_ctx_gouraud(g0, gi, gj), sh, amb), mat)
		(machine1, _hit) = r3d_fan_one_sw!(machine, st, poly, i, ctx, half_w, half_h, sh)
		r3d_gouraud_fan_sw!(machine1, st, poly, (i + 1), mat, lights, eye, ambient, g0, amb, sh, half_w, half_h)
	}) })

	r3d_render_tris_phong_sw! : Machine.Machine, Renderer3D.R3dTriState, Mesh.Mesh, Matrix4.Mat4, Matrix4.Mat4, Material.EngineMaterial, List(Scene3D.Light3D), Quaternion.Vec3, I64, Renderer3D.R3dShadow, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_render_tris_phong_sw! = |machine, st, mesh, model, mvp, mat, lights, eye, ambient, sh, half_w, half_h, i, n| (if (i >= n) { (machine, 0) } else { ({
		c0 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, i)), mvp, model)
		c1 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, (i + 1))), mvp, model)
		c2 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, (i + 2))), mvp, model)
		poly = r3d_clip_tri(c0, c1, c2)
		(if (U64.to_i64_wrap(List.len(poly)) < 3) { r3d_render_tris_phong_sw!(machine, st, mesh, model, mvp, mat, lights, eye, ambient, sh, half_w, half_h, (i + 3), n) } else { ({
			amb = Color.rgb_to_packed(Color.rgb_scale(mat.emat_albedo, ambient))
			ctx = r3d_ctx_with_shadow(r3d_shade_ctx_phong(c0, c1, c2, mat, lights, eye, ambient), sh, amb)
			(machine1, _hit) = r3d_raster_fan_sw!(machine, st, poly, 1, ctx, half_w, half_h, sh)
			r3d_render_tris_phong_sw!(machine1, st, mesh, model, mvp, mat, lights, eye, ambient, sh, half_w, half_h, (i + 3), n)
		}) })
	}) })

	r3d_render_mesh_sw! : Machine.Machine, Renderer3D.R3dTriState, Mesh.Mesh, Matrix4.Mat4, Matrix4.Mat4, Material.EngineMaterial, List(Scene3D.Light3D), Quaternion.Vec3, I64, Renderer3D.R3dShadow, I64, I64 => (Machine.Machine, I64)
	r3d_render_mesh_sw! = |machine, st, mesh, model, mvp, mat, lights, eye, ambient, sh, half_w, half_h| (match mat.emat_shading {
		Unlit => r3d_render_unlit_dispatch!(machine, st, mesh, mvp, mat, half_w, half_h)
		FlatShaded => r3d_render_tris_flat_sw!(machine, st, mesh, model, mvp, mat, lights, eye, ambient, sh, half_w, half_h, 0, mesh.mesh_index_count)
		GouraudShaded => r3d_render_tris_gouraud_sw!(machine, st, mesh, model, mvp, mat, lights, eye, ambient, sh, half_w, half_h, 0, mesh.mesh_index_count)
		PhongShaded => r3d_render_tris_phong_sw!(machine, st, mesh, model, mvp, mat, lights, eye, ambient, sh, half_w, half_h, 0, mesh.mesh_index_count)
	})

	r3d_render_nodes_sw! : Machine.Machine, Scene3D.Scene3DState, Matrix4.Mat4, Culling.Frustum, Renderer3D.R3dTriState, Renderer3D.R3dShadow, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_render_nodes_sw! = |machine, scene, vp, fr, st, sh, i, n, w, h| (if (i >= n) { (machine, 0) } else { ({
		node = (List.get(scene.s3_nodes, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(machine1, _drawn) = (if node.sn3_visible { r3d_render_node_sw!(machine, scene, vp, fr, st, sh, node, i, w, h) } else { (machine, 0) })
		r3d_render_nodes_sw!(machine1, scene, vp, fr, st, sh, (i + 1), n, w, h)
	}) })

	r3d_render_node_sw! : Machine.Machine, Scene3D.Scene3DState, Matrix4.Mat4, Culling.Frustum, Renderer3D.R3dTriState, Renderer3D.R3dShadow, Scene3D.SceneNode3D, I64, I64, I64 => (Machine.Machine, I64)
	r3d_render_node_sw! = |machine, scene, vp, fr, st, sh, node, idx, w, h| (match node.sn3_mesh {
		None => (machine, 0)
		Just(mesh) => ({
			model = Scene3D.scene3d_world_matrix(scene, idx)
			verdict = Culling.frustum_test_aabb(fr, r3d_world_bounds(Mesh.mesh_bounds(mesh), model))
			(match verdict {
				FrOutside => (machine, 0)
				_ => ({
					mvp = Matrix4.mat4_mul(vp, model)
					r3d_render_mesh_sw!(machine, st, mesh, model, mvp, node.sn3_material, scene.s3_lights, scene.s3_camera.c3_eye, scene.s3_ambient, sh, I64.div_trunc_by(w, 2), I64.div_trunc_by(h, 2))
				})
			})
		})
	})

	r3d_render_shadowed! : Machine.Machine, Renderer3D.R3dTriState, Scene3D.Scene3DState, I64 => (Machine.Machine, I64)
	r3d_render_shadowed! = |machine, st, scene, map_size| (match r3d_first_dir(scene.s3_lights, 0, U64.to_i64_wrap(List.len(scene.s3_lights))) {
		None => r3d_render_into!(machine, st, scene)
		Just(dir) => ({
			lvp = r3d_light_vp(scene, dir)
			(machine1, sh_st) = r3d_target_new!(machine, map_size, map_size, 0)
			(machine2, _dp) = r3d_shadow_pass!(machine1, sh_st, scene, lvp)
			sh = { rs_base: sh_st.r3t_depth, rs_size: map_size, rs_bias: r3d_shadow_bias, rs_vp: lvp }
			vp = Scene3D.camera3d_vp(scene.s3_camera)
			fr = Culling.frustum_extract(vp)
			r3d_render_nodes_sw!(machine2, scene, vp, fr, st, sh, 0, scene.s3_count, st.r3t_w, st.r3t_h)
		})
	})

	r3d_render_scene_shadowed! : Machine.Machine, Scene3D.Scene3DState, I64, I64, I64 => (Machine.Machine, Rasterizer.Framebuf)
	r3d_render_scene_shadowed! = |machine, scene, width, height, map_size| ({
		(machine4, machine__17) = ({
		(machine1, st) = r3d_target_new!(machine, width, height, Color.rgb_to_packed(Color.rgb(20, 20, 30)))
		(machine2, _drawn) = r3d_render_shadowed!(machine1, st, scene, map_size)
		({
			(machine3, machine__16) = r3d_buf_to_list!(machine2, st.r3t_base, 0, (width * height), [])
			(machine3, { fb_width: width, fb_height: height, fb_pixels: machine__16 })
		})
	})
		(machine4, machine__17)
	})

	r3d_render_scene! : Machine.Machine, Scene3D.Scene3DState, I64, I64 => (Machine.Machine, Rasterizer.Framebuf)
	r3d_render_scene! = |machine, scene, width, height| ({
		(machine4, machine__19) = ({
		(machine1, st) = r3d_target_new!(machine, width, height, Color.rgb_to_packed(Color.rgb(20, 20, 30)))
		(machine2, _drawn) = r3d_render_into!(machine1, st, scene)
		({
			(machine3, machine__18) = r3d_buf_to_list!(machine2, st.r3t_base, 0, (width * height), [])
			(machine3, { fb_width: width, fb_height: height, fb_pixels: machine__18 })
		})
	})
		(machine4, machine__19)
	})

	r3d_render_into! : Machine.Machine, Renderer3D.R3dTriState, Scene3D.Scene3DState => (Machine.Machine, I64)
	r3d_render_into! = |machine, st, scene| ({
		vp = Scene3D.camera3d_vp(scene.s3_camera)
		fr = Culling.frustum_extract(vp)
		r3d_render_nodes!(machine, scene, vp, fr, st, 0, scene.s3_count, st.r3t_w, st.r3t_h)
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
		{ mb_min_x: F64.to_i64_wrap(r3d_rmin8(c0.vx, c1.vx, c2.vx, c3.vx, c4.vx, c5.vx, c6.vx, c7.vx)), mb_min_y: F64.to_i64_wrap(r3d_rmin8(c0.vy, c1.vy, c2.vy, c3.vy, c4.vy, c5.vy, c6.vy, c7.vy)), mb_min_z: F64.to_i64_wrap(r3d_rmin8(c0.vz, c1.vz, c2.vz, c3.vz, c4.vz, c5.vz, c6.vz, c7.vz)), mb_max_x: F64.to_i64_wrap(r3d_rmax8(c0.vx, c1.vx, c2.vx, c3.vx, c4.vx, c5.vx, c6.vx, c7.vx)), mb_max_y: F64.to_i64_wrap(r3d_rmax8(c0.vy, c1.vy, c2.vy, c3.vy, c4.vy, c5.vy, c6.vy, c7.vy)), mb_max_z: F64.to_i64_wrap(r3d_rmax8(c0.vz, c1.vz, c2.vz, c3.vz, c4.vz, c5.vz, c6.vz, c7.vz)) }
	})

	r3d_rmin : F64, F64 -> F64
	r3d_rmin = |a, b| (if (a < b) { a } else { b })

	r3d_rmax : F64, F64 -> F64
	r3d_rmax = |a, b| (if (a > b) { a } else { b })

	r3d_rmin8 : F64, F64, F64, F64, F64, F64, F64, F64 -> F64
	r3d_rmin8 = |a, b, c, d, e, f, g, h| r3d_rmin(r3d_rmin(r3d_rmin(a, b), r3d_rmin(c, d)), r3d_rmin(r3d_rmin(e, f), r3d_rmin(g, h)))

	r3d_rmax8 : F64, F64, F64, F64, F64, F64, F64, F64 -> F64
	r3d_rmax8 = |a, b, c, d, e, f, g, h| r3d_rmax(r3d_rmax(r3d_rmax(a, b), r3d_rmax(c, d)), r3d_rmax(r3d_rmax(e, f), r3d_rmax(g, h)))

	r3d_buf_to_list! : Machine.Machine, I64, I64, I64, List(I64) => (Machine.Machine, List(I64))
	r3d_buf_to_list! = |machine, base, i, n, acc| (if (i >= n) { (machine, acc) } else { ({
		(machine1, machine__20) = Machine.load!(machine, base, (i * 4), 4)
		r3d_buf_to_list!(machine1, base, (i + 1), n, List.append(acc, machine__20))
	}) })

	r3d_render_nodes! : Machine.Machine, Scene3D.Scene3DState, Matrix4.Mat4, Culling.Frustum, Renderer3D.R3dTriState, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_render_nodes! = |machine, scene, vp, fr, st, i, n, w, h| (if (i >= n) { (machine, 0) } else { ({
		node = (List.get(scene.s3_nodes, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(machine1, _drawn) = (if node.sn3_visible { r3d_render_node!(machine, scene, vp, fr, st, node, i, w, h) } else { (machine, 0) })
		r3d_render_nodes!(machine1, scene, vp, fr, st, (i + 1), n, w, h)
	}) })

	r3d_render_node! : Machine.Machine, Scene3D.Scene3DState, Matrix4.Mat4, Culling.Frustum, Renderer3D.R3dTriState, Scene3D.SceneNode3D, I64, I64, I64 => (Machine.Machine, I64)
	r3d_render_node! = |machine, scene, vp, fr, st, node, idx, w, h| (match node.sn3_mesh {
		None => (machine, 0)
		Just(mesh) => ({
			model = Scene3D.scene3d_world_matrix(scene, idx)
			verdict = Culling.frustum_test_aabb(fr, r3d_world_bounds(Mesh.mesh_bounds(mesh), model))
			(match verdict {
				FrOutside => (machine, 0)
				_ => ({
					mvp = Matrix4.mat4_mul(vp, model)
					half_w = I64.div_trunc_by(w, 2)
					half_h = I64.div_trunc_by(h, 2)
					r3d_render_mesh!(machine, st, mesh, model, mvp, node.sn3_material, scene.s3_lights, scene.s3_camera.c3_eye, scene.s3_ambient, half_w, half_h)
				})
			})
		})
	})

	r3d_render_mesh! : Machine.Machine, Renderer3D.R3dTriState, Mesh.Mesh, Matrix4.Mat4, Matrix4.Mat4, Material.EngineMaterial, List(Scene3D.Light3D), Quaternion.Vec3, I64, I64, I64 => (Machine.Machine, I64)
	r3d_render_mesh! = |machine, st, mesh, model, mvp, mat, lights, eye, ambient, half_w, half_h| ({
		shading = mat.emat_shading
		(match shading {
			Unlit => r3d_render_unlit_dispatch!(machine, st, mesh, mvp, mat, half_w, half_h)
			FlatShaded => r3d_render_tris_flat!(machine, st, mesh, model, mvp, mat, lights, eye, ambient, half_w, half_h, 0, mesh.mesh_index_count)
			GouraudShaded => r3d_render_tris_gouraud!(machine, st, mesh, model, mvp, mat, lights, eye, ambient, half_w, half_h, 0, mesh.mesh_index_count)
			PhongShaded => r3d_render_tris_phong!(machine, st, mesh, model, mvp, mat, lights, eye, ambient, half_w, half_h, 0, mesh.mesh_index_count)
		})
	})

	r3d_render_unlit_dispatch! : Machine.Machine, Renderer3D.R3dTriState, Mesh.Mesh, Matrix4.Mat4, Material.EngineMaterial, I64, I64 => (Machine.Machine, I64)
	r3d_render_unlit_dispatch! = |machine, st, mesh, mvp, mat, half_w, half_h| (match mat.emat_texture {
		None => r3d_render_tris_unlit!(machine, st, mesh, mvp, mat, half_w, half_h, 0, mesh.mesh_index_count)
		Just(_t) => r3d_render_tris_unlit_tex!(machine, st, mesh, mvp, mat, half_w, half_h, 0, mesh.mesh_index_count)
	})

	r3d_render_tris_unlit_tex! : Machine.Machine, Renderer3D.R3dTriState, Mesh.Mesh, Matrix4.Mat4, Material.EngineMaterial, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_render_tris_unlit_tex! = |machine, st, mesh, mvp, mat, half_w, half_h, i, n| (if (i >= n) { (machine, 0) } else { ({
		c0 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, i)), mvp, Matrix4.mat4_identity)
		c1 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, (i + 1))), mvp, Matrix4.mat4_identity)
		c2 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, (i + 2))), mvp, Matrix4.mat4_identity)
		poly = r3d_clip_tri(c0, c1, c2)
		ctx = r3d_ctx_with_tex(r3d_shade_ctx_flat(Color.rgb_to_packed(mat.emat_albedo)), mat)
		(machine1, _drawn) = r3d_raster_fan_sh!(machine, st, poly, 1, ctx, half_w, half_h)
		r3d_render_tris_unlit_tex!(machine1, st, mesh, mvp, mat, half_w, half_h, (i + 3), n)
	}) })

	r3d_render_tris_unlit! : Machine.Machine, Renderer3D.R3dTriState, Mesh.Mesh, Matrix4.Mat4, Material.EngineMaterial, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_render_tris_unlit! = |machine, st, mesh, mvp, mat, half_w, half_h, i, n| (if (i >= n) { (machine, 0) } else { ({
		i0 = Mesh.mesh_index_at(mesh, i)
		i1 = Mesh.mesh_index_at(mesh, (i + 1))
		i2 = Mesh.mesh_index_at(mesh, (i + 2))
		v0 = Mesh.mesh_vertex_at(mesh, i0)
		v1 = Mesh.mesh_vertex_at(mesh, i1)
		v2 = Mesh.mesh_vertex_at(mesh, i2)
		c0 = r3d_clip_vertex(v0, mvp, Matrix4.mat4_identity)
		c1 = r3d_clip_vertex(v1, mvp, Matrix4.mat4_identity)
		c2 = r3d_clip_vertex(v2, mvp, Matrix4.mat4_identity)
		poly = r3d_clip_tri(c0, c1, c2)
		color = Color.rgb_to_packed(mat.emat_albedo)
		(machine1, _drawn) = r3d_raster_fan!(machine, st, poly, 1, color, half_w, half_h)
		r3d_render_tris_unlit!(machine1, st, mesh, mvp, mat, half_w, half_h, (i + 3), n)
	}) })

	r3d_render_tris_caster! : Machine.Machine, Renderer3D.R3dTriState, Mesh.Mesh, Matrix4.Mat4, Material.EngineMaterial, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_render_tris_caster! = |machine, st, mesh, mvp, mat, half_w, half_h, i, n| (if (i >= n) { (machine, 0) } else { ({
		c0 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, i)), mvp, Matrix4.mat4_identity)
		c1 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, (i + 1))), mvp, Matrix4.mat4_identity)
		c2 = r3d_clip_vertex(Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, (i + 2))), mvp, Matrix4.mat4_identity)
		poly = r3d_clip_tri(c0, c1, c2)
		(machine1, _drawn) = r3d_raster_fan_cast!(machine, st, poly, 1, Color.rgb_to_packed(mat.emat_albedo), half_w, half_h)
		r3d_render_tris_caster!(machine1, st, mesh, mvp, mat, half_w, half_h, (i + 3), n)
	}) })

	r3d_raster_fan_cast! : Machine.Machine, Renderer3D.R3dTriState, List(Renderer3D.ClipVert), I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_raster_fan_cast! = |machine, st, poly, i, color, half_w, half_h| (if ((i + 1) >= U64.to_i64_wrap(List.len(poly))) { (machine, 0) } else { ({
		p0 = r3d_project_clip((List.get(poly, I64.to_u64_wrap(0)) ?? crash("list-at out of range")), half_w, half_h)
		pa = r3d_project_clip((List.get(poly, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), half_w, half_h)
		pb = r3d_project_clip((List.get(poly, I64.to_u64_wrap((i + 1))) ?? crash("list-at out of range")), half_w, half_h)
		(machine1, _hit) = (if Culling.cull_backface(p0.pv_sx, p0.pv_sy, pa.pv_sx, pa.pv_sy, pb.pv_sx, pb.pv_sy) { (machine, 0) } else { r3d_rasterize_tri!(machine, st, p0, pa, pb, color) })
		r3d_raster_fan_cast!(machine1, st, poly, (i + 1), color, half_w, half_h)
	}) })

	r3d_render_tris_flat! : Machine.Machine, Renderer3D.R3dTriState, Mesh.Mesh, Matrix4.Mat4, Matrix4.Mat4, Material.EngineMaterial, List(Scene3D.Light3D), Quaternion.Vec3, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	r3d_render_tris_flat! = |machine, st, mesh, model, mvp, mat, lights, eye, ambient, half_w, half_h, i, n| (if (i >= n) { (machine, 0) } else { ({
		i0 = Mesh.mesh_index_at(mesh, i)
		i1 = Mesh.mesh_index_at(mesh, (i + 1))
		i2 = Mesh.mesh_index_at(mesh, (i + 2))
		v0 = Mesh.mesh_vertex_at(mesh, i0)
		v1 = Mesh.mesh_vertex_at(mesh, i1)
		v2 = Mesh.mesh_vertex_at(mesh, i2)
		c0 = r3d_clip_vertex(v0, mvp, model)
		c1 = r3d_clip_vertex(v1, mvp, model)
		c2 = r3d_clip_vertex(v2, mvp, model)
		poly = r3d_clip_tri(c0, c1, c2)
		(if (U64.to_i64_wrap(List.len(poly)) < 3) { r3d_render_tris_flat!(machine, st, mesh, model, mvp, mat, lights, eye, ambient, half_w, half_h, (i + 3), n) } else { ({
			face_nx = (I64.to_f64(((c0.cv_nx + c1.cv_nx) + c2.cv_nx)) / 3.0)
			face_ny = (I64.to_f64(((c0.cv_ny + c1.cv_ny) + c2.cv_ny)) / 3.0)
			face_nz = (I64.to_f64(((c0.cv_nz + c1.cv_nz) + c2.cv_nz)) / 3.0)
			face_normal = Matrix4.mat4_v3_normalize(Quaternion.vec3_new(face_nx, face_ny, face_nz))
			center = Quaternion.vec3_new((((c0.cv_wx + c1.cv_wx) + c2.cv_wx) / 3.0), (((c0.cv_wy + c1.cv_wy) + c2.cv_wy) / 3.0), (((c0.cv_wz + c1.cv_wz) + c2.cv_wz) / 3.0))
			color = r3d_shade_phong(center, face_normal, eye, mat, lights, 0, U64.to_i64_wrap(List.len(lights)), ambient)
			ctx = r3d_ctx_with_tex(r3d_shade_ctx_flat(Color.rgb_to_packed(color)), mat)
			(machine1, _drawn) = r3d_raster_fan_sh!(machine, st, poly, 1, ctx, half_w, half_h)
			r3d_render_tris_flat!(machine1, st, mesh, model, mvp, mat, lights, eye, ambient, half_w, half_h, (i + 3), n)
		}) })
	}) })

	r3d_unit_to_milli : F64 -> I64
	r3d_unit_to_milli = |x| F64.to_i64_wrap((x * 1000.0))

	r3d_vec_len : Quaternion.Vec3 -> I64
	r3d_vec_len = |v| F64.to_i64_wrap(Matrix4.mat4_v3_length(v))

	r3d_reflect : Quaternion.Vec3, Quaternion.Vec3 -> Quaternion.Vec3
	r3d_reflect = |incoming, normal| ({
		d = Quaternion.vec3_dot(incoming, normal)
		Quaternion.vec3_subtract(incoming, Quaternion.vec3_scale(normal, (2.0 * d)))
	})

	r3d_negate_vec : Quaternion.Vec3 -> Quaternion.Vec3
	r3d_negate_vec = |v| Quaternion.vec3_scale(v, (-1.0))

	r3d_pow_int : I64, I64 -> I64
	r3d_pow_int = |base, exp| r3d_pow_loop(base, exp, 1000)

	r3d_pow_loop : I64, I64, I64 -> I64
	r3d_pow_loop = |base, exp, acc| (if (exp <= 0) { acc } else { r3d_pow_loop(base, (exp - 1), I64.div_trunc_by((acc * base), 1000)) })

	r3d_min : I64, I64 -> I64
	r3d_min = |a, b| (if (a < b) { a } else { b })

	r3d_max : I64, I64 -> I64
	r3d_max = |a, b| (if (a > b) { a } else { b })

	r3d_min3 : I64, I64, I64 -> I64
	r3d_min3 = |a, b, c| r3d_min(a, r3d_min(b, c))

	r3d_max3 : I64, I64, I64 -> I64
	r3d_max3 = |a, b, c| r3d_max(a, r3d_max(b, c))

	r3d_clamp : I64, I64, I64 -> I64
	r3d_clamp = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	r3d_abs : I64 -> I64
	r3d_abs = |n| (if (n < 0) { (0 - n) } else { n })
}
