# The gallery app: every pixel-writing gpushow demo behind one render.
# Written by gpu/gallery.py from the Cobblestone pages and kernels. Do not edit.
#
# render(kernel, frame) runs demo number `kernel` (gallery.js names them):
# its buffers, its passes in order over their gids, and the buffer the
# page reads, as packed pixels.
app [render] { pf: platform "../wasm/platform/main.roc" }

import Device
import AlphaCoverageKernel
import BloomKernel
import BloomSceneKernel
import CubeKernel
import CubemapKernel
import DeferredKernel
import GbufKernel
import GearsKernel
import GltfKernel
import InstancingKernel
import JuliaKernel
import MandelKernel
import MultisampleKernel
import OcclusionKernel
import OmniShadowKernel
import ParallaxKernel
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
import TexArrayKernel
import TexMipmapKernel
import TextKernel
import TextureKernel
import TriangleKernel
import VertexAttrKernel
import Seeds

pixels : Device.Device, I32 -> List(U32)
pixels = |dev, out| List.map(Device.buffer(dev, out), |v| I32.to_u32_wrap(v))

render : I64, I64 -> List(U32)
render = |kernel, frame| {
	f = I64.to_i32_wrap(frame)
	match kernel {
		0 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| AlphaCoverageKernel.alphacov_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		1 => ({
			dev0 = Device.new([List.repeat(0, 786432), List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| BloomSceneKernel.bloom_scene_step(d, 0, f, gid))
			dev2 = Device.dispatch(dev1, 786432, |d, gid| BloomKernel.bloom_step(d, 0, 1, f, gid))
			pixels(dev2, 1)
		})
		2 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| CubeKernel.cube_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		3 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| CubemapKernel.cubemap_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		4 => ({
			dev0 = Device.new([List.repeat(0, 786432), List.repeat(0, 786432), List.repeat(0, 786432), List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| GbufKernel.gbuf_step(d, 0, 1, 2, gid))
			dev2 = Device.dispatch(dev1, 786432, |d, gid| DeferredKernel.deferred_step(d, 0, 1, 2, 3, f, gid))
			pixels(dev2, 3)
		})
		5 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| GearsKernel.gears_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		6 => ({
			dev0 = Device.new([Seeds.icosahedron({}), List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| GltfKernel.gltf_step(d, 0, 1, f, gid))
			pixels(dev1, 1)
		})
		7 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| InstancingKernel.instancing_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		8 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| JuliaKernel.julia_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		9 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| MandelKernel.mandel_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		10 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| MultisampleKernel.multisample_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		11 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| OcclusionKernel.occlusion_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		12 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| OmniShadowKernel.omnishadow_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		13 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| ParallaxKernel.parallax_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		14 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| PbrKernel.pbr_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		15 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| PbrIblKernel.pbribl_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		16 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| PbrTexKernel.pbrtex_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		17 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| PipelinesKernel.pipelines_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		18 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| PlasmaKernel.plasma_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		19 => ({
			dev0 = Device.new([List.repeat(0, 786432), List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| BloomSceneKernel.bloom_scene_step(d, 0, f, gid))
			dev2 = Device.dispatch(dev1, 786432, |d, gid| RadialKernel.radial_step(d, 0, 1, f, gid))
			pixels(dev2, 1)
		})
		20 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| RaymarchKernel.raymarch_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		21 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| RaytraceKernel.raytrace_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		22 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| ReflectKernel.reflect_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		23 => ({
			dev0 = Device.new([List.repeat(0, 1048576), List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 1048576, |d, gid| ShadowMapKernel.shadowmap_step(d, 0, f, gid))
			dev2 = Device.dispatch(dev1, 786432, |d, gid| ShadowSceneKernel.shadowmain_step(d, 0, 1, f, gid))
			pixels(dev2, 1)
		})
		24 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| ShadowKernel.shadow_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		25 => ({
			dev0 = Device.new([List.repeat(0, 786432), List.repeat(0, 786432), List.repeat(0, 786432), List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| GbufKernel.gbuf_step(d, 0, 1, 2, gid))
			dev2 = Device.dispatch(dev1, 786432, |d, gid| SsaoKernel.ssao_step(d, 0, 1, 2, 3, f, gid))
			pixels(dev2, 3)
		})
		26 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| StencilKernel.stencil_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		27 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| TexArrayKernel.texarray_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		28 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| TexMipmapKernel.texmipmap_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		29 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| TextKernel.text_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		30 => ({
			dev0 = Device.new([Seeds.texture({}), List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| TextureKernel.texture_step(d, 0, 1, f, gid))
			pixels(dev1, 1)
		})
		31 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| TriangleKernel.triangle_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		32 => ({
			dev0 = Device.new([List.repeat(0, 786432)])
			dev1 = Device.dispatch(dev0, 786432, |d, gid| VertexAttrKernel.vertexattr_step(d, 0, f, gid))
			pixels(dev1, 0)
		})
		_ => []
	}
}
