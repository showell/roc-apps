# Fast Track's experiment platform: a command line in, lines out, and a real
# allocator behind it. Roc's built-in platform for a headerless app maps a
# page for every allocation and unmaps it on free, which left an arena run
# 86% in the kernel; this host allocates with the C library.
platform ""
	requires {} { main! : List(Str) => Try(_, [Exit(I8), ..]) }
	exposes [Echo]
	packages {}
	provides { "roc_main": main_for_host! }
	hosted {
		"roc_echo_line": Echo.line!,
	}
	targets: {
		inputs_dir: "targets/",
		x64musl: { inputs: ["crt1.o", "libhost.a", app, "libc.a"] },
	}

import Echo

main_for_host! : List(Str) => I8
main_for_host! = |args|
	match main!(args) {
		Ok(_) => 0
		Err(Exit(code)) => code
		Err(other) => {
			Echo.line!("Program exited with error: ${Str.inspect(other)}")
			1
		}
	}
