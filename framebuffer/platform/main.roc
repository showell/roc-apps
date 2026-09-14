# The framebuffer platform: a Codex program whose memory the host keeps, run
# once per frame. Echo's shape for what it prints; Heap's doors for every byte
# it reads or writes; Gpu's for the GPU's ports. The screen is the part of that
# memory UEFI's GOP protocol describes, and the page shows it after each run.
platform ""
	requires {} { main! : List(Str) => Try(_, [Exit(I8), ..]) }
	exposes [Echo, Gpu, Heap]
	packages {}
	provides { "roc_main": main_for_host! }
	hosted {
		"roc_echo_line": Echo.line!,
		"roc_gpu_in": Gpu.in!,
		"roc_gpu_out": Gpu.out!,
		"roc_heap_load": Heap.load!,
		"roc_heap_store": Heap.store!,
	}
	targets: {
		inputs_dir: "targets/",
		x64musl: { inputs: ["crt1.o", "libhost.a", app, "libc.a"] },
		wasm32: {
			inputs: ["host.wasm", app],
			exports: ["run", "screen", "clock", "present", "pagesMade", "consolePtr", "consoleLen", "crashPtr", "crashLen"],
		},
	}

import Echo
import Gpu
import Heap

main_for_host! : List(Str) => I8
main_for_host! = |args|
	match main!(args) {
		Ok(_) => 0
		Err(Exit(code)) => code
		Err(other) => {
			Echo.line!("Program exited with error: ${Str.inspect(other)}\n")
			1
		}
	}
