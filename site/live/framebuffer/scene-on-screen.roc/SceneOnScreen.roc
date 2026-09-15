app [main!] { pf: platform "../../../../../../showell_repos/roc-apps/framebuffer/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# SceneOnScreen -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Color
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

sky : I64
sky = Color.rgb_to_packed(Color.rgb(20, 20, 30))

demo_scene : Scene3D.Scene3DState
demo_scene = ({
	cam = Scene3D.camera3d_new(Quaternion.vec3_new(0.0, 2200.0, 5200.0), Quaternion.vec3_new(0.0, 300.0, 0.0), 0.785)
	stage = Scene3D.scene3d_new(cam)
	ground = Scene3D.sn3_with_mesh("ground", Mesh.mesh_plane(3000, 3000), Material.emat_flat(Color.rgb(90, 80, 62)))
	cube = Scene3D.sn3_set_pos(Scene3D.sn3_with_mesh("cube", Mesh.mesh_cube(900), Material.emat_shiny(Color.rgb(90, 130, 210), 32)), (-900.0), 450.0, 0.0)
	pyr = Scene3D.sn3_set_pos(Scene3D.sn3_with_mesh("pyr", Mesh.mesh_pyramid(600, 1100), Material.emat_red), 1100.0, 0.0, (-300.0))
	s2 = Scene3D.scene3d_add(Scene3D.scene3d_add(Scene3D.scene3d_add(stage, ground), cube), pyr)
	key = Scene3D.dir_light(Quaternion.vec3_new((-400.0), 800.0, 400.0), Color.rgb(255, 250, 235), 850)
	Scene3D.scene3d_set_ambient(Scene3D.scene3d_add_light(s2, key), 260)
})

drawn_cols! : Mem.Mem, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
drawn_cols! = |mem, stride, w, y, x, acc| (if (x >= w) { (mem, acc) } else { ({
	(mem1, mem__21) = Mem.load!(mem, fb_base, (((y * stride) + x) * 4), 4)
	(if (mem__21 == sky) { drawn_cols!(mem1, stride, w, y, (x + 1), acc) } else { drawn_cols!(mem1, stride, w, y, (x + 1), (acc + 1)) })
}) })

drawn_rows! : Mem.Mem, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
drawn_rows! = |mem, stride, w, h, y, acc| (if (y >= h) { (mem, acc) } else { ({
	(mem1, mem__22) = drawn_cols!(mem, stride, w, y, 0, acc)
	drawn_rows!(mem1, stride, w, h, (y + 1), mem__22)
}) })

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(_mem7, mem__23) = ({
		(mem1, w) = Mem.load!(mem, cell_width, 0, 4)
		(mem2, h) = Mem.load!(mem1, cell_height, 0, 4)
		(mem3, stride) = Mem.load!(mem2, cell_stride, 0, 4)
		(mem4, tgt) = Renderer3D.r3d_target_at!(mem3, fb_base, stride, w, h, sky)
		(mem5, _d) = Renderer3D.r3d_render_into!(mem4, tgt, demo_scene)
		(mem6, drawn) = drawn_rows!(mem5, stride, w, h, 0, 0)
		({
			_ = line!(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("screen : ", I64.to_str(w)), " x "), I64.to_str(h)), ", stride "), I64.to_str(stride)))
			(mem6, line!(Str.concat(Str.concat(Str.concat(Str.concat("drawn  : ", I64.to_str(drawn)), " of "), I64.to_str((w * h))), " pixels")))
		})
	})
	mem__23
	Ok({})
}
