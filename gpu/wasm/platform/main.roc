# The gpu platform: a kernel demo is one function from the frame number to
# the pixels, packed 0xRRGGBB as the Codex kernels pack them. The host
# (host.zig) keeps the last frame's list alive for the page to read.
platform ""
	requires {} { render : I64 -> List(U32) }
	exposes []
	packages {}
	provides { "roc_render": render_for_host }
	targets: {
		inputs_dir: "targets/",
		wasm32: {
			inputs: ["host.wasm", app],
			exports: ["renderFrame", "bufPtr"],
		},
	}

render_for_host : I64 -> List(U32)
render_for_host = render
