## The lens the ride is seen through. The view widens as the rider leans,
## and as the rider's attention is caught, by a cat waiting ahead or by a
## look to the side.
import Bike
import Cat
import lib.DeviceMath
import Gaze
import Lens
import Pose
import World

RideFocal :: [].{

	## How strongly a cat waiting on the rider's segment holds the rider's
	## attention; none where no cat waits.
	cat_attention : List(World.Segment), Pose.RiderState -> F64
	cat_attention = |world, rider| {
		segment = world.get(rider.segment.to_u64_wrap()) ?? crash "RideFocal.cat_attention: the rider is on a segment of the world"
		match segment.cat {
			Waits(crossing) => Cat.focus({ gap: (crossing.along - rider.along), speed: rider.v })
			NoCat => 0.0
		}
	}

	## The camera's focal length for where the rider is and how they ride.
	ride_focal : List(World.Segment), Pose.RiderState -> F64
	ride_focal = |world, rider| {
		lean_frac = DeviceMath.real_min((DeviceMath.real_abs(rider.tilt) / Bike.max_lean), 1.0)
		attention = DeviceMath.real_max(cat_attention(world, rider), Gaze.gaze_focus(rider.focus))
		Lens.cam_focal({ lean_frac, attention })
	}
}
