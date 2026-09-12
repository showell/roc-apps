# The gallery app: every pixel-writing gpushow kernel behind one render.
# Written by gpu/gallery.py from the Cobblestone pages and kernels. Do not edit.
#
# render(kernel, frame) dispatches kernel number `kernel` (gallery.js
# names them) over its W*H gids on the CPU and answers the packed pixels.
app [render] { pf: platform "../wasm/platform/main.roc" }

import Device
import AlphaCoverageKernel
import CubeKernel
import CubemapKernel
import GearsKernel
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
import RaymarchKernel
import RaytraceKernel
import ReflectKernel
import ShadowKernel
import StencilKernel
import TexArrayKernel
import TexMipmapKernel
import TextKernel
import TriangleKernel
import VertexAttrKernel

pixels : I32, I32, (Device.Device, I32 -> (Device.Device, I32)) -> List(U32)
pixels = |w, h, kernel| {
	dev = Device.new([List.repeat(0, I32.to_u64_wrap(w * h))])
	out = Device.dispatch(dev, w * h, kernel)
	List.map(Device.buffer(out, 0), |v| I32.to_u32_wrap(v))
}

render : I64, I64 -> List(U32)
render = |kernel, frame| {
	f = I64.to_i32_wrap(frame)
	match kernel {
		0 => pixels(1024, 768, |d, gid| AlphaCoverageKernel.alphacov_step(d, 0, f, gid))
		1 => pixels(1024, 768, |d, gid| CubeKernel.cube_step(d, 0, f, gid))
		2 => pixels(1024, 768, |d, gid| CubemapKernel.cubemap_step(d, 0, f, gid))
		3 => pixels(1024, 768, |d, gid| GearsKernel.gears_step(d, 0, f, gid))
		4 => pixels(1024, 768, |d, gid| InstancingKernel.instancing_step(d, 0, f, gid))
		5 => pixels(1024, 768, |d, gid| JuliaKernel.julia_step(d, 0, f, gid))
		6 => pixels(1024, 768, |d, gid| MandelKernel.mandel_step(d, 0, f, gid))
		7 => pixels(1024, 768, |d, gid| MultisampleKernel.multisample_step(d, 0, f, gid))
		8 => pixels(1024, 768, |d, gid| OcclusionKernel.occlusion_step(d, 0, f, gid))
		9 => pixels(1024, 768, |d, gid| OmniShadowKernel.omnishadow_step(d, 0, f, gid))
		10 => pixels(1024, 768, |d, gid| ParallaxKernel.parallax_step(d, 0, f, gid))
		11 => pixels(1024, 768, |d, gid| PbrKernel.pbr_step(d, 0, f, gid))
		12 => pixels(1024, 768, |d, gid| PbrIblKernel.pbribl_step(d, 0, f, gid))
		13 => pixels(1024, 768, |d, gid| PbrTexKernel.pbrtex_step(d, 0, f, gid))
		14 => pixels(1024, 768, |d, gid| PipelinesKernel.pipelines_step(d, 0, f, gid))
		15 => pixels(1024, 768, |d, gid| PlasmaKernel.plasma_step(d, 0, f, gid))
		16 => pixels(1024, 768, |d, gid| RaymarchKernel.raymarch_step(d, 0, f, gid))
		17 => pixels(1024, 768, |d, gid| RaytraceKernel.raytrace_step(d, 0, f, gid))
		18 => pixels(1024, 768, |d, gid| ReflectKernel.reflect_step(d, 0, f, gid))
		19 => pixels(1024, 768, |d, gid| ShadowKernel.shadow_step(d, 0, f, gid))
		20 => pixels(1024, 768, |d, gid| StencilKernel.stencil_step(d, 0, f, gid))
		21 => pixels(1024, 768, |d, gid| TexArrayKernel.texarray_step(d, 0, f, gid))
		22 => pixels(1024, 768, |d, gid| TexMipmapKernel.texmipmap_step(d, 0, f, gid))
		23 => pixels(1024, 768, |d, gid| TextKernel.text_step(d, 0, f, gid))
		24 => pixels(1024, 768, |d, gid| TriangleKernel.triangle_step(d, 0, f, gid))
		25 => pixels(1024, 768, |d, gid| VertexAttrKernel.vertexattr_step(d, 0, f, gid))
		_ => []
	}
}
