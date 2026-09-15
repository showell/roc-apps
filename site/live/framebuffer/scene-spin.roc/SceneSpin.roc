app [main!] { pf: platform "../../../../../../showell_repos/roc-apps/framebuffer/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# SceneSpin -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Color
import Cordic
import Material
import Mem
import Mesh
import Quaternion
import Renderer3D
import Scene3D

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

fb_base : I64
fb_base = 3204448256

cell_width : I64
cell_width = 1988

cell_height : I64
cell_height = 1992

cell_stride : I64
cell_stride = 2016

cell_clock : I64
cell_clock = 2032

sky : I64
sky = Color.rgb_to_packed(Color.rgb(20, 20, 30))

scene_at : I64 -> Scene3D.Scene3DState
scene_at = |angle| ({
	ex = I64.to_f64(I64.div_trunc_by((5200 * Cordic.cordic_sin(angle)), 1000))
	ez = I64.to_f64(I64.div_trunc_by((5200 * Cordic.cordic_cos(angle)), 1000))
	cam = Scene3D.camera3d_new(Quaternion.vec3_new(ex, 2200.0, ez), Quaternion.vec3_new(0.0, 300.0, 0.0), 0.785)
	stage = Scene3D.scene3d_new(cam)
	ground = Scene3D.sn3_with_mesh("ground", Mesh.mesh_plane(3000, 3000), Material.emat_flat(Color.rgb(90, 80, 62)))
	cube = Scene3D.sn3_set_pos(Scene3D.sn3_with_mesh("cube", Mesh.mesh_cube(900), Material.emat_shiny(Color.rgb(90, 130, 210), 32)), (-900.0), 450.0, 0.0)
	pyr = Scene3D.sn3_set_pos(Scene3D.sn3_with_mesh("pyr", Mesh.mesh_pyramid(600, 1100), Material.emat_red), 1100.0, 0.0, (-300.0))
	s2 = Scene3D.scene3d_add(Scene3D.scene3d_add(Scene3D.scene3d_add(stage, ground), cube), pyr)
	key = Scene3D.dir_light(Quaternion.vec3_new((-400.0), 800.0, 400.0), Color.rgb(255, 250, 235), 850)
	Scene3D.scene3d_set_ambient(Scene3D.scene3d_add_light(s2, key), 260)
})

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(_mem7, mem__21) = ({
		(mem1, w) = Mem.load!(mem, cell_width, 0, 4)
		(mem2, h) = Mem.load!(mem1, cell_height, 0, 4)
		(mem3, stride) = Mem.load!(mem2, cell_stride, 0, 4)
		(mem4, angle) = Mem.load!(mem3, cell_clock, 0, 4)
		(mem5, tgt) = Renderer3D.r3d_target_at!(mem4, fb_base, stride, w, h, sky)
		(mem6, _d) = Renderer3D.r3d_render_into!(mem5, tgt, scene_at(angle))
		({
			(mem6, line!(Str.concat(Str.concat("camera : ", I64.to_str(angle)), " milliradians round the scene")))
		})
	})
	mem__21
	Ok({})
}
