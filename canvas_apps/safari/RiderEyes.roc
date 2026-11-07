## Where the rider's eyes are: the look away from the way the motorcycle
## points, and how far into a look the rider has gone.
import Angle
import Fraction

## The rider's eyes at one step. `gaze_yaw` is the look away from the way the
## motorcycle points, and `look_depth` how far into a look the rider has gone,
## which outlasts the look.
RiderEyes := { gaze_yaw : Angle.Turn, look_depth : Fraction }.{

	initial : RiderEyes
	initial = { gaze_yaw: Angle.straight_ahead, look_depth: Fraction.zero }

	is_eq : _
}
