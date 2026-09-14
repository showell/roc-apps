# The machine's batch platform for the browser: Echo's shape (a command line
# in, lines out), with the drives answered from buffers the page fills. An
# emitted Codex program runs to its end in one call, and the page reads back
# the console, the drives as the program left them, and a crash's message.
platform ""
	requires {} { main! : List(Str) => Try(_, [Exit(I8), ..]) }
	exposes [Drive, Echo, Wire]
	packages {}
	provides { "roc_main": main_for_host! }
	hosted {
		"roc_drive_open": Drive.open!,
		"roc_drive_read": Drive.read!,
		"roc_drive_sector_count": Drive.sector_count!,
		"roc_drive_write": Drive.write!,
		"roc_echo_line": Echo.line!,
		"roc_wire_frame": Wire.frame!,
	}
	targets: {
		inputs_dir: "targets/",
		wasm32: {
			inputs: ["host.wasm", app],
			exports: ["driveBuffer", "drivePtr", "driveLen", "argsBuffer", "argsCapacity", "run", "consolePtr", "consoleLen", "crashPtr", "crashLen", "wirePtr", "wireLen"],
		},
	}

import Drive
import Echo
import Wire

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
