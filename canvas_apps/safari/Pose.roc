## The rider's state from one step to the next: where on the route the bike
## is, which way it points, how fast it goes, how far it leans, and where the
## rider is looking.
import Angle
import World

Pose :: [].{

	## The rider at one step. `along` and `across` place the bike on its
	## segment, and `yaw` is its turn from the segment's axis; `heading` is
	## its bearing in the world. `tilt` is the bike's lean, `gaze_yaw` the
	## rider's look away from the way the bike points, and `focus` how
	## closely the rider is watching something.
	RiderState : {
		segment : World.SegmentIndex,
		along : F64,
		across : F64,
		yaw : Angle.Turn,
		v : F64,
		tilt : Angle.Lean,
		heading : Angle.Bearing,
		gaze_yaw : Angle.Turn,
		focus : F64,
	}

	v_base : F64
	v_base = 0.3

	initial_rider_state : Pose.RiderState
	initial_rider_state = {
		segment: World.SegmentIndex.first,
		along: 0.0,
		across: 0.0,
		yaw: Angle.straight_ahead,
		v: v_base,
		tilt: Angle.upright,
		heading: Angle.north,
		gaze_yaw: Angle.straight_ahead,
		focus: 0.0,
	}

	with_tilt : Pose.RiderState, Angle.Lean -> Pose.RiderState
	with_tilt = |s, tilt| { ..s, tilt }
}
