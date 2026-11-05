## The motorcycle's physics for one step. The lean steers the bike, and it
## moves along the middle of the step's turn.
import Acceleration
import Angle
import Speed
import lib.Trig

Bike :: [].{

	## How far the bike turns in a step for each radian of lean.
	yaw_per_tilt : F64
	yaw_per_tilt = 0.1

	max_lean : Angle.Lean
	max_lean = Angle.Lean.degrees(20.0)

	## What a physics step reads and writes. It is open so that a caller's
	## larger record passes through a step with its other fields kept.
	Motion(others) : { along : F64, across : F64, yaw : Angle.Turn, speed : Speed, tilt : Angle.Lean, heading : Angle.Bearing, ..others }

	## The bike one step on, after leaning by `lean_step` and speeding up by
	## `accel`.
	simulate_rider_step : Bike.Motion(others),
	{
		lean_step : Angle.Lean,
		accel : Acceleration,
	} -> Bike.Motion(others)
	simulate_rider_step = |s, { lean_step, accel }| {
		tilt = s.tilt.plus(lean_step)
		speed = s.speed.accelerated_by(accel)
		step_length = speed.to_metres_a_step()
		turn = tilt.steer(yaw_per_tilt)
		mid = s.yaw.plus(turn.times(0.5)).to_radians()
		{
			..s,
			along: s.along + step_length * Trig.r_cos(mid),
			across: s.across + step_length * Trig.r_sin(mid),
			yaw: s.yaw.plus(turn),
			speed,
			tilt,
			heading: s.heading.plus(turn),
		}
	}

	with_tilt : Bike.Motion(others), Angle.Lean -> Bike.Motion(others)
	with_tilt = |s, tilt| { ..s, tilt }
}
