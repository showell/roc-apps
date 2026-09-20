# The arcade platform: what a page needs from any game, over one boxed model
# the host keeps (host.zig).
#
# Seven functions, against the movie platform's fourteen. A game is not
# scrubbed, so there is no back, no skip and no scene; it does not bank a
# camera, so there is no roll. What it has instead is input -- `advance` takes
# one Devices.Snapshot, flattened into numbers because the wasm edge has no
# records -- and a speaker, which `sounds` reports as a bit per tone.
platform ""
	requires {
		[Model : model] for program : {
			init : {} -> Box(model),
			advance : Box(model), U32, U32, U32, U32, F32, F32, F32 -> Box(model),
			render : Box(model) -> List(U32),
			sounds : Box(model) -> U32,
			tone_count : Box(model) -> U32,
			width : Box(model) -> U32,
			height : Box(model) -> U32,
			fps : Box(model) -> U32,
		}
	}
	exposes []
	packages {}
	provides {
		"roc_init": init_for_host,
		"roc_advance": advance_for_host,
		"roc_render": render_for_host,
		"roc_sounds": sounds_for_host,
		"roc_tone_count": tone_count_for_host,
		"roc_width": width_for_host,
		"roc_height": height_for_host,
		"roc_fps": fps_for_host,
	}
	targets: {
		inputs_dir: "targets/",
		wasm32: {
			inputs: ["host.wasm", app],
			exports: ["renderFrame", "bufPtr", "bufHighWater", "bufCap", "advance", "sounds", "toneCount", "width", "height", "fps"],
		},
	}

init_for_host = program.init
advance_for_host = program.advance
render_for_host = program.render
sounds_for_host = program.sounds
tone_count_for_host = program.tone_count
width_for_host = program.width
height_for_host = program.height
fps_for_host = program.fps
