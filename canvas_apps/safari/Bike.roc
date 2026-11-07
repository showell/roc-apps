## The motorcycle's physics for one step. The lean steers the bike, and it
## moves along the middle of the step's turn.
import Acceleration
import Across
import Along
import Angle
import Speed

Bike :: [].{

	## How far the bike turns in a step for each radian of lean.
	turn_per_lean : F64
	turn_per_lean = 0.1

	## What a physics step reads and writes. It is open so that a caller's
	## larger record passes through a step with its other fields kept.
	Motion(others) : {
		along : Along,
		across : Across,
		yaw : Angle.Turn,
		speed : Speed,
		lean : Angle.Lean,
		heading : Angle.Bearing,
		..others,
	}

	## The bike one step on, after leaning by `lean_step` and speeding up by
	## `acceleration`.
	bike_motion_at_next_step : Bike.Motion(others),
	{
		lean_step : Angle.Lean,
		acceleration : Acceleration,
	} -> Bike.Motion(others)
	bike_motion_at_next_step = |s, { lean_step, acceleration }| {
		lean = s.lean.plus(lean_step)
		speed = s.speed.accelerated_by(acceleration)
		step_length = speed.step_length()
		turn = lean.steer(turn_per_lean)
		mid = s.yaw.plus(turn.times(0.5)).to_radians()
		{
			..s,
			along: s.along.plus(step_length.times(mid.cos())),
			across: s.across.plus(step_length.times(mid.sin())),
			yaw: s.yaw.plus(turn),
			speed,
			lean,
			heading: s.heading.plus(turn),
		}
	}

	with_lean : Bike.Motion(others), Angle.Lean -> Bike.Motion(others)
	with_lean = |s, lean| { ..s, lean }
}

expect Bike.turn_per_lean == 0.1

# Bike doesn't import RiderState, and `Motion` is open, so the records here stand in
# for it: `segment_index`, `gaze_yaw` and `look_depth` are the caller's own fields.

## A rider well along a segment, leaning a little to the right.
riding = {
	segment_index: 3,
	along: Along.metres(120.5),
	across: Across.metres(2.25),
	yaw: Angle.Turn.radians(0.375),
	speed: Speed.metres_a_step(0.8),
	lean: Angle.Lean.radians(0.125),
	heading: Angle.Bearing.radians(4.5),
	gaze_yaw: Angle.Turn.radians(0.625),
	look_depth: 0.25,
}

first_step = Bike.bike_motion_at_next_step(
	riding,
	{
		lean_step: Angle.Lean.radians(0.05),
		acceleration: Acceleration.metres_a_step_each_step(0.01),
	},
)

second_step = Bike.bike_motion_at_next_step(
	first_step,
	{
		lean_step: Angle.Lean.radians(-0.02),
		acceleration: Acceleration.metres_a_step_each_step(0.005),
	},
)

third_step = Bike.bike_motion_at_next_step(
	second_step,
	{ lean_step: Angle.upright, acceleration: Acceleration.steady },
)

expect
	[first_step, second_step, third_step].join_map(
		|s| [
			s.yaw.to_radians(),
			s.speed.to_metres_a_step(),
			s.lean.to_radians(),
			s.heading.to_radians(),
		],
	)
		== [
			0.3925,
			0.81,
			0.175,
			4.5175,
			0.40800000000000003,
			0.8150000000000001,
			0.155,
			4.533,
			0.42350000000000004,
			0.8150000000000001,
			0.155,
			4.548500000000001,
		]

# A step keeps the caller's own fields.
expect first_step.gaze_yaw.to_radians() == 0.625
expect first_step.look_depth == 0.25
expect third_step.gaze_yaw.to_radians() == 0.625
expect third_step.look_depth == 0.25
expect first_step.segment_index == 3
expect second_step.segment_index == 3
expect third_step.segment_index == 3

# Each is within 1e-9 of its want, scaled up by a want past 1.
expect
	[
		(first_step.along.to_metres(), 121.25108639750266),
		(first_step.across.to_metres(), 2.5532642799382796),
		(second_step.along.to_metres(), 122.00167174017032),
		(second_step.across.to_metres(), 2.8708278851774045),
		(third_step.along.to_metres(), 122.7472448817898),
		(third_step.across.to_metres(), 3.1999869508214647),
	].all(|(got, want)| (got - want).abs() <= 0.000000001 * want.abs().max(1.0))

expect {
	at_start = {
		along: Along.start,
		across: Across.middle,
		yaw: Angle.straight_ahead,
		speed: Speed.metres_a_step(0.3),
		lean: Angle.upright,
		heading: Angle.north,
	}
	a = Bike.bike_motion_at_next_step(
		at_start,
		{ lean_step: Angle.upright, acceleration: Acceleration.steady },
	)
	b = Bike.bike_motion_at_next_step(
		at_start,
		{
			lean_step: Angle.Lean.radians(0.5),
			acceleration: Acceleration.metres_a_step_each_step(0.25),
		},
	)
	[
		a.across.to_metres(),
		a.yaw.to_radians(),
		a.heading.to_radians(),
		a.lean.to_radians(),
		a.speed.to_metres_a_step(),
		b.lean.to_radians(),
		b.speed.to_metres_a_step(),
		b.yaw.to_radians(),
		b.heading.to_radians(),
		Bike.turn_per_lean,
	]
		== [
			0.0,
			0.0,
			0.0,
			0.0,
			0.3,
			0.5,
			0.55,
			0.05,
			0.05,
			0.1,
		]
}

probe = {
	segment_index: 7,
	along: Along.metres(11.0),
	across: Across.metres(2.5),
	yaw: Angle.Turn.radians(0.75),
	speed: Speed.metres_a_step(3.25),
	lean: Angle.Lean.radians(0.125),
	heading: Angle.Bearing.radians(4.5),
	gaze_yaw: Angle.Turn.radians(0.375),
	look_depth: 0.75,
}

numbers_of = |s| [
	s.along.to_metres(),
	s.across.to_metres(),
	s.yaw.to_radians(),
	s.speed.to_metres_a_step(),
	s.lean.to_radians(),
	s.heading.to_radians(),
	s.gaze_yaw.to_radians(),
	s.look_depth,
]

leaned_once = Bike.with_lean(probe, Angle.Lean.radians(1.5))

# `with_lean` changes the lean and nothing else, and the last one holds.
expect
	numbers_of(Bike.with_lean(probe, Angle.Lean.radians(9.5)))
		== [
			11.0,
			2.5,
			0.75,
			3.25,
			9.5,
			4.5,
			0.375,
			0.75,
		]

expect Bike.with_lean(probe, Angle.Lean.radians(9.5)).segment_index == 7

expect
	numbers_of(Bike.with_lean(leaned_once, Angle.Lean.radians(9.5)))
		== [
			11.0,
			2.5,
			0.75,
			3.25,
			9.5,
			4.5,
			0.375,
			0.75,
		]
