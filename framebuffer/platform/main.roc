# The framebuffer platform: a Codex program whose memory and ports the host
# keeps. Echo's shape for what it prints; Heap's doors for every byte it reads
# or writes; Port's for the GPU and the keyboard controller. The screen is the
# part of that memory UEFI's GOP protocol describes. The page runs the program
# once a frame, or, for a program that draws in a loop of its own, shows each
# GPU flush as it comes; the native host checks the same frames' hashes.
platform ""
	requires {} { main! : List(Str) => Try(_, [Exit(I8), ..]) }
	exposes [Echo, Heap, Port]
	packages {}
	provides { "roc_main": main_for_host! }
	hosted {
		"roc_echo_line": Echo.line!,
		"roc_heap_load": Heap.load!,
		"roc_heap_store": Heap.store!,
		"roc_port_in": Port.in!,
		"roc_port_out": Port.out!,
	}
	targets: {
		inputs_dir: "targets/",
		x64musl: { inputs: ["crt1.o", "libhost.a", app, "libc.a"] },
		wasm32: {
			inputs: ["host.wasm", app],
			exports: ["run", "screen", "clock", "present", "key", "mouse", "pagesMade", "consolePtr", "consoleLen", "crashPtr", "crashLen"],
		},
	}

import Echo
import Heap
import Port

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
