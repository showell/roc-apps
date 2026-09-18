# CanvasRoll -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
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
