# The gpu platform: the gallery is one boxed model the host keeps. step
# takes it with a demo number and the frame and answers the next model;
# view answers the words the page draws, packed 0xRRGGBB pixels or a
# particle buffer as gallery.js says. The host (host.zig) keeps the last
# view's list alive for the page.
platform ""
	requires {
		[Model : model] for program : {
			init : {} -> Box(model),
			step : Box(model), I64, I64 -> Box(model),
			view : Box(model) -> List(U32),
		}
	}
	exposes []
	packages {}
	provides {
		"roc_init": init_for_host,
		"roc_step": step_for_host,
		"roc_view": view_for_host,
	}
	targets: {
		inputs_dir: "targets/",
		wasm32: {
			inputs: ["host.wasm", app],
			exports: ["step", "view", "bufPtr"],
		},
	}

init_for_host = program.init
step_for_host = program.step
view_for_host = program.view
