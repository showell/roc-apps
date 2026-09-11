# Pose -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Pose :: [].{
	RiderState : { segment : I64, along : F64, across : F64, yaw : F64, v : F64, tilt : F64, heading : F64, gaze_yaw : F64, focus : F64 }

	v_base : F64
	v_base = 0.3

	initial_rider_state : Pose.RiderState
	initial_rider_state = { segment: 0, along: 0.0, across: 0.0, yaw: 0.0, v: v_base, tilt: 0.0, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }

	with_tilt : Pose.RiderState, F64 -> Pose.RiderState
	with_tilt = |s, t| { segment: s.segment, along: s.along, across: s.across, yaw: s.yaw, v: s.v, tilt: t, heading: s.heading, gaze_yaw: s.gaze_yaw, focus: s.focus }
}
