# The BASIC platform for the browser: bytes in, bytes out.
#
# One function. A page writes the listing and the keystrokes into the
# module's memory, calls `runIt`, and reads the transcript back out
# (host.zig). There is no model, no step and no frame: a BASIC run is a
# pure function of its listing, its keystrokes and a seed.
platform ""
	requires {} { run : List(U8), List(U8), I64 -> List(U8) }
	exposes []
	packages {}
	provides {
		"roc_run": run_for_host,
	}
	targets: {
		inputs_dir: "targets/",
		wasm32: {
			inputs: ["host.wasm", app],
			exports: ["srcPtr", "keysPtr", "runIt", "outPtr", "capacity"],
		},
	}

run_for_host = run
