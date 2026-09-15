app [main!] { pf: platform "../../../../../../showell_repos/roc-apps/framebuffer/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# EngineDemo -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Color
import GpuScene
import Machine
import Material
import Mesh
import Quaternion
import Scene3D

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

sw : I64
sw = 640

sh : I64
sh = 480

kb_addr : I64
kb_addr = 28680

demo_main! : Machine.Machine, I64 => (Machine.Machine, Str)
demo_main! = |machine, _dummy| ({
	scene = demo_build_scene
	demo_loop!(machine, scene, 0, 300, 6000, 0)
})

demo_build_scene : Scene3D.Scene3DState
demo_build_scene = ({
	cam = Scene3D.camera3d_new(Quaternion.vec3_new(0.0, 3000.0, 6000.0), Quaternion.vec3_new(0.0, 500.0, 0.0), 0.785)
	scene = Scene3D.scene3d_new(cam)
	cube_node = Scene3D.sn3_set_pos(Scene3D.sn3_with_mesh("cube", Mesh.mesh_cube(600), Material.emat_shiny(Color.rgb(100, 140, 220), 32)), 0.0, 600.0, 0.0)
	ground_node = Scene3D.sn3_with_mesh("ground", Mesh.mesh_plane(4000, 4000), Material.emat_flat(Color.rgb(100, 85, 65)))
	pyr_node = Scene3D.sn3_set_pos(Scene3D.sn3_with_mesh("pyr", Mesh.mesh_pyramid(500, 900), Material.emat_red), 1800.0, 0.0, (-600.0))
	cube2_node = Scene3D.sn3_set_pos(Scene3D.sn3_with_mesh("cube2", Mesh.mesh_cube(400), Material.emat_gold), (-1500.0), 400.0, 500.0)
	pyr2_node = Scene3D.sn3_set_pos(Scene3D.sn3_with_mesh("pyr2", Mesh.mesh_pyramid(350, 600), Material.emat_shiny(Color.rgb(80, 200, 120), 16)), (-800.0), 0.0, (-1200.0))
	s2 = Scene3D.scene3d_add(Scene3D.scene3d_add(Scene3D.scene3d_add(Scene3D.scene3d_add(Scene3D.scene3d_add(scene, cube_node), ground_node), pyr_node), cube2_node), pyr2_node)
	light1 = Scene3D.dir_light(Quaternion.vec3_new((-400.0), 800.0, 400.0), Color.rgb(255, 250, 235), 850)
	light2 = Scene3D.dir_light(Quaternion.vec3_new(300.0, 500.0, (-600.0)), Color.rgb(160, 180, 220), 350)
	Scene3D.scene3d_set_ambient(Scene3D.scene3d_add_light(Scene3D.scene3d_add_light(s2, light1), light2), 250)
})

demo_view : GpuScene.GpuView
demo_view = GpuScene.gv_new(0, 0, sw, sh)

demo_sky : I64
demo_sky = 1052712

demo_gpu_render! : Machine.Machine, Scene3D.Scene3DState, I64, I64, I64 => (Machine.Machine, I64)
demo_gpu_render! = |machine, scene, yaw, pitch, dist| GpuScene.gs_render_full!(machine, Scene3D.scene3d_set_camera(scene, demo_orbit(yaw, pitch, dist)), demo_view, demo_sky)

demo_loop! : Machine.Machine, Scene3D.Scene3DState, I64, I64, I64, I64 => (Machine.Machine, Str)
demo_loop! = |machine, scene, yaw, pitch, dist, frame| ({
	(machine1, _dummy) = Machine.port_in_byte!(machine, 96)
	({
		(machine2, sc) = Machine.load!(machine1, kb_addr, 0, 1)
		(machine3, _ack) = Machine.store!(machine2, kb_addr, 0, 0, 1)
		yaw2 = (yaw + 8)
		(if (sc == 16) { (machine3, "quit") } else { ({
			y3 = (if (sc == 75) { (yaw2 - 200) } else { (if (sc == 77) { (yaw2 + 200) } else { yaw2 }) })
			p2 = (if (sc == 72) { GpuScene.gs_clamp((pitch + 100), (-700), 700) } else { (if (sc == 80) { GpuScene.gs_clamp((pitch - 100), (-700), 700) } else { pitch }) })
			d2 = (if (sc == 78) { GpuScene.gs_clamp((dist - 500), 2000, 20000) } else { (if (sc == 74) { GpuScene.gs_clamp((dist + 500), 2000, 20000) } else { dist }) })
			demo_frame!(machine3, scene, y3, p2, d2, frame)
		}) })
	})
})

demo_frame! : Machine.Machine, Scene3D.Scene3DState, I64, I64, I64, I64 => (Machine.Machine, Str)
demo_frame! = |machine, scene, yaw, pitch, dist, frame| ({
	(machine1, hp) = Machine.mark(machine)
	demo_frame_done!(machine1, scene, yaw, pitch, dist, frame, hp)
})

demo_frame_done! : Machine.Machine, Scene3D.Scene3DState, I64, I64, I64, I64, I64 => (Machine.Machine, Str)
demo_frame_done! = |machine, scene, yaw, pitch, dist, frame, hp| ({
	(machine1, _w) = demo_gpu_render!(machine, scene, yaw, pitch, dist)
	({
		(machine2, _restored) = Machine.release(machine1, hp)
		demo_loop!(machine2, scene, yaw, pitch, dist, (frame + 1))
	})
})

demo_orbit : I64, I64, I64 -> Scene3D.Camera3D
demo_orbit = |yaw, pitch, dist| ({
	sy = gpu_sin(yaw)
	cy = gpu_cos(yaw)
	sp = gpu_sin(pitch)
	cp = gpu_cos(pitch)
	Scene3D.camera3d_new(Quaternion.vec3_new(I64.to_f64(I64.div_trunc_by(((sy * cp) * dist), 1000000)), I64.to_f64(I64.div_trunc_by((sp * dist), 1000)), I64.to_f64(I64.div_trunc_by(((cy * cp) * dist), 1000000))), Quaternion.vec3_new(0.0, 500.0, 0.0), 0.785)
})

gpu_sin : I64 -> I64
gpu_sin = |raw| ({
	a = gpu_wrap(raw)
	(if (a <= 1570) { gpu_sin_core(a) } else { (if (a <= 3141) { gpu_sin_core((3141 - a)) } else { (if (a <= 4712) { (0 - gpu_sin_core((a - 3141))) } else { (0 - gpu_sin_core((6283 - a))) }) }) })
})

gpu_cos : I64 -> I64
gpu_cos = |raw| gpu_sin((raw + 1570))

gpu_sin_core : I64 -> I64
gpu_sin_core = |x| ({
	x2 = I64.div_trunc_by((x * x), 1000)
	x3 = I64.div_trunc_by((x2 * x), 1000)
	x5 = I64.div_trunc_by((x3 * x2), 1000)
	((x - I64.div_trunc_by(x3, 6)) + I64.div_trunc_by(x5, 120))
})

gpu_wrap : I64 -> I64
gpu_wrap = |a| ({
	m = (a - (I64.div_trunc_by(a, 6283) * 6283))
	(if (m < 0) { (m + 6283) } else { m })
})

# --- Entry ---

main! = |args| {
	machine = Machine.boot!(args, ["Console", "Device.Port", "Gpu.Compute", "Gpu.Memory"])
	(machine1, machine__57) = demo_main!(machine, 0)
	result = machine__57
	line!(result)
	Machine.halt!(machine1)
	Ok({})
}
