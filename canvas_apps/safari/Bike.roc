## The motorcycle's physics for one step. The lean steers the bike, and it
## moves along the middle of the step's turn.
import Angle
import Pose
import lib.Trig

Bike :: [].{

	## How far the bike turns in a step for each radian of lean.
	yaw_per_tilt : F64
	yaw_per_tilt = 0.1

	max_lean : Angle.Lean
	max_lean = Angle.Lean.degrees(20.0)

	## The rider one step on, after leaning by `lean_step` and speeding up by
	## `accel`.
	simulate_rider_step : Pose.RiderState,
	{
		lean_step : Angle.Lean,
		accel : F64,
	} -> Pose.RiderState
	simulate_rider_step = |s, { lean_step, accel }| {
		tilt = s.tilt.plus(lean_step)
		v = s.v + accel
		turn = tilt.steer(yaw_per_tilt)
		mid = s.yaw.plus(turn.times(0.5)).to_radians()
		{
			..s,
			along: s.along + v * Trig.r_cos(mid),
			across: s.across + v * Trig.r_sin(mid),
			yaw: s.yaw.plus(turn),
			v,
			tilt,
			heading: s.heading.plus(turn),
		}
	}
}
