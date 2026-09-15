app [main!] { pf: platform "../../../../../../showell_repos/roc-apps/framebuffer/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# ShadowSpin -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
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
sky = 1315870

shadow_map : I64
shadow_map = 256

scene_at : I64 -> Scene3D.Scene3DState
scene_at = |angle| ({
	lx = I64.to_f64(I64.div_trunc_by((566 * Cordic.cordic_sin((angle - 785))), 1000))
	lz = I64.to_f64(I64.div_trunc_by((566 * Cordic.cordic_cos((angle - 785))), 1000))
	cam = Scene3D.camera3d_new(Quaternion.vec3_new(0.0, 2600.0, 5200.0), Quaternion.vec3_new(0.0, 300.0, 0.0), 0.785)
	stage = Scene3D.scene3d_new(cam)
	ground = Scene3D.sn3_with_mesh("ground", Mesh.mesh_plane(2500, 2500), Material.emat_flat(Color.rgb(90, 80, 62)))
	cube = Scene3D.sn3_set_pos(Scene3D.sn3_with_mesh("cube", Mesh.mesh_cube(450), Material.emat_shiny(Color.rgb(90, 130, 210), 32)), 0.0, 450.0, 0.0)
	s2 = Scene3D.scene3d_add(Scene3D.scene3d_add(stage, ground), cube)
	key = Scene3D.dir_light(Quaternion.vec3_new(lx, 800.0, lz), Color.rgb(255, 250, 235), 850)
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
		(mem6, _d) = Renderer3D.r3d_render_shadowed!(mem5, tgt, scene_at(angle), shadow_map)
		({
			(mem6, line!(Str.concat(Str.concat("light : ", I64.to_str(angle)), " milliradians round the cube")))
		})
	})
	mem__21
	Ok({})
}
