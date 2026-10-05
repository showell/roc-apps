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

	camera3d_new : Quaternion.Vec3, Quaternion.Vec3, F64 -> Scene3D.Camera3D
	camera3d_new = |eye, target, fov| Scene3D.Camera3D.{ c3_eye: eye, c3_target: target, c3_up: Quaternion.vec3_new(0.0, 1.0, 0.0), c3_fov: fov, c3_near: 100.0, c3_far: 100000.0, c3_aspect: 1.333 }

	camera3d_view : Scene3D.Camera3D -> Matrix4.Mat4
	camera3d_view = |c| Matrix4.mat4_look_at(c.c3_eye, c.c3_target, c.c3_up)

	camera3d_proj : Scene3D.Camera3D -> Matrix4.Mat4
	camera3d_proj = |c| Matrix4.mat4_perspective(c.c3_fov, c.c3_aspect, c.c3_near, c.c3_far)

	camera3d_vp : Scene3D.Camera3D -> Matrix4.Mat4
	camera3d_vp = |c| Matrix4.mat4_mul(camera3d_proj(c), camera3d_view(c))
}
