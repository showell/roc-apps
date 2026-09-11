# The safari platform: the sixteen exports web/blitter.js binds, over one
# boxed model the host keeps (host.zig). probe_frame and probe_expand are
# two more, for the Node smoke run only: the command count before and after
# expansion, so the three stages of a frame can be timed apart, since a
# wasm profile has no names.
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
			rider_seg : Box(model) -> U32,
			rider_tilt : Box(model) -> F32,
			cam_focal : Box(model) -> F32,
			gaze_yaw : Box(model) -> F32,
			sky_top : Box(model) -> U32,
			sky_horizon : Box(model) -> U32,
			sun_visible : Box(model) -> U32,
			sun_x : Box(model) -> F32,
			sun_y : Box(model) -> F32,
			sun_scale : Box(model) -> F32,
			rider_v : Box(model) -> F32,
			truck_lead : Box(model) -> F32,
			truck_v : Box(model) -> F32,
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
		"roc_rider_seg": rider_seg_for_host,
		"roc_rider_tilt": rider_tilt_for_host,
		"roc_cam_focal": cam_focal_for_host,
		"roc_gaze_yaw": gaze_yaw_for_host,
		"roc_sky_top": sky_top_for_host,
		"roc_sky_horizon": sky_horizon_for_host,
		"roc_sun_visible": sun_visible_for_host,
		"roc_sun_x": sun_x_for_host,
		"roc_sun_y": sun_y_for_host,
		"roc_sun_scale": sun_scale_for_host,
		"roc_rider_v": rider_v_for_host,
		"roc_truck_lead": truck_lead_for_host,
		"roc_truck_v": truck_v_for_host,
	}
	targets: {
		inputs_dir: "targets/",
		wasm32: {
			inputs: ["host.wasm", app],
			exports: ["renderFrame", "probeFrame", "probeExpand", "bufPtr", "bufHighWater", "bufCap", "advance", "back", "clock", "riderSeg", "riderTilt", "camFocal", "gazeYaw", "skyTop", "skyHorizon", "sunVisible", "sunX", "sunY", "sunScale", "riderV", "truckLead", "truckV"],
		},
	}

init_for_host = program.init
advance_for_host = program.advance
back_for_host = program.back
render_for_host = program.render
clock_for_host = program.clock
rider_seg_for_host = program.rider_seg
rider_tilt_for_host = program.rider_tilt
cam_focal_for_host = program.cam_focal
gaze_yaw_for_host = program.gaze_yaw
sky_top_for_host = program.sky_top
sky_horizon_for_host = program.sky_horizon
sun_visible_for_host = program.sun_visible
sun_x_for_host = program.sun_x
sun_y_for_host = program.sun_y
sun_scale_for_host = program.sun_scale
rider_v_for_host = program.rider_v
truck_lead_for_host = program.truck_lead
truck_v_for_host = program.truck_v
probe_frame_for_host = program.probe_frame
probe_expand_for_host = program.probe_expand
