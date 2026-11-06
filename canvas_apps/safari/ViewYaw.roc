## Where the camera looks. It turns with the rider's gaze, and a little with
## the bike's lean, as a rider's head turns into a bend.
import Angle
import Chain
import Geom
import RiderState
import Scenery

ViewYaw :: [].{

	## How far the head turns for each radian of lean.
	head_yaw_frac : F64
	head_yaw_frac = 0.15

	## The camera's turn from the way the bike points.
	view_yaw_for : RiderState -> Angle.Turn
	view_yaw_for = |s| s.gaze_yaw.plus(s.tilt.steer(head_yaw_frac))

	## The camera's bearing in the world.
	heading_for : RiderState -> Angle.Bearing
	heading_for = |s| s.heading.plus(view_yaw_for(s))

	## Where the camera stands on the rider's segment, and which way it faces.
	vantage_for : RiderState -> Geom.Vantage
	vantage_for = |s| {
		along: s.along,
		across: s.across,
		yaw: s.yaw.plus(view_yaw_for(s)),
		half_width: Scenery.lane_half_width,
	}
}

expect ViewYaw.head_yaw_frac == 0.15

level : RiderState
level = RiderState.initial

looking_right : RiderState
looking_right = {
	..level,
	tilt: Angle.Lean.radians(0.125),
	heading: Angle.Bearing.radians(4.5),
	gaze_yaw: Angle.Turn.radians(0.375),
}

looking_left : RiderState
looking_left = {
	..level,
	tilt: Angle.Lean.radians(0.5),
	heading: Angle.Bearing.radians(1.0),
	gaze_yaw: Angle.Turn.radians(-0.25),
}

leaning_left : RiderState
leaning_left = {
	..level,
	tilt: Angle.Lean.radians(-0.75),
	heading: Angle.Bearing.radians(-2.0),
	gaze_yaw: Angle.Turn.radians(0.125),
}

leaning_hard : RiderState
leaning_hard = {
	..level,
	tilt: Angle.Lean.radians(1.25),
	heading: Angle.Bearing.radians(0.5),
}

expect
	[
		(level, 0.0),
		(looking_right, 0.39375),
		(looking_left, -0.175),
		(leaning_left, 0.012500000000000011),
		(leaning_hard, 0.1875),
	].all(|(state, yaw)| ViewYaw.view_yaw_for(state).to_radians() == yaw)

expect
	[
		(level, 0.0),
		(looking_right, 4.89375),
		(looking_left, 0.825),
		(leaning_left, -1.9875),
		(leaning_hard, 0.6875),
	].all(|(state, heading)| ViewYaw.heading_for(state).to_radians() == heading)
