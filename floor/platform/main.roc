# The floor: the low-level machine in zig, with the Roc above it free to be an
# operating system. Every mutable byte is the host's -- memory, the disk's
# images, the clock -- and the Roc value carries only what is genuinely
# protocol state. A transfer names an address, never a payload, so a sector
# moves inside the host the way a real controller's does.
#
# Echo's shape for what a program prints; Heap's doors for every byte it reads
# or writes; Port's for the devices the host answers at an I/O port, which is
# codex-vm's GPU and its keyboard controller; Disk's for the block device;
# Clock's for time and waiting. The screen is the part of memory UEFI's GOP
# protocol describes. floor/roc/Machine.roc stands in for the Machine rocemit
# writes, door for door, over exactly these.
platform ""
	requires {} { main! : List(Str) => Try(_, [Exit(I8), ..]) }
	exposes [Echo, Heap, Port, Disk, Clock]
	packages {}
	provides { "roc_main": main_for_host! }
	hosted {
		"roc_echo_line": Echo.line!,
		"roc_heap_load": Heap.load!,
		"roc_heap_store": Heap.store!,
		"roc_port_in": Port.in!,
		"roc_port_out": Port.out!,
		"roc_disk_select": Disk.select!,
		"roc_disk_sector_count": Disk.sector_count!,
		"roc_disk_read": Disk.read!,
		"roc_disk_write": Disk.write!,
		"roc_clock_now": Clock.now!,
		"roc_clock_wait": Clock.wait!,
	}
	targets: {
		inputs_dir: "targets/",
		x64musl: { inputs: ["crt1.o", "libhost.a", app, "libc.a"] },
		wasm32: {
			inputs: ["host.wasm", app],
			exports: ["run", "screen", "clock", "present", "key", "mouse", "wallClock", "driveBuffer", "drivePtr", "driveLen", "fault", "faultsBitten", "pagesMade", "heapLoads", "heapStores", "sectorsRead", "sectorsWritten", "consolePtr", "consoleLen", "crashPtr", "crashLen"],
		},
	}

import Echo
import Heap
import Port
import Disk
import Clock

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
