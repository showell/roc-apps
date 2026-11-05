## The rider's state from one step to the next: where on the route the bike
## is, which way it points, how fast it goes, how far it leans, and where the
## rider is looking.
import Across
import Along
import Angle
import Fraction
import Speed
import VehicleLimits
import World

Pose :: [].{

	## The rider at one step. `along` and `across` place the bike on its
	## segment, and `yaw` is its turn from the segment's axis; `heading` is
	## its bearing in the world. `tilt` is the bike's lean, `gaze_yaw` the
	## rider's look away from the way the bike points, and `focus` how
	## closely the rider is watching something.
	RiderState : {
		segment : World.SegmentIndex,
		along : Along,
		across : Across,
		yaw : Angle.Turn,
		speed : Speed,
		tilt : Angle.Lean,
		heading : Angle.Bearing,
		gaze_yaw : Angle.Turn,
		focus : Fraction,
	}

	initial_rider_state : Pose.RiderState
	initial_rider_state = {
		segment: World.SegmentIndex.first,
		along: Along.start,
		across: Across.middle,
		yaw: Angle.straight_ahead,
		speed: VehicleLimits.v_base,
		tilt: Angle.upright,
		heading: Angle.north,
		gaze_yaw: Angle.straight_ahead,
		focus: Fraction.zero,
	}
}
