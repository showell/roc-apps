## The lens the ride is seen through. The view widens as the rider leans,
## and as the rider's attention is caught, by a crossing on the road or by a
## look to the side.
import Attention
import Bike
import CrossingReaction
import lib.DeviceMath
import Fraction
import Gaze
import Lens
import Pose
import World

RideFocal :: [].{

	## How strongly the crossing on the rider's segment holds their attention.
	crossing_attention : List(World.Segment), Pose.RiderState -> Attention
	crossing_attention = |world, rider|
		CrossingReaction.reaction_to(rider.segment.segment_in(world), rider).eye_pull

	## The camera's focal length for where the rider is and how they ride.
	ride_focal : List(World.Segment), Pose.RiderState -> F64
	ride_focal = |world, rider| {
		lean_frac = Fraction.clamp(
			(DeviceMath.real_abs(rider.tilt.to_radians()) / Bike.max_lean.to_radians()),
		)
		attention = crossing_attention(world, rider).max(Gaze.gaze_focus(rider.focus))
		Lens.cam_focal({ lean_frac, attention })
	}
}
