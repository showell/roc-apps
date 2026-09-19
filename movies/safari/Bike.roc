# Bike -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Pose
import Trig

Bike :: [].{

	yaw_per_tilt : F64
	yaw_per_tilt = 0.1

	max_lean : F64
	max_lean = (20.0 * Trig.deg)

	simulate_rider_step : Pose.RiderState, F64, F64 -> Pose.RiderState
	simulate_rider_step = |s, tilt_step, accel| ({
		tilt = (s.tilt + tilt_step)
		v = (s.v + accel)
		heading_change = (yaw_per_tilt * tilt)
		mid = (s.yaw + (heading_change / 2.0))
		{ segment: s.segment, along: (s.along + (v * Trig.r_cos(mid))), across: (s.across + (v * Trig.r_sin(mid))), yaw: (s.yaw + heading_change), v: v, tilt: tilt, heading: (s.heading + heading_change), gaze_yaw: s.gaze_yaw, focus: s.focus }
	})
}
