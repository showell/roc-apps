# ViewYaw -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Frame
import Pose
import Scenery

ViewYaw :: [].{

	head_yaw_frac : F64
	head_yaw_frac = 0.15

	view_yaw_for : Pose.RiderState -> F64
	view_yaw_for = |s| (s.gaze_yaw + (head_yaw_frac * s.tilt))

	heading_for : Pose.RiderState -> F64
	heading_for = |s| (s.heading + view_yaw_for(s))

	pose_for : Pose.RiderState -> Frame.Pose
	pose_for = |s| { along: s.along, across: s.across, yaw: (s.yaw + view_yaw_for(s)), hw: (Scenery.lane_width / 2.0) }
}
