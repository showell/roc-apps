# The machine's native platform: Echo's shape (a command line in, a line out),
# with a real block device behind it. A program the machine runs here reaches
# its drives through Drive, which the host answers from files on the host --
# codex-vm's `-disk` and `-disk2`, read and written in place.
platform ""
	requires {} { main! : List(Str) => Try(_, [Exit(I8), ..]) }
	exposes [Drive, Echo]
	packages {}
	provides { "roc_main": main_for_host! }
	hosted {
		"roc_drive_open": Drive.open!,
		"roc_drive_read": Drive.read!,
		"roc_drive_sector_count": Drive.sector_count!,
		"roc_drive_write": Drive.write!,
		"roc_echo_line": Echo.line!,
	}
	targets: {
		inputs_dir: "targets/",
		x64musl: { inputs: ["crt1.o", "libhost.a", app, "libc.a"] },
	}

import Drive
import Echo

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
