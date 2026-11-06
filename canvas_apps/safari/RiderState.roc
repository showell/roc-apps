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

## The rider at one step. `along` and `across` place the bike on its
## segment, and `yaw` is its turn from the segment's axis; `heading` is
## its bearing in the world. `lean` is how far the bike tips, `gaze_yaw` the
## rider's look away from the way the bike points, and `attention` how
## closely the rider is watching something.
RiderState := {
	segment_index : World.SegmentIndex,
	along : Along,
	across : Across,
	yaw : Angle.Turn,
	speed : Speed,
	lean : Angle.Lean,
	heading : Angle.Bearing,
	gaze_yaw : Angle.Turn,
	attention : Fraction,
}.{

	initial : RiderState
	initial = {
		segment_index: World.SegmentIndex.first,
		along: Along.start,
		across: Across.middle,
		yaw: Angle.straight_ahead,
		speed: VehicleLimits.base_speed,
		lean: Angle.upright,
		heading: Angle.north,
		gaze_yaw: Angle.straight_ahead,
		attention: Fraction.zero,
	}
}

expect RiderState.initial.segment_index.to_i64() == 0
expect RiderState.initial.along.to_metres() == 0.0
expect RiderState.initial.across.to_metres() == 0.0
expect RiderState.initial.yaw.to_radians() == 0.0
expect RiderState.initial.speed.to_metres_a_step() == 0.3
expect RiderState.initial.lean.to_radians() == 0.0
expect RiderState.initial.heading.to_radians() == 0.0
expect RiderState.initial.gaze_yaw.to_radians() == 0.0
expect RiderState.initial.attention.to_f64() == 0.0
