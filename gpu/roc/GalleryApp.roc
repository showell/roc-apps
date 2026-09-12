# The gallery app: every gpushow demo behind one model.
# Written by gpu/gallery.py from the Cobblestone pages and kernels. Do not edit.
#
# A model is a demo number and its device. step(model, kernel, frame) makes
# the demo's buffers when the number changes (gallery.js names them), runs
# its passes over their gids for the frame, and remembers which buffer
# the page reads; view answers that buffer as words.
app [Model, program] { pf: platform "../wasm/platform/main.roc" }

import Device
import AlphaCoverageKernel
import BloomKernel
import BloomSceneKernel
import CpuParticlesKernel
import CubeKernel
import CubemapKernel
import DeferredKernel
import FireworksKernel
import GbufKernel
import GearsKernel
import GltfKernel
import InstancingKernel
import JuliaKernel
import MandelKernel
import MultisampleKernel
import NbodyKernel
import OcclusionKernel
import OmniShadowKernel
import ParallaxKernel
import ParticlesKernel
import PbrIblKernel
import PbrKernel
import PbrTexKernel
import PipelinesKernel
import PlasmaKernel
import RadialKernel
import RaymarchKernel
import RaytraceKernel
import ReflectKernel
import ShadowKernel
import ShadowMapKernel
import ShadowSceneKernel
import SsaoKernel
import StencilKernel
import SwarmKernel
import TexArrayKernel
import TexMipmapKernel
import TextKernel
import TextureKernel
import TriangleKernel
import VertexAttrKernel
import Seeds

Model : { kernel : I64, dev : Device.Device, out : I32 }

init : {} -> Box(Model)
init = |{}| Box.box({ kernel: -1, dev: Device.new([]), out: 0 })

view : Box(Model) -> List(U32)
view = |boxed| { m = Box.unbox(boxed)
	List.map(Device.buffer(m.dev, m.out), |v| I32.to_u32_wrap(v)) }

step : Box(Model), I64, I64 -> Box(Model)
step = |boxed, kernel, frame| {
	m = Box.unbox(boxed)
	f = I64.to_i32_wrap(frame)
	odd = I64.rem_by(frame, 2) == 1
	dev0 = if m.kernel == kernel { m.dev } else { make(kernel) }
	match kernel {
		0 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| AlphaCoverageKernel.alphacov_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		1 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| BloomSceneKernel.bloom_scene_step(d, 0, f, gid))
			dev2 = Device.dispatch(dev1, 786432, |d, gid| BloomKernel.bloom_step(d, 0, 1, f, gid))
			Box.box({ kernel: kernel, dev: dev2, out: 1 })
		})
		2 => ({
			dev1 = if odd { Device.dispatch(dev0, 14000, |d, gid| CpuParticlesKernel.cp_step(d, 1, 0, f, gid)) } else { Device.dispatch(dev0, 14000, |d, gid| CpuParticlesKernel.cp_step(d, 0, 1, f, gid)) }
			Box.box({ kernel: kernel, dev: dev1, out: (if odd { 0 } else { 1 }) })
		})
		3 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| CubeKernel.cube_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		4 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| CubemapKernel.cubemap_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		5 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| GbufKernel.gbuf_step(d, 0, 1, 2, gid))
			dev2 = Device.dispatch(dev1, 786432, |d, gid| DeferredKernel.deferred_step(d, 0, 1, 2, 3, f, gid))
			Box.box({ kernel: kernel, dev: dev2, out: 3 })
		})
		6 => ({
			dev1 = Device.dispatch(dev0, 2600, |d, gid| FireworksKernel.fw_burst_spark(d, 0, 512, 300, f, 2600, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		7 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| GearsKernel.gears_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		8 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| GltfKernel.gltf_step(d, 0, 1, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 1 })
		})
		9 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| InstancingKernel.instancing_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		10 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| JuliaKernel.julia_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		11 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| MandelKernel.mandel_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		12 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| MultisampleKernel.multisample_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		13 => ({
			dev1 = if odd { Device.dispatch(dev0, 1024, |d, gid| NbodyKernel.nbody_step(d, 1, 0, f, gid)) } else { Device.dispatch(dev0, 1024, |d, gid| NbodyKernel.nbody_step(d, 0, 1, f, gid)) }
			Box.box({ kernel: kernel, dev: dev1, out: (if odd { 0 } else { 1 }) })
		})
		14 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| OcclusionKernel.occlusion_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		15 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| OmniShadowKernel.omnishadow_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		16 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| ParallaxKernel.parallax_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		17 => ({
			dev1 = if odd { Device.dispatch(dev0, 20000, |d, gid| ParticlesKernel.particles_step(d, 1, 0, f, gid)) } else { Device.dispatch(dev0, 20000, |d, gid| ParticlesKernel.particles_step(d, 0, 1, f, gid)) }
			Box.box({ kernel: kernel, dev: dev1, out: (if odd { 0 } else { 1 }) })
		})
		18 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| PbrKernel.pbr_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		19 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| PbrIblKernel.pbribl_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		20 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| PbrTexKernel.pbrtex_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		21 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| PipelinesKernel.pipelines_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		22 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| PlasmaKernel.plasma_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		23 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| BloomSceneKernel.bloom_scene_step(d, 0, f, gid))
			dev2 = Device.dispatch(dev1, 786432, |d, gid| RadialKernel.radial_step(d, 0, 1, f, gid))
			Box.box({ kernel: kernel, dev: dev2, out: 1 })
		})
		24 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| RaymarchKernel.raymarch_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		25 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| RaytraceKernel.raytrace_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		26 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| ReflectKernel.reflect_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		27 => ({
			dev1 = Device.dispatch(dev0, 1048576, |d, gid| ShadowMapKernel.shadowmap_step(d, 0, f, gid))
			dev2 = Device.dispatch(dev1, 786432, |d, gid| ShadowSceneKernel.shadowmain_step(d, 0, 1, f, gid))
			Box.box({ kernel: kernel, dev: dev2, out: 1 })
		})
		28 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| ShadowKernel.shadow_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		29 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| GbufKernel.gbuf_step(d, 0, 1, 2, gid))
			dev2 = Device.dispatch(dev1, 786432, |d, gid| SsaoKernel.ssao_step(d, 0, 1, 2, 3, f, gid))
			Box.box({ kernel: kernel, dev: dev2, out: 3 })
		})
		30 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| StencilKernel.stencil_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		31 => ({
			dev1 = if odd { Device.dispatch(dev0, 8000, |d, gid| SwarmKernel.swarm_step(d, 1, 0, f, gid)) } else { Device.dispatch(dev0, 8000, |d, gid| SwarmKernel.swarm_step(d, 0, 1, f, gid)) }
			Box.box({ kernel: kernel, dev: dev1, out: (if odd { 0 } else { 1 }) })
		})
		32 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| TexArrayKernel.texarray_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		33 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| TexMipmapKernel.texmipmap_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		34 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| TextKernel.text_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		35 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| TextureKernel.texture_step(d, 0, 1, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 1 })
		})
		36 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| TriangleKernel.triangle_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		37 => ({
			dev1 = Device.dispatch(dev0, 786432, |d, gid| VertexAttrKernel.vertexattr_step(d, 0, f, gid))
			Box.box({ kernel: kernel, dev: dev1, out: 0 })
		})
		_ => Box.box({ kernel: kernel, dev: Device.new([]), out: 0 })
	}
}

