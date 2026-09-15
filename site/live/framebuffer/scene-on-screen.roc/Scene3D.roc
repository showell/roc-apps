# Scene3D -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Color
import Material
import Matrix4
import Maybe
import Mesh
import Prelude
import Quaternion

Scene3D :: [].{
	Transform3D : { t3_pos : Quaternion.Vec3, t3_rot : Quaternion.Quat, t3_scale : Quaternion.Vec3 }
	Camera3D : { c3_eye : Quaternion.Vec3, c3_target : Quaternion.Vec3, c3_up : Quaternion.Vec3, c3_fov : F64, c3_near : F64, c3_far : F64, c3_aspect : F64 }
	Light3D : [DirLight(Quaternion.Vec3, Color.Rgb, I64), PtLight(Quaternion.Vec3, Color.Rgb, I64, I64), SpotLight3D(Quaternion.Vec3, Quaternion.Vec3, Color.Rgb, I64, I64, I64)]
	SceneNode3D : { sn3_transform : Scene3D.Transform3D, sn3_mesh : Maybe.Maybe(Mesh.Mesh), sn3_material : Material.EngineMaterial, sn3_parent : I64, sn3_visible : Bool, sn3_tag : Str }
	Scene3DState : { s3_nodes : List(Scene3D.SceneNode3D), s3_count : I64, s3_lights : List(Scene3D.Light3D), s3_camera : Scene3D.Camera3D, s3_ambient : I64 }

	t3_identity : Scene3D.Transform3D
	t3_identity = { t3_pos: Quaternion.vec3_zero, t3_rot: Quaternion.quat_identity, t3_scale: Quaternion.vec3_new(1.0, 1.0, 1.0) }

	t3_at : F64, F64, F64 -> Scene3D.Transform3D
	t3_at = |x, y, z| { t3_pos: Quaternion.vec3_new(x, y, z), t3_rot: Quaternion.quat_identity, t3_scale: Quaternion.vec3_new(1.0, 1.0, 1.0) }

	t3_to_mat4 : Scene3D.Transform3D -> Matrix4.Mat4
	t3_to_mat4 = |t| ({
		rot_mat = Matrix4.mat4_from_quat(t.t3_rot)
		scale_mat = Matrix4.mat4_scale(t.t3_scale.vx, t.t3_scale.vy, t.t3_scale.vz)
		translate_mat = Matrix4.mat4_translate(t.t3_pos.vx, t.t3_pos.vy, t.t3_pos.vz)
		Matrix4.mat4_mul(translate_mat, Matrix4.mat4_mul(rot_mat, scale_mat))
	})

	camera3d_new : Quaternion.Vec3, Quaternion.Vec3, F64 -> Scene3D.Camera3D
	camera3d_new = |eye, target, fov| { c3_eye: eye, c3_target: target, c3_up: Quaternion.vec3_new(0.0, 1.0, 0.0), c3_fov: fov, c3_near: 100.0, c3_far: 100000.0, c3_aspect: 1.333 }

	camera3d_view : Scene3D.Camera3D -> Matrix4.Mat4
	camera3d_view = |c| Matrix4.mat4_look_at(c.c3_eye, c.c3_target, c.c3_up)

	camera3d_proj : Scene3D.Camera3D -> Matrix4.Mat4
	camera3d_proj = |c| Matrix4.mat4_perspective(c.c3_fov, c.c3_aspect, c.c3_near, c.c3_far)

	camera3d_vp : Scene3D.Camera3D -> Matrix4.Mat4
	camera3d_vp = |c| Matrix4.mat4_mul(camera3d_proj(c), camera3d_view(c))

	dir_light : Quaternion.Vec3, Color.Rgb, I64 -> Scene3D.Light3D
	dir_light = |direction, color, intensity| DirLight(direction, color, intensity)

	pt_light : Quaternion.Vec3, Color.Rgb, I64, I64 -> Scene3D.Light3D
	pt_light = |pos, color, intensity, radius| PtLight(pos, color, intensity, radius)

	sn3_new : Str -> Scene3D.SceneNode3D
	sn3_new = |tag| { sn3_transform: t3_identity, sn3_mesh: None, sn3_material: Material.emat_default, sn3_parent: (-1), sn3_visible: True, sn3_tag: tag }

	sn3_with_mesh : Str, Mesh.Mesh, Material.EngineMaterial -> Scene3D.SceneNode3D
	sn3_with_mesh = |tag, m, mat| { sn3_transform: t3_identity, sn3_mesh: Just(m), sn3_material: mat, sn3_parent: (-1), sn3_visible: True, sn3_tag: tag }

	sn3_set_pos : Scene3D.SceneNode3D, F64, F64, F64 -> Scene3D.SceneNode3D
	sn3_set_pos = |n, x, y, z| ({
		t = n.sn3_transform
		t2 = { t3_pos: Quaternion.vec3_new(x, y, z), t3_rot: t.t3_rot, t3_scale: t.t3_scale }
		{ ..n, sn3_transform: t2 }
	})

	sn3_set_rot : Scene3D.SceneNode3D, Quaternion.Quat -> Scene3D.SceneNode3D
	sn3_set_rot = |n, q| ({
		t = n.sn3_transform
		t2 = { t3_pos: t.t3_pos, t3_rot: q, t3_scale: t.t3_scale }
		{ ..n, sn3_transform: t2 }
	})

	sn3_set_scale : Scene3D.SceneNode3D, F64, F64, F64 -> Scene3D.SceneNode3D
	sn3_set_scale = |n, sx, sy, sz| ({
		t = n.sn3_transform
		t2 = { t3_pos: t.t3_pos, t3_rot: t.t3_rot, t3_scale: Quaternion.vec3_new(sx, sy, sz) }
		{ ..n, sn3_transform: t2 }
	})

	scene3d_new : Scene3D.Camera3D -> Scene3D.Scene3DState
	scene3d_new = |cam| { s3_nodes: [], s3_count: 0, s3_lights: [], s3_camera: cam, s3_ambient: 200 }

	scene3d_add : Scene3D.Scene3DState, Scene3D.SceneNode3D -> Scene3D.Scene3DState
	scene3d_add = |s, node| { s3_nodes: List.append(s.s3_nodes, node), s3_count: (s.s3_count + 1), s3_lights: s.s3_lights, s3_camera: s.s3_camera, s3_ambient: s.s3_ambient }

	scene3d_add_light : Scene3D.Scene3DState, Scene3D.Light3D -> Scene3D.Scene3DState
	scene3d_add_light = |s, light| { s3_nodes: s.s3_nodes, s3_count: s.s3_count, s3_lights: List.append(s.s3_lights, light), s3_camera: s.s3_camera, s3_ambient: s.s3_ambient }

	scene3d_set_camera : Scene3D.Scene3DState, Scene3D.Camera3D -> Scene3D.Scene3DState
	scene3d_set_camera = |s, cam| { ..s, s3_camera: cam }

	scene3d_set_ambient : Scene3D.Scene3DState, I64 -> Scene3D.Scene3DState
	scene3d_set_ambient = |s, a| { ..s, s3_ambient: a }

	scene3d_world_matrix : Scene3D.Scene3DState, I64 -> Matrix4.Mat4
	scene3d_world_matrix = |s, idx| (if (idx < 0) { Matrix4.mat4_identity } else { (if (idx >= s.s3_count) { Matrix4.mat4_identity } else { ({
		node = (List.get(s.s3_nodes, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))
		local = t3_to_mat4(node.sn3_transform)
		(if (node.sn3_parent < 0) { local } else { Matrix4.mat4_mul(scene3d_world_matrix(s, node.sn3_parent), local) })
	}) }) })

	scene3d_node_at : Scene3D.Scene3DState, I64 -> Scene3D.SceneNode3D
	scene3d_node_at = |s, idx| (List.get(s.s3_nodes, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))

	scene3d_update_node : Scene3D.Scene3DState, I64, Scene3D.SceneNode3D -> Scene3D.Scene3DState
	scene3d_update_node = |s, idx, node| (if (idx < 0) { s } else { (if (idx >= s.s3_count) { s } else { { s3_nodes: (List.set(s.s3_nodes, I64.to_u64_wrap(idx), node) ?? crash("list-set-at past the end")), s3_count: s.s3_count, s3_lights: s.s3_lights, s3_camera: s.s3_camera, s3_ambient: s.s3_ambient } }) })

	scene3d_find_tag : Scene3D.Scene3DState, Str -> I64
	scene3d_find_tag = |s, tag| s3_find_loop(s.s3_nodes, tag, 0, s.s3_count)

	s3_find_loop : List(Scene3D.SceneNode3D), Str, I64, I64 -> I64
	s3_find_loop = |nodes, tag, i, n| (if (i >= n) { (0 - 1) } else { (if ((List.get(nodes, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).sn3_tag == tag) { i } else { s3_find_loop(nodes, tag, (i + 1), n) }) })

	scene3d_count : Scene3D.Scene3DState -> I64
	scene3d_count = |s| s.s3_count

	scene3d_light_count : Scene3D.Scene3DState -> I64
	scene3d_light_count = |s| U64.to_i64_wrap(List.len(s.s3_lights))

	format_scene3d : Scene3D.Scene3DState -> Str
	format_scene3d = |s| Str.concat(Str.concat(Str.concat(Str.concat("Scene3D(", I64.to_str(s.s3_count)), " nodes, "), I64.to_str(U64.to_i64_wrap(List.len(s.s3_lights)))), " lights)")

	format_transform : Scene3D.Transform3D -> Str
	format_transform = |t| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("pos=(", Prelude.real_to_str(t.t3_pos.vx)), ","), Prelude.real_to_str(t.t3_pos.vy)), ","), Prelude.real_to_str(t.t3_pos.vz)), ")")

	eq_Light3D : Scene3D.Light3D, Scene3D.Light3D -> Bool
	eq_Light3D = |ex, ey| (match ex {
		DirLight(exf0, exf1, exf2) => (match ey {
			DirLight(eyf0, eyf1, eyf2) => (((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2))
			_ => False
		})
		PtLight(exf0, exf1, exf2, exf3) => (match ey {
			PtLight(eyf0, eyf1, eyf2, eyf3) => ((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3))
			_ => False
		})
		SpotLight3D(exf0, exf1, exf2, exf3, exf4, exf5) => (match ey {
			SpotLight3D(eyf0, eyf1, eyf2, eyf3, eyf4, eyf5) => ((((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3)) and (exf4 == eyf4)) and (exf5 == eyf5))
			_ => False
		})
	})
}
