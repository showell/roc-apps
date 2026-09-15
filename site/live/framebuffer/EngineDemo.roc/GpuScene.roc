# GpuScene -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Color
import Culling
import Machine
import Material
import Matrix4
import Mesh
import Quaternion
import Renderer3D
import Scene3D
import Texture

GpuScene :: [].{
	GpuView : { gv_x : I64, gv_y : I64, gv_w : I64, gv_h : I64 }
	GsShadow : { gsh_on : I64, gsh_lm : Matrix4.Mat4, gsh_size : I64 }
	GsLight : { gl_x : I64, gl_y : I64, gl_d : I64 }
	GsProj : { gp_sx : I64, gp_sy : I64, gp_depth : I64, gp_behind : I64 }

	gv_new : I64, I64, I64, I64 -> GpuScene.GpuView
	gv_new = |x, y, w, h| { gv_x: x, gv_y: y, gv_w: w, gv_h: h }

	gs_vp_origin : I64
	gs_vp_origin = 1027

	gs_vp_extent : I64
	gs_vp_extent = 1039

	gs_viewport_set! : Machine.Machine, GpuScene.GpuView => (Machine.Machine, I64)
	gs_viewport_set! = |machine, gv| ({
		(machine1, _o) = Machine.port_out_32!(machine, gs_vp_origin, ((gv.gv_x * 65536) + gv.gv_y))
		Machine.port_out_32!(machine1, gs_vp_extent, ((((gv.gv_x + gv.gv_w) - 1) * 65536) + ((gv.gv_y + gv.gv_h) - 1)))
	})

	gs_viewport_release! : Machine.Machine => (Machine.Machine, I64)
	gs_viewport_release! = |machine| Machine.port_out_32!(machine, gs_vp_extent, 0)

	gs_cmd : I64
	gs_cmd = 3187671040

	gs_tex_buf : I64
	gs_tex_buf = 3193044992

	gs_tex_write! : Machine.Machine, List(I64), I64, I64, I64 => (Machine.Machine, I64)
	gs_tex_write! = |machine, px, i, n, acc| (if (i >= n) { (machine, acc) } else { ({
		(machine1, machine__21) = Machine.store!(machine, gs_tex_buf, (i * 4), (List.get(px, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), 4)
		gs_tex_write!(machine1, px, (i + 1), n, (acc + machine__21))
	}) })

	gs_tex_upload! : Machine.Machine, Texture.EngineTexture => (Machine.Machine, I64)
	gs_tex_upload! = |machine, tex| ({
		({
			w = tex.etx_width
			h = tex.etx_height
			({
				(machine1, _wr) = gs_tex_write!(machine, tex.etx_pixels, 0, (w * h), 0)
				(machine2, _a) = Machine.port_out_32!(machine1, 1032, gs_tex_buf)
				(machine3, _b) = Machine.port_out_32!(machine2, 1033, w)
				(machine4, _c) = Machine.port_out_32!(machine3, 1034, h)
				Machine.port_out_32!(machine4, 1035, 1)
			})
		})
	})

	gs_has_tex : Material.EngineMaterial -> Bool
	gs_has_tex = |mat| (match mat.emat_texture {
		None => False
		Just(_t) => True
	})

	gs_max_tris : I64
	gs_max_tris = 1024

	gs_render_in! : Machine.Machine, Scene3D.Scene3DState, GpuScene.GpuView, I64 => (Machine.Machine, I64)
	gs_render_in! = |machine, scene, gv, sky| ({
		(machine1, _v) = gs_viewport_set!(machine, gv)
		({
			(machine2, machine__22) = gs_build!(machine1, scene, gv, gs_shadow_off)
			gs_flush!(machine2, sky, machine__22)
		})
	})

	gs_render_full! : Machine.Machine, Scene3D.Scene3DState, GpuScene.GpuView, I64 => (Machine.Machine, I64)
	gs_render_full! = |machine, scene, gv, sky| ({
		(machine1, _v) = gs_viewport_release!(machine)
		({
			(machine2, machine__23) = gs_build!(machine1, scene, gv, gs_shadow_off)
			gs_flush!(machine2, sky, machine__23)
		})
	})

	gs_build! : Machine.Machine, Scene3D.Scene3DState, GpuScene.GpuView, GpuScene.GsShadow => (Machine.Machine, I64)
	gs_build! = |machine, scene, gv, sh| ({
		vp = Scene3D.camera3d_vp(scene.s3_camera)
		gs_build_cmds!(machine, scene, vp, Culling.frustum_extract(vp), gv, sh, 0, Scene3D.scene3d_count(scene), 0)
	})

	gs_flush! : Machine.Machine, I64, I64 => (Machine.Machine, I64)
	gs_flush! = |machine, sky, tri_count| ({
		(machine1, _w1) = Machine.port_out_32!(machine, 1025, sky)
		(machine2, _w2) = Machine.port_out_32!(machine1, 1026, 0)
		Machine.port_out_32!(machine2, 1024, tri_count)
	})

	gs_render_shadowed! : Machine.Machine, Scene3D.Scene3DState, GpuScene.GpuView, I64, I64 => (Machine.Machine, I64)
	gs_render_shadowed! = |machine, scene, gv, sky, map_size| (match Renderer3D.r3d_first_dir(scene.s3_lights, 0, U64.to_i64_wrap(List.len(scene.s3_lights))) {
		None => gs_render_in!(machine, scene, gv, sky)
		Just(dir) => gs_render_two_pass!(machine, scene, gv, sky, map_size, Renderer3D.r3d_light_vp(scene, dir))
	})

	gs_render_two_pass! : Machine.Machine, Scene3D.Scene3DState, GpuScene.GpuView, I64, I64, Matrix4.Mat4 => (Machine.Machine, I64)
	gs_render_two_pass! = |machine, scene, gv, sky, map_size, lvp| ({
		(machine1, _arm) = Machine.port_out_32!(machine, 1026, map_size)
		(machine3, _cast) = ({
			(machine2, machine__24) = gs_build_cmds!(machine1, scene, lvp, Culling.frustum_extract(lvp), gv_new(0, 0, map_size, map_size), gs_shadow_depth, 0, Scene3D.scene3d_count(scene), 0)
			Machine.port_out_32!(machine2, 1024, (machine__24 + gs_shadow_flag))
		})
		(machine4, _v) = gs_viewport_set!(machine3, gv)
		({
			(machine5, machine__25) = gs_build!(machine4, scene, gv, { gsh_on: 1, gsh_lm: lvp, gsh_size: map_size })
			gs_flush!(machine5, sky, machine__25)
		})
	})

	gs_light_addr : I64
	gs_light_addr = 3192913920

	gs_shadow_flag : I64
	gs_shadow_flag = 1073741824

	gs_shadow_off : GpuScene.GsShadow
	gs_shadow_off = { gsh_on: 0, gsh_lm: Matrix4.mat4_identity, gsh_size: 0 }

	gs_shadow_depth : GpuScene.GsShadow
	gs_shadow_depth = { gsh_on: 2, gsh_lm: Matrix4.mat4_identity, gsh_size: 0 }

	gs_lproj : Mesh.Vertex, Matrix4.Mat4, I64 -> GpuScene.GsLight
	gs_lproj = |v, lmvp, size| ({
		clip = Matrix4.mat4_transform_vec4(lmvp, { v4x: I64.to_f64(v.vp_x), v4y: I64.to_f64(v.vp_y), v4z: I64.to_f64(v.vp_z), v4w: 1.0 })
		(if (clip.v4w <= 0.0) { { gl_x: (0 - 1), gl_y: (0 - 1), gl_d: 0 } } else { ({
			fs = I64.to_f64(size)
			{ gl_x: F64.to_i64_wrap((((((clip.v4x / clip.v4w) * 0.5) + 0.5) * fs) * 1000.0)), gl_y: F64.to_i64_wrap((((0.5 - ((clip.v4y / clip.v4w) * 0.5)) * fs) * 1000.0)), gl_d: F64.to_i64_wrap((((clip.v4z / clip.v4w) + 1.0) * 500000.0)) }
		}) })
	})

	gs_write_light! : Machine.Machine, I64, GpuScene.GsLight, GpuScene.GsLight, GpuScene.GsLight, I64 => (Machine.Machine, I64)
	gs_write_light! = |machine, idx, a, b, c, shadow_color| ({
		(machine11, machine__36) = ({
		off = (idx * 40)
		({
			(machine1, machine__26) = Machine.store!(machine, gs_light_addr, off, a.gl_x, 4)
			(machine2, machine__27) = Machine.store!(machine1, gs_light_addr, (off + 4), a.gl_y, 4)
			(machine3, machine__28) = Machine.store!(machine2, gs_light_addr, (off + 8), a.gl_d, 4)
			(machine4, machine__29) = Machine.store!(machine3, gs_light_addr, (off + 12), b.gl_x, 4)
			(machine5, machine__30) = Machine.store!(machine4, gs_light_addr, (off + 16), b.gl_y, 4)
			(machine6, machine__31) = Machine.store!(machine5, gs_light_addr, (off + 20), b.gl_d, 4)
			(machine7, machine__32) = Machine.store!(machine6, gs_light_addr, (off + 24), c.gl_x, 4)
			(machine8, machine__33) = Machine.store!(machine7, gs_light_addr, (off + 28), c.gl_y, 4)
			(machine9, machine__34) = Machine.store!(machine8, gs_light_addr, (off + 32), c.gl_d, 4)
			(machine10, machine__35) = Machine.store!(machine9, gs_light_addr, (off + 36), shadow_color, 4)
			(machine10, (((((((((machine__26 + machine__27) + machine__28) + machine__29) + machine__30) + machine__31) + machine__32) + machine__33) + machine__34) + machine__35))
		})
	})
		(machine11, machine__36)
	})

	gs_ambient_color : Material.EngineMaterial, I64 -> I64
	gs_ambient_color = |mat, ambient| Color.rgb_to_packed(Color.rgb_scale(mat.emat_albedo, ambient))

	gs_smooth : Material.EngineMaterial -> Bool
	gs_smooth = |mat| (match mat.emat_shading {
		FlatShaded => False
		Unlit => False
		GouraudShaded => True
		PhongShaded => True
	})

	gs_face_color : Mesh.Vertex, Mesh.Vertex, Mesh.Vertex, Matrix4.Mat4, Material.EngineMaterial, List(Scene3D.Light3D), Quaternion.Vec3, I64 -> I64
	gs_face_color = |v0, v1, v2, model, mat, lights, eye, ambient| Color.rgb_to_packed(gs_shade(Matrix4.mat4_transform_point(model, Quaternion.vec3_new((I64.to_f64(((v0.vp_x + v1.vp_x) + v2.vp_x)) / 3.0), (I64.to_f64(((v0.vp_y + v1.vp_y) + v2.vp_y)) / 3.0), (I64.to_f64(((v0.vp_z + v1.vp_z) + v2.vp_z)) / 3.0))), gs_face_normal(v0, v1, v2), eye, mat, lights, ambient))

	gs_vert_color : Mesh.Vertex, Matrix4.Mat4, Material.EngineMaterial, List(Scene3D.Light3D), Quaternion.Vec3, I64 -> I64
	gs_vert_color = |v, model, mat, lights, eye, ambient| Color.rgb_to_packed(gs_shade(Matrix4.mat4_transform_point(model, Quaternion.vec3_new(I64.to_f64(v.vp_x), I64.to_f64(v.vp_y), I64.to_f64(v.vp_z))), Matrix4.mat4_v3_normalize(Quaternion.vec3_new(I64.to_f64(v.vn_x), I64.to_f64(v.vn_y), I64.to_f64(v.vn_z))), eye, mat, lights, ambient))

	gs_build_cmds! : Machine.Machine, Scene3D.Scene3DState, Matrix4.Mat4, Culling.Frustum, GpuScene.GpuView, GpuScene.GsShadow, I64, I64, I64 => (Machine.Machine, I64)
	gs_build_cmds! = |machine, scene, vp, fr, gv, sh, i, n, tri_offset| (if (i >= n) { (machine, tri_offset) } else { ({
		node = Scene3D.scene3d_node_at(scene, i)
		({
			(machine1, machine__37) = (if node.sn3_visible { gs_node_cmds!(machine, scene, vp, fr, gv, sh, node, i, tri_offset) } else { (machine, tri_offset) })
			gs_build_cmds!(machine1, scene, vp, fr, gv, sh, (i + 1), n, machine__37)
		})
	}) })

	gs_node_cmds! : Machine.Machine, Scene3D.Scene3DState, Matrix4.Mat4, Culling.Frustum, GpuScene.GpuView, GpuScene.GsShadow, Scene3D.SceneNode3D, I64, I64 => (Machine.Machine, I64)
	gs_node_cmds! = |machine, scene, vp, fr, gv, sh, node, idx, tri_offset| (match node.sn3_mesh {
		None => (machine, tri_offset)
		Just(mesh) => ({
			model = Scene3D.scene3d_world_matrix(scene, idx)
			(if gs_culled(fr, mesh, model) { (machine, tri_offset) } else { ({
				nsh = (if (sh.gsh_on == 1) { { gsh_on: 1, gsh_lm: Matrix4.mat4_mul(sh.gsh_lm, model), gsh_size: sh.gsh_size } } else { sh })
				gs_mesh_cmds!(machine, mesh, model, Matrix4.mat4_mul(vp, model), gv, nsh, node.sn3_material, scene.s3_lights, scene.s3_camera.c3_eye, scene.s3_ambient, tri_offset, 0, mesh.mesh_index_count)
			}) })
		})
	})

	gs_culled : Culling.Frustum, Mesh.Mesh, Matrix4.Mat4 -> Bool
	gs_culled = |fr, mesh, model| (match Culling.frustum_test_aabb(fr, Renderer3D.r3d_world_bounds(Mesh.mesh_bounds(mesh), model)) {
		FrOutside => True
		FrInside => False
		FrIntersect => False
	})

	gs_mesh_cmds! : Machine.Machine, Mesh.Mesh, Matrix4.Mat4, Matrix4.Mat4, GpuScene.GpuView, GpuScene.GsShadow, Material.EngineMaterial, List(Scene3D.Light3D), Quaternion.Vec3, I64, I64, I64, I64 => (Machine.Machine, I64)
	gs_mesh_cmds! = |machine, mesh, model, mvp, gv, sh, mat, lights, eye, ambient, tri_idx, i, n| (if (i >= n) { (machine, tri_idx) } else { (if (tri_idx >= gs_max_tris) { (machine, tri_idx) } else { ({
		v0 = Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, i))
		v1 = Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, (i + 1)))
		v2 = Mesh.mesh_vertex_at(mesh, Mesh.mesh_index_at(mesh, (i + 2)))
		p0 = gs_proj(v0, mvp, gv)
		p1 = gs_proj(v1, mvp, gv)
		p2 = gs_proj(v2, mvp, gv)
		area = (((p1.gp_sx - p0.gp_sx) * (p2.gp_sy - p0.gp_sy)) - ((p1.gp_sy - p0.gp_sy) * (p2.gp_sx - p0.gp_sx)))
		casting = (sh.gsh_on == 2)
		(if (area >= 0) { gs_mesh_cmds!(machine, mesh, model, mvp, gv, sh, mat, lights, eye, ambient, tri_idx, (i + 3), n) } else { (if (((p0.gp_behind + p1.gp_behind) + p2.gp_behind) > 0) { gs_mesh_cmds!(machine, mesh, model, mvp, gv, sh, mat, lights, eye, ambient, tri_idx, (i + 3), n) } else { ({
			depth_only = casting
			smooth = (if depth_only { False } else { gs_smooth(mat) })
			color = (if depth_only { 0 } else { (if smooth { 0 } else { gs_face_color(v0, v1, v2, model, mat, lights, eye, ambient) }) })
			c0 = (if smooth { gs_vert_color(v0, model, mat, lights, eye, ambient) } else { color })
			c1 = (if smooth { gs_vert_color(v1, model, mat, lights, eye, ambient) } else { color })
			c2 = (if smooth { gs_vert_color(v2, model, mat, lights, eye, ambient) } else { color })
			textured = (if depth_only { False } else { gs_has_tex(mat) })
			tu0 = (if textured { v0.vu } else { 0 })
			tv0 = (if textured { v0.vv } else { 0 })
			tu1 = (if textured { v1.vu } else { 0 })
			tv1 = (if textured { v1.vv } else { 0 })
			tu2 = (if textured { v2.vu } else { 0 })
			tv2 = (if textured { v2.vv } else { 0 })
			offset = (tri_idx * 72)
			(machine1, machine__38) = Machine.store!(machine, gs_cmd, offset, p0.gp_sx, 4)
			(machine2, machine__39) = Machine.store!(machine1, gs_cmd, (offset + 4), p0.gp_sy, 4)
			(machine3, machine__40) = Machine.store!(machine2, gs_cmd, (offset + 8), p1.gp_sx, 4)
			(machine4, machine__41) = Machine.store!(machine3, gs_cmd, (offset + 12), p1.gp_sy, 4)
			(machine5, machine__42) = Machine.store!(machine4, gs_cmd, (offset + 16), p2.gp_sx, 4)
			(machine6, machine__43) = Machine.store!(machine5, gs_cmd, (offset + 20), p2.gp_sy, 4)
			(machine7, machine__44) = Machine.store!(machine6, gs_cmd, (offset + 24), c0, 4)
			(machine8, machine__45) = Machine.store!(machine7, gs_cmd, (offset + 28), c1, 4)
			(machine9, machine__46) = Machine.store!(machine8, gs_cmd, (offset + 32), c2, 4)
			(machine10, machine__47) = Machine.store!(machine9, gs_cmd, (offset + 36), p0.gp_depth, 4)
			(machine11, machine__48) = Machine.store!(machine10, gs_cmd, (offset + 40), p1.gp_depth, 4)
			(machine12, machine__49) = Machine.store!(machine11, gs_cmd, (offset + 44), p2.gp_depth, 4)
			(machine13, machine__50) = Machine.store!(machine12, gs_cmd, (offset + 48), tu0, 4)
			(machine14, machine__51) = Machine.store!(machine13, gs_cmd, (offset + 52), tv0, 4)
			(machine15, machine__52) = Machine.store!(machine14, gs_cmd, (offset + 56), tu1, 4)
			(machine16, machine__53) = Machine.store!(machine15, gs_cmd, (offset + 60), tv1, 4)
			(machine17, machine__54) = Machine.store!(machine16, gs_cmd, (offset + 64), tu2, 4)
			(machine18, machine__55) = Machine.store!(machine17, gs_cmd, (offset + 68), tv2, 4)
			(machine19, machine__56) = (if (sh.gsh_on == 1) { gs_write_light!(machine18, tri_idx, gs_lproj(v0, sh.gsh_lm, sh.gsh_size), gs_lproj(v1, sh.gsh_lm, sh.gsh_size), gs_lproj(v2, sh.gsh_lm, sh.gsh_size), gs_ambient_color(mat, ambient)) } else { (machine18, 0) })
			_w = ((((((((((((((((((machine__38 + machine__39) + machine__40) + machine__41) + machine__42) + machine__43) + machine__44) + machine__45) + machine__46) + machine__47) + machine__48) + machine__49) + machine__50) + machine__51) + machine__52) + machine__53) + machine__54) + machine__55) + machine__56)
			gs_mesh_cmds!(machine19, mesh, model, mvp, gv, sh, mat, lights, eye, ambient, (tri_idx + 1), (i + 3), n)
		}) }) })
	}) }) })

	gs_mesh_next! : Machine.Machine, I64, Mesh.Mesh, Matrix4.Mat4, Matrix4.Mat4, GpuScene.GpuView, GpuScene.GsShadow, Material.EngineMaterial, List(Scene3D.Light3D), Quaternion.Vec3, I64, I64, I64, I64 => (Machine.Machine, I64)
	gs_mesh_next! = |machine, _w, mesh, model, mvp, gv, sh, mat, lights, eye, ambient, tri_idx, i, n| gs_mesh_cmds!(machine, mesh, model, mvp, gv, sh, mat, lights, eye, ambient, (tri_idx + 1), (i + 3), n)

	gs_proj : Mesh.Vertex, Matrix4.Mat4, GpuScene.GpuView -> GpuScene.GsProj
	gs_proj = |v, mvp, gv| ({
		clip = Matrix4.mat4_transform_vec4(mvp, { v4x: I64.to_f64(v.vp_x), v4y: I64.to_f64(v.vp_y), v4z: I64.to_f64(v.vp_z), v4w: 1.0 })
		(if (clip.v4w <= 0.0) { { gp_sx: (0 - 9999), gp_sy: (0 - 9999), gp_depth: 999999, gp_behind: 1 } } else { ({
			ndc_x = (clip.v4x / clip.v4w)
			ndc_y = (clip.v4y / clip.v4w)
			ndc_z = (clip.v4z / clip.v4w)
			half_w = I64.to_f64(I64.div_trunc_by(gv.gv_w, 2))
			half_h = I64.to_f64(I64.div_trunc_by(gv.gv_h, 2))
			{ gp_sx: (gv.gv_x + F64.to_i64_wrap((half_w + (ndc_x * half_w)))), gp_sy: (gv.gv_y + F64.to_i64_wrap((half_h - (ndc_y * half_h)))), gp_depth: F64.to_i64_wrap(((ndc_z + 1.0) * 500000.0)), gp_behind: 0 }
		}) })
	})

	gs_face_normal : Mesh.Vertex, Mesh.Vertex, Mesh.Vertex -> Quaternion.Vec3
	gs_face_normal = |v0, v1, v2| Matrix4.mat4_v3_normalize(Quaternion.vec3_new((I64.to_f64(((v0.vn_x + v1.vn_x) + v2.vn_x)) / 3.0), (I64.to_f64(((v0.vn_y + v1.vn_y) + v2.vn_y)) / 3.0), (I64.to_f64(((v0.vn_z + v1.vn_z) + v2.vn_z)) / 3.0)))

	gs_shade : Quaternion.Vec3, Quaternion.Vec3, Quaternion.Vec3, Material.EngineMaterial, List(Scene3D.Light3D), I64 -> Color.Rgb
	gs_shade = |center, normal, eye, mat, lights, ambient| ({
		base = Color.rgb_scale(mat.emat_albedo, ambient)
		gs_accum(center, normal, eye, mat, lights, base, 0, U64.to_i64_wrap(List.len(lights)))
	})

	gs_accum : Quaternion.Vec3, Quaternion.Vec3, Quaternion.Vec3, Material.EngineMaterial, List(Scene3D.Light3D), Color.Rgb, I64, I64 -> Color.Rgb
	gs_accum = |center, normal, eye, mat, lights, acc, i, n| (if (i >= n) { acc } else { ({
		light = (List.get(lights, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		contrib = (match light {
			DirLight(dir, col, intensity) => ({
				to_light = Matrix4.mat4_v3_normalize(dir)
				ndl = gs_unit_to_milli(Quaternion.vec3_dot(normal, to_light))
				diffuse = (if (ndl > 0) { I64.div_trunc_by((ndl * mat.emat_diffuse), 1000) } else { 0 })
				reflect = gs_reflect(gs_negate(to_light), normal)
				to_eye = Matrix4.mat4_v3_normalize(Quaternion.vec3_subtract(eye, center))
				rdv = gs_unit_to_milli(Quaternion.vec3_dot(reflect, to_eye))
				spec = (if (rdv > 0) { (if (ndl > 0) { I64.div_trunc_by((gs_pow(rdv, mat.emat_shininess) * mat.emat_specular), 1000) } else { 0 }) } else { 0 })
				total = I64.div_trunc_by(((diffuse + spec) * intensity), 1000)
				Color.rgb_scale(Color.rgb_multiply(mat.emat_albedo, col), gs_clamp(total, 0, 1000))
			})
			PtLight(_pos, _col, _intensity, _radius) => Color.rgb(0, 0, 0)
			SpotLight3D(_pos, _dir, _col, _intensity, _angle, _falloff) => Color.rgb(0, 0, 0)
		})
		gs_accum(center, normal, eye, mat, lights, Color.rgb_add(acc, contrib), (i + 1), n)
	}) })

	gs_unit_to_milli : F64 -> I64
	gs_unit_to_milli = |x| F64.to_i64_wrap((x * 1000.0))

	gs_reflect : Quaternion.Vec3, Quaternion.Vec3 -> Quaternion.Vec3
	gs_reflect = |inc, n| ({
		d = Quaternion.vec3_dot(inc, n)
		Quaternion.vec3_subtract(inc, Quaternion.vec3_scale(n, (2.0 * d)))
	})

	gs_negate : Quaternion.Vec3 -> Quaternion.Vec3
	gs_negate = |v| Quaternion.vec3_new((0.0 - v.vx), (0.0 - v.vy), (0.0 - v.vz))

	gs_pow : I64, I64 -> I64
	gs_pow = |b, e| (if (e <= 0) { 1000 } else { I64.div_trunc_by((gs_pow(b, (e - 1)) * b), 1000) })

	gs_clamp : I64, I64, I64 -> I64
	gs_clamp = |v, lo, hi| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })
}