# A demo's buffers, fresh: zeros of the size, or what the page uploads.
make : I64 -> Device.Device
make = |kernel| match kernel {
	0 => Device.new([List.repeat(0, 786432)])
	1 => Device.new([List.repeat(0, 786432), List.repeat(0, 786432)])
	2 => Device.new([Seeds.cpu_particles({}), List.repeat(0, 56000)])
	3 => Device.new([List.repeat(0, 786432)])
	4 => Device.new([List.repeat(0, 786432)])
	5 => Device.new([List.repeat(0, 786432), List.repeat(0, 786432), List.repeat(0, 786432), List.repeat(0, 786432)])
	6 => Device.new([List.repeat(0, 2600)])
	7 => Device.new([List.repeat(0, 786432)])
	8 => Device.new([Seeds.icosahedron({}), List.repeat(0, 786432)])
	9 => Device.new([List.repeat(0, 786432)])
	10 => Device.new([List.repeat(0, 786432)])
	11 => Device.new([List.repeat(0, 786432)])
	12 => Device.new([List.repeat(0, 786432)])
	13 => Device.new([Seeds.nbody({}), List.repeat(0, 4096)])
	14 => Device.new([List.repeat(0, 786432)])
	15 => Device.new([List.repeat(0, 786432)])
	16 => Device.new([List.repeat(0, 786432)])
	17 => Device.new([Seeds.particles_page({}), List.repeat(0, 80000)])
	18 => Device.new([List.repeat(0, 786432)])
	19 => Device.new([List.repeat(0, 786432)])
	20 => Device.new([List.repeat(0, 786432)])
	21 => Device.new([List.repeat(0, 786432)])
	22 => Device.new([List.repeat(0, 786432)])
	23 => Device.new([List.repeat(0, 786432), List.repeat(0, 786432)])
	24 => Device.new([List.repeat(0, 786432)])
	25 => Device.new([List.repeat(0, 786432)])
	26 => Device.new([List.repeat(0, 786432)])
	27 => Device.new([List.repeat(0, 1048576), List.repeat(0, 786432)])
	28 => Device.new([List.repeat(0, 786432)])
	29 => Device.new([List.repeat(0, 786432), List.repeat(0, 786432), List.repeat(0, 786432), List.repeat(0, 786432)])
	30 => Device.new([List.repeat(0, 786432)])
	31 => Device.new([Seeds.swarm({}), List.repeat(0, 32000)])
	32 => Device.new([List.repeat(0, 786432)])
	33 => Device.new([List.repeat(0, 786432)])
	34 => Device.new([List.repeat(0, 786432)])
	35 => Device.new([Seeds.texture({}), List.repeat(0, 786432)])
	36 => Device.new([List.repeat(0, 786432)])
	37 => Device.new([List.repeat(0, 786432)])
	_ => Device.new([])
}

program = { init, step, view }
