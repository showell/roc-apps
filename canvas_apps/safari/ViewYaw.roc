## Where the camera looks. It turns with the rider's gaze, and a little with
## the bike's lean, as a rider's head turns into a bend.
import Angle
import Frame
import Pose
import Scenery

ViewYaw :: [].{

	## How far the head turns for each radian of lean.
	head_yaw_frac : F64
	head_yaw_frac = 0.15

	## The camera's turn from the way the bike points.
	view_yaw_for : Pose.RiderState -> Angle.Turn
	view_yaw_for = |s| s.gaze_yaw.plus(s.tilt.steer(head_yaw_frac))

	## The camera's bearing in the world.
	heading_for : Pose.RiderState -> Angle.Bearing
	heading_for = |s| s.heading.plus(view_yaw_for(s))

	pose_for : Pose.RiderState -> Frame.Pose
	pose_for = |s| {
		along: s.along,
		across: s.across,
		yaw: s.yaw.plus(view_yaw_for(s)).to_radians(),
		hw: Scenery.lane_width / 2.0,
	}
}
