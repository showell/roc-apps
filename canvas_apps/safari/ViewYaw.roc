## Where the camera looks. It turns with the rider's gaze, and a little with
## the motorcycle's lean, as a rider's head turns into a bend.
import Angle
import Geom
import Motorcycle
import RiderState

ViewYaw :: [].{

	## The camera's bearing in the world.
	heading_for : RiderState -> Angle.Bearing
	heading_for = |s| s.motorcycle.heading.plus(view_yaw_for(s))

	## Where the camera stands on the rider's segment, and which way it faces.
	vantage_for : RiderState -> Geom.Vantage
	vantage_for = |s| {
		along: s.motorcycle.along,
		across: s.motorcycle.across,
		yaw: s.motorcycle.yaw.plus(view_yaw_for(s)),
	}
}

## How far the head turns for each radian of lean.
head_turn_per_lean : F64
head_turn_per_lean = 0.15

## The camera's turn from the way the motorcycle points.
view_yaw_for : RiderState -> Angle.Turn
view_yaw_for = |s| s.eyes.gaze_yaw.plus(s.motorcycle.lean.steer(head_turn_per_lean))

expect head_turn_per_lean == 0.15

## A rider leaning `lean_radians`, on `heading_radians`, looking `gaze_radians`
## from the way the motorcycle points.
rider : {
	lean_radians : F64,
	heading_radians : F64,
	gaze_radians : F64,
} -> RiderState
rider = |{ lean_radians, heading_radians, gaze_radians }| {
	..RiderState.initial,
	motorcycle: {
		..Motorcycle.initial,
		lean: Angle.Lean.radians(lean_radians),
		heading: Angle.Bearing.radians(heading_radians),
	},
	eyes: { ..RiderState.initial.eyes, gaze_yaw: Angle.Turn.radians(gaze_radians) },
}

level : RiderState
level = RiderState.initial

looking_right : RiderState
looking_right = rider({
	lean_radians: 0.125,
	heading_radians: 4.5,
	gaze_radians: 0.375,
})

looking_left : RiderState
looking_left = rider({
	lean_radians: 0.5,
	heading_radians: 1.0,
	gaze_radians: -0.25,
})

leaning_left : RiderState
leaning_left = rider({
	lean_radians: -0.75,
	heading_radians: -2.0,
	gaze_radians: 0.125,
})

leaning_hard : RiderState
leaning_hard = rider({
	lean_radians: 1.25,
	heading_radians: 0.5,
	gaze_radians: 0.0,
})

expect
	[
		(level, 0.0),
		(looking_right, 0.39375),
		(looking_left, -0.175),
		(leaning_left, 0.012500000000000011),
		(leaning_hard, 0.1875),
	].all(|(state, yaw)| view_yaw_for(state).to_radians() == yaw)

expect
	[
		(level, 0.0),
		(looking_right, 4.89375),
		(looking_left, 0.825),
		(leaning_left, -1.9875),
		(leaning_hard, 0.6875),
	].all(|(state, heading)| ViewYaw.heading_for(state).to_radians() == heading)
