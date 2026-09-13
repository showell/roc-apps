# The machine platform for the browser: one boxed model and five doors.
#
# The page loads a disk image into the host's buffer and asks for a machine
# over it, steps it a budget of operations a frame, hands it keys, and reads
# a view back: status, the console, the devices, the memory a read landed on.
platform ""
	requires {
		[Model : model] for program : {
			new : List(U8) -> Box(model),
			step : Box(model), I64 -> Box(model),
			key : Box(model), I64 -> Box(model),
			view : Box(model) -> List(U8),
			drop : Box(model) -> {},
		}
	}
	exposes []
	packages {}
	provides {
		"roc_new": new_for_host,
		"roc_step": step_for_host,
		"roc_key": key_for_host,
		"roc_view": view_for_host,
		"roc_drop": drop_for_host,
	}
	targets: {
		inputs_dir: "targets/",
		wasm32: {
			inputs: ["host.wasm", app],
			exports: ["diskPtr", "diskCapacity", "newMachine", "step", "key", "view", "outPtr", "outLen"],
		},
	}

new_for_host = program.new
step_for_host = program.step
key_for_host = program.key
view_for_host = program.view
drop_for_host = program.drop
