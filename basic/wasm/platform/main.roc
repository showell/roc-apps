# The BASIC platform for the browser: bytes in, bytes out.
#
# One function. A page writes the listing and the keystrokes into the
# module's memory, calls `runIt`, and reads back the SCREEN and then the
# transcript (host.zig). There is no model, no step and no frame: a BASIC
# run is a pure function of its listing, its keystrokes and a seed.
#
# The screen is memory. ECMA-55 has neither PEEK nor POKE -- it is a
# teletype language whose only output is PRINT -- but every microcomputer
# BASIC had them, and on a Commodore a program draws by writing bytes to
# 1024. So the machine here carries a 64 KB address space and the page
# reads 1,000 screen codes and 1,000 colour cells straight out of it.
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
			exports: ["srcPtr", "keysPtr", "runIt", "outPtr", "capacity", "screenBytes"],
		},
	}

run_for_host = run
