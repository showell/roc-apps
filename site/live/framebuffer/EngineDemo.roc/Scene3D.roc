# Scene3D -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import Color
import Material
import Matrix4
import Maybe
import Mesh
import Quaternion

Scene3D :: [].{
	Transform3D := { t3_pos : Quaternion.Vec3, t3_rot : Quaternion.Quat, t3_scale : Quaternion.Vec3 }.{
		is_eq : Scene3D.Transform3D, Scene3D.Transform3D -> Bool
		is_eq = |a, b| a.t3_pos == b.t3_pos and a.t3_rot == b.t3_rot and a.t3_scale == b.t3_scale
	}
	Camera3D := { c3_eye : Quaternion.Vec3, c3_target : Quaternion.Vec3, c3_up : Quaternion.Vec3, c3_fov : F64, c3_near : F64, c3_far : F64, c3_aspect : F64 }.{
		is_eq : Scene3D.Camera3D, Scene3D.Camera3D -> Bool
		is_eq = |a, b| a.c3_eye == b.c3_eye and a.c3_target == b.c3_target and a.c3_up == b.c3_up and a.c3_fov == b.c3_fov and a.c3_near == b.c3_near and a.c3_far == b.c3_far and a.c3_aspect == b.c3_aspect
	}
	Light3D : [DirLight(Quaternion.Vec3, Color.Rgb, I64), PtLight(Quaternion.Vec3, Color.Rgb, I64, I64), SpotLight3D(Quaternion.Vec3, Quaternion.Vec3, Color.Rgb, I64, I64, I64)]
	SceneNode3D := { sn3_transform : Scene3D.Transform3D, sn3_mesh : Maybe.Maybe(Mesh.Mesh), sn3_material : Material.EngineMaterial, sn3_parent : I64, sn3_visible : Bool, sn3_tag : CceText }.{
		is_eq : Scene3D.SceneNode3D, Scene3D.SceneNode3D -> Bool
		is_eq = |a, b| a.sn3_transform == b.sn3_transform and a.sn3_mesh == b.sn3_mesh and a.sn3_material == b.sn3_material and a.sn3_parent == b.sn3_parent and a.sn3_visible == b.sn3_visible and a.sn3_tag == b.sn3_tag
	}
	Scene3DState := { s3_nodes : List(Scene3D.SceneNode3D), s3_count : I64, s3_lights : List(Scene3D.Light3D), s3_camera : Scene3D.Camera3D, s3_ambient : I64 }.{
		is_eq : Scene3D.Scene3DState, Scene3D.Scene3DState -> Bool
		is_eq = |a, b| a.s3_nodes == b.s3_nodes and a.s3_count == b.s3_count and a.s3_lights == b.s3_lights and a.s3_camera == b.s3_camera and a.s3_ambient == b.s3_ambient
	}

	t3_identity : Scene3D.Transform3D
	t3_identity = Scene3D.Transform3D.{ t3_pos: Quaternion.vec3_zero, t3_rot: Quaternion.quat_identity, t3_scale: Quaternion.vec3_new(1.0, 1.0, 1.0) }

	t3_to_mat4 : Scene3D.Transform3D -> Matrix4.Mat4
	t3_to_mat4 = |t| ({
		rot_mat = Matrix4.mat4_from_quat(t.t3_rot)
		scale_mat = Matrix4.mat4_scale(t.t3_scale.vx, t.t3_scale.vy, t.t3_scale.vz)
		translate_mat = Matrix4.mat4_translate(t.t3_pos.vx, t.t3_pos.vy, t.t3_pos.vz)
		Matrix4.mat4_mul(translate_mat, Matrix4.mat4_mul(rot_mat, scale_mat))
	})

	camera3d_new : Quaternion.Vec3, Quaternion.Vec3, F64 -> Scene3D.Camera3D
	camera3d_new = |eye, target, fov| Scene3D.Camera3D.{ c3_eye: eye, c3_target: target, c3_up: Quaternion.vec3_new(0.0, 1.0, 0.0), c3_fov: fov, c3_near: 100.0, c3_far: 100000.0, c3_aspect: 1.333 }

	camera3d_view : Scene3D.Camera3D -> Matrix4.Mat4
	camera3d_view = |c| Matrix4.mat4_look_at(c.c3_eye, c.c3_target, c.c3_up)

	camera3d_proj : Scene3D.Camera3D -> Matrix4.Mat4
	camera3d_proj = |c| Matrix4.mat4_perspective(c.c3_fov, c.c3_aspect, c.c3_near, c.c3_far)

	camera3d_vp : Scene3D.Camera3D -> Matrix4.Mat4
	camera3d_vp = |c| Matrix4.mat4_mul(camera3d_proj(c), camera3d_view(c))

	dir_light : Quaternion.Vec3, Color.Rgb, I64 -> Scene3D.Light3D
	dir_light = |direction, color, intensity| DirLight(direction, color, intensity)

	sn3_with_mesh : CceText, Mesh.Mesh, Material.EngineMaterial -> Scene3D.SceneNode3D
	sn3_with_mesh = |tag, m, mat| Scene3D.SceneNode3D.{ sn3_transform: t3_identity, sn3_mesh: Just(m), sn3_material: mat, sn3_parent: (-1), sn3_visible: True, sn3_tag: tag }

	sn3_set_pos : Scene3D.SceneNode3D, F64, F64, F64 -> Scene3D.SceneNode3D
	sn3_set_pos = |n, x, y, z| ({
		t = n.sn3_transform
		t2 = Scene3D.Transform3D.{ t3_pos: Quaternion.vec3_new(x, y, z), t3_rot: t.t3_rot, t3_scale: t.t3_scale }
		{ ..n, sn3_transform: t2 }
	})

	scene3d_new : Scene3D.Camera3D -> Scene3D.Scene3DState
	scene3d_new = |cam| Scene3D.Scene3DState.{ s3_nodes: [], s3_count: 0, s3_lights: [], s3_camera: cam, s3_ambient: 200 }

	scene3d_add : Scene3D.Scene3DState, Scene3D.SceneNode3D -> Scene3D.Scene3DState
	scene3d_add = |s, node| Scene3D.Scene3DState.{ s3_nodes: List.append(s.s3_nodes, node), s3_count: (s.s3_count + 1), s3_lights: s.s3_lights, s3_camera: s.s3_camera, s3_ambient: s.s3_ambient }

	scene3d_add_light : Scene3D.Scene3DState, Scene3D.Light3D -> Scene3D.Scene3DState
	scene3d_add_light = |s, light| Scene3D.Scene3DState.{ s3_nodes: s.s3_nodes, s3_count: s.s3_count, s3_lights: List.append(s.s3_lights, light), s3_camera: s.s3_camera, s3_ambient: s.s3_ambient }

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

	scene3d_count : Scene3D.Scene3DState -> I64
	scene3d_count = |s| s.s3_count
}
