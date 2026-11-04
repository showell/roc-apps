## How far the canvas rolls with the rider's lean. A lean inside the
## deadband leaves the canvas level.
import lib.DeviceMath
import Pose

CanvasRoll :: [].{

	roll_deadband : F64
	roll_deadband = 0.001

	rider_roll : Pose.RiderState -> F64
	rider_roll = |rider| {
		roll = rider.tilt.to_radians()
		if (DeviceMath.real_abs(roll) < roll_deadband) 0.0 else roll
	}
}
