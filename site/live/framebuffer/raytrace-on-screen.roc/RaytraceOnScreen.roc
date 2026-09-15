app [main!] { pf: platform "../../../../../../showell_repos/roc-apps/framebuffer/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# RaytraceOnScreen -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Color
import Cordic
import Mem
import Quaternion
import Rasterizer
import Raytracer

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

trace_w : I64
trace_w = 160

trace_h : I64
trace_h = 120

scene_at : I64 -> Raytracer.RtScene
scene_at = |t| ({
	bob = I64.to_f64(I64.div_trunc_by((600 * Cordic.cordic_sin(t)), 1000))
	s1 = ObjSphere({ rt_center: Quaternion.vec3_new(0.0, bob, 5000.0), rt_radius: 1000.0, rt_mat: Raytracer.mat_shiny(Color.rgb_red) })
	s2 = ObjSphere({ rt_center: Quaternion.vec3_new(2000.0, 0.0, 6000.0), rt_radius: 1500.0, rt_mat: Raytracer.mat_matte(Color.rgb_green) })
	floor = ObjPlane({ rt_point: Quaternion.vec3_new(0.0, (0.0 - 1000.0), 0.0), rt_normal: Quaternion.vec3_new(0.0, 1.0, 0.0), rt_mat: Raytracer.mat_matte(Color.rgb(128, 128, 128)) })
	light = Quaternion.vec3_new((0.0 - 3000.0), 5000.0, 2000.0)
	sc = Raytracer.scene_new(light, Color.rgb_white, 200, Color.rgb(32, 32, 64))
	Raytracer.scene_add(Raytracer.scene_add(Raytracer.scene_add(sc, s1), s2), floor)
})

camera : Raytracer.RtCamera
camera = Raytracer.rt_camera_new(Quaternion.vec3_new(0.0, 0.0, 0.0), 1000)

copy_cols! : Mem.Mem, Rasterizer.Framebuf, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
copy_cols! = |mem, src, stride, w, h, y, x| (if (x >= w) { (mem, 0) } else { ({
	c = Rasterizer.fb_get(src, I64.div_trunc_by((x * src.fb_width), w), I64.div_trunc_by((y * src.fb_height), h))
	(mem1, _p) = Mem.store!(mem, fb_base, (((y * stride) + x) * 4), c, 4)
	copy_cols!(mem1, src, stride, w, h, y, (x + 1))
}) })

copy_rows! : Mem.Mem, Rasterizer.Framebuf, I64, I64, I64, I64 => (Mem.Mem, I64)
copy_rows! = |mem, src, stride, w, h, y| (if (y >= h) { (mem, 0) } else { ({
	(mem1, _d) = copy_cols!(mem, src, stride, w, h, y, 0)
	copy_rows!(mem1, src, stride, w, h, (y + 1))
}) })

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(_mem6, mem__1) = ({
		(mem1, w) = Mem.load!(mem, cell_width, 0, 4)
		(mem2, h) = Mem.load!(mem1, cell_height, 0, 4)
		(mem3, stride) = Mem.load!(mem2, cell_stride, 0, 4)
		(mem4, t) = Mem.load!(mem3, cell_clock, 0, 4)
		traced = Raytracer.rt_render(scene_at(t), camera, trace_w, trace_h)
		(mem5, _d) = copy_rows!(mem4, traced, stride, w, h, 0)
		({
			(mem5, line!(Str.concat(Str.concat("clock : ", I64.to_str(t)), " ms")))
		})
	})
	mem__1
	Ok({})
}
