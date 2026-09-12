# The plasma kernel as a Roc app on the gpu wasm platform (../wasm/platform):
# one export, the frame's pixels. Hand-written; PlasmaKernel is the port.
#
# Where apps/gpushow/web/plasma.html dispatches plasma_step_main over W*H
# GPU threads and a render pass reads the storage buffer back, this
# dispatches the same kernel over the same gids on the CPU and hands the
# buffer to the page, which puts it on a canvas. Same pixels, no WebGPU.
app [render] { pf: platform "../wasm/platform/main.roc" }

import Device
import PlasmaKernel

w : I32
w = 1024
h : I32
h = 768

render : I64 -> List(U32)
render = |frame| {
	f = I64.to_i32_wrap(frame)
	dev = Device.new([List.repeat(0, I32.to_u64_wrap(w * h))])
	out = Device.dispatch(dev, w * h, |d, gid| PlasmaKernel.plasma_step(d, 0, f, gid))
	List.map(Device.buffer(out, 0), |v| I32.to_u32_wrap(v))
}
