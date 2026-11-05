## How far the canvas rolls with the rider's lean. A lean inside the
## deadband leaves the canvas level.
import Angle
import Pose

CanvasRoll :: [].{

	roll_deadband : Angle.Lean
	roll_deadband = Angle.Lean.radians(0.001)

	rider_roll : Pose.RiderState -> Angle.Lean
	rider_roll = |rider| if (rider.tilt.abs() < roll_deadband) Angle.upright else rider.tilt
}
