## How far the canvas rolls with the rider's lean. A lean inside the
## deadband leaves the canvas level.
import Angle

CanvasRoll :: [].{

	roll_deadband : Angle.Lean
	roll_deadband = Angle.Lean.radians(0.001)

	rider_roll : Angle.Lean -> Angle.Lean
	rider_roll = |tilt| if (tilt.abs() < roll_deadband) Angle.upright else tilt
}

expect CanvasRoll.roll_deadband.to_radians() == 0.001

# Inside the deadband the canvas stays level; at its edge and past it, either
# way, the canvas rolls with the rider.
expect
	[
		(0.0, 0.0),
		(0.00001, 0.0),
		(0.0005, 0.0),
		(-0.0005, 0.0),
		(0.0009999, 0.0),
		(0.001, 0.001),
		(-0.001, -0.001),
		(0.002, 0.002),
		(-0.002, -0.002),
		(0.35, 0.35),
		(-0.42, -0.42),
	].all(|(tilt, roll)| CanvasRoll.rider_roll(Angle.Lean.radians(tilt)).to_radians() == roll)
