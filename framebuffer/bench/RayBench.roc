# A native bench for raytrace-on-screen's trace: the demo's scene and camera,
# traced at 160 x 120 for N frames, the clock stepping 100 ms a frame.
# `render` is rt-render, shading and all; `trace` finds each pixel's closest
# hit and nothing else. Hand-written, beside the modules rocemit wrote.
#
#   framebuffer/bench/raybench.sh [frames] [trace|render]...
import Color
import Cordic
import Quaternion
import Raytracer

scene_at : I64 -> Raytracer.RtScene
scene_at = |t| {
	bob = I64.to_f64(I64.div_trunc_by((600 * Cordic.cordic_sin(t)), 1000))
	s1 = ObjSphere({ rt_center: Quaternion.vec3_new(0.0, bob, 5000.0), rt_radius: 1000.0, rt_mat: Raytracer.mat_shiny(Color.rgb_red) })
	s2 = ObjSphere({ rt_center: Quaternion.vec3_new(2000.0, 0.0, 6000.0), rt_radius: 1500.0, rt_mat: Raytracer.mat_matte(Color.rgb_green) })
	floor = ObjPlane({ rt_point: Quaternion.vec3_new(0.0, (0.0 - 1000.0), 0.0), rt_normal: Quaternion.vec3_new(0.0, 1.0, 0.0), rt_mat: Raytracer.mat_matte(Color.rgb(128, 128, 128)) })
	light = Quaternion.vec3_new((0.0 - 3000.0), 5000.0, 2000.0)
	sc = Raytracer.scene_new(light, Color.rgb_white, 200, Color.rgb(32, 32, 64))
	Raytracer.scene_add(Raytracer.scene_add(Raytracer.scene_add(sc, s1), s2), floor)
}

camera : Raytracer.RtCamera
camera = Raytracer.rt_camera_new(Quaternion.vec3_new(0.0, 0.0, 0.0), 1000)

# Every pixel's closest hit, and the sum of the whole distances hit.
trace_rows : Raytracer.RtScene, I64, I64, I64 -> I64
trace_rows = |scene, x, y, acc|
	if y >= 120 { acc }
	else if x >= 160 { trace_rows(scene, 0, y + 1, acc) }
	else {
		hit = Raytracer.rt_trace(Raytracer.rt_pixel_ray(camera, x, y, 160, 120), scene)
		d = if hit.rt_did_hit { F64.to_i64_wrap(hit.rt_dist) } else { 0 }
		trace_rows(scene, x + 1, y, I64.plus_wrap(acc, d))
	}

run : Str, I64, I64, I64 -> I64
run = |mode, n, t, acc|
	if n <= 0 { acc } else {
		scene = scene_at(t)
		got = if mode == "trace" { trace_rows(scene, 0, 0, 0) } else { List.fold(Raytracer.rt_render(scene, camera, 160, 120).fb_pixels, 0, |a, p| I64.plus_wrap(a, p)) }
		run(mode, n - 1, t + 100, I64.plus_wrap(acc, got))
	}

main! = |args| {
	n = I64.from_str(List.get(args, 0) ?? "30") ?? 30
	mode = List.get(args, 1) ?? "render"
	echo!(Str.concat(Str.concat(mode, " checksum "), Str.concat(I64.to_str(run(mode, n, 100, 0)), "\n")))
	Ok({})
}
