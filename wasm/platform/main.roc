# The movie platform: what a page needs from any movie, over one boxed model
# the host keeps (host.zig). `render` answers the frame's SHAPES, packed as
# ShapeWire lays them out; the rest is how far in it is and how the camera is
# turned.
#
# **IT USED TO BE SAFARI'S.** It required a rider's segment and tilt, a camera
# focal length, a gaze yaw, two sky colours, four numbers about the sun, and
# three about a truck -- twenty exports, of which the page bound half and used
# them to paint a country sky itself. A second movie could not have satisfied
# any of it. probe_frame and probe_expand stay for the Node smoke run, which
# times a frame's stages.
platform ""
	requires {
		[Model : model] for program : {
			init : {} -> Box(model),
			advance : Box(model) -> Box(model),
			back : Box(model) -> Box(model),
			render : Box(model) -> List(U32),
			probe_frame : Box(model) -> U32,
			probe_expand : Box(model) -> U32,
			clock : Box(model) -> U32,
			scene : Box(model) -> U32,
			roll : Box(model) -> F32,
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
		"roc_back": back_for_host,
		"roc_render": render_for_host,
		"roc_probe_frame": probe_frame_for_host,
		"roc_probe_expand": probe_expand_for_host,
		"roc_clock": clock_for_host,
		"roc_scene": scene_for_host,
		"roc_roll": roll_for_host,
		"roc_width": width_for_host,
		"roc_height": height_for_host,
		"roc_fps": fps_for_host,
	}
	targets: {
		inputs_dir: "targets/",
		wasm32: {
			inputs: ["host.wasm", app],
			exports: ["renderFrame", "probeFrame", "probeExpand", "bufPtr", "bufHighWater", "bufCap", "advance", "back", "clock", "scene", "roll", "width", "height", "fps"],
		},
	}

init_for_host = program.init
advance_for_host = program.advance
back_for_host = program.back
render_for_host = program.render
clock_for_host = program.clock
scene_for_host = program.scene
roll_for_host = program.roll

width_for_host = program.width

height_for_host = program.height

fps_for_host = program.fps
probe_frame_for_host = program.probe_frame
probe_expand_for_host = program.probe_expand
