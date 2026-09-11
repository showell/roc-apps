# ViewYaw -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Frame
import Pose
import World

ViewYaw :: [].{

	head_yaw_frac : F64
	head_yaw_frac = 0.15

	view_yaw_for : Pose.RiderState -> F64
	view_yaw_for = |s| (s.gaze_yaw + (head_yaw_frac * s.tilt))

	heading_for : Pose.RiderState -> F64
	heading_for = |s| (s.heading + view_yaw_for(s))

	pose_for : List(World.Segment), Pose.RiderState -> Frame.Pose
	pose_for = |w, s| { along: s.along, across: s.across, yaw: (s.yaw + view_yaw_for(s)), hw: ((List.get(w, I64.to_u64_wrap(s.segment)) ?? crash("list-at out of range")).width / 2.0) }
}
