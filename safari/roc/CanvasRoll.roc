# CanvasRoll -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import DeviceMath
import Pose

CanvasRoll :: [].{

	roll_deadband : F64
	roll_deadband = 0.001

	rider_roll : Pose.RiderState -> F64
	rider_roll = |s| ({
		t = s.tilt
		(if (DeviceMath.real_abs(t) < roll_deadband) { 0.0 } else { t })
	})
}
