# The canvas_apps platform: what a page needs from any game, over one boxed model
# the host keeps (host.zig).
#
# Eight functions, against the movie platform's fourteen. A game is not
# scrubbed, so there is no back, no skip and no scene; it does not bank a
# camera, so there is no roll. What it has instead is input -- `advance` takes
# one Input.Snapshot, flattened into numbers because the wasm edge has no
# records -- and a speaker, which `sounds` reports as a bit per tone.
platform ""
	requires {
		[Model : model] for program : {
			init : {} -> Box(model),
			advance : Box(model), U32, U32, U32, U32, F32, F32, F32 -> Box(model),
			frame : Box(model) -> List(Frame.Shape),
			release : List(Frame.Shape) -> {},
			sounds : Box(model) -> U32,
			tone_count : Box(model) -> U32,
			tone_freq : Box(model), U32 -> U32,
			tone_ms : Box(model), U32 -> U32,
			width : Box(model) -> U32,
			height : Box(model) -> U32,
			fps : Box(model) -> U32,
		}
	}
	exposes [Frame]
	packages {}
	provides {
		"roc_init": init_for_host,
		"roc_advance": advance_for_host,
		"roc_frame": frame_for_host,
		"roc_release": release_for_host,
		"roc_sounds": sounds_for_host,
		"roc_tone_count": tone_count_for_host,
		"roc_tone_freq": tone_freq_for_host,
		"roc_tone_ms": tone_ms_for_host,
		"roc_width": width_for_host,
		"roc_height": height_for_host,
		"roc_fps": fps_for_host,
	}
	targets: {
		inputs_dir: "targets/",
		wasm32: {
			inputs: ["host.wasm", app],
			exports: ["computeFrame", "advance", "sounds", "toneCount", "toneFreq", "toneMs", "width", "height", "fps"],
		},
	}

import Frame

init_for_host = program.init
advance_for_host = program.advance
frame_for_host = program.frame
release_for_host = program.release
sounds_for_host = program.sounds
tone_count_for_host = program.tone_count
tone_freq_for_host = program.tone_freq
tone_ms_for_host = program.tone_ms
width_for_host = program.width
height_for_host = program.height
fps_for_host = program.fps
