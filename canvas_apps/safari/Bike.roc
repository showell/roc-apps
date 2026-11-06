## The motorcycle's physics for one step. The lean steers the bike, and it
## moves along the middle of the step's turn.
import Acceleration
import Across
import Along
import Angle
import Speed
import lib.Trig

Bike :: [].{

	## How far the bike turns in a step for each radian of lean.
	yaw_per_tilt : F64
	yaw_per_tilt = 0.1

	max_lean : Angle.Lean
	max_lean = Angle.Lean.degrees(20.0)

	## What a physics step reads and writes. It is open so that a caller's
	## larger record passes through a step with its other fields kept.
	Motion(others) : {
		along : Along,
		across : Across,
		yaw : Angle.Turn,
		speed : Speed,
		tilt : Angle.Lean,
		heading : Angle.Bearing,
		..others,
	}

	## The bike one step on, after leaning by `lean_step` and speeding up by
	## `accel`.
	simulate_rider_step : Bike.Motion(others),
	{
		lean_step : Angle.Lean,
		accel : Acceleration,
	} -> Bike.Motion(others)
	simulate_rider_step = |s, { lean_step, accel }| {
		tilt = s.tilt.plus(lean_step)
		speed = s.speed.accelerated_by(accel)
		step_length = speed.step_length()
		turn = tilt.steer(yaw_per_tilt)
		mid = s.yaw.plus(turn.times(0.5)).to_radians()
		{
			..s,
			along: s.along.plus(step_length.times(Trig.r_cos(mid))),
			across: s.across.plus(step_length.times(Trig.r_sin(mid))),
			yaw: s.yaw.plus(turn),
			speed,
			tilt,
			heading: s.heading.plus(turn),
		}
	}

	with_tilt : Bike.Motion(others), Angle.Lean -> Bike.Motion(others)
	with_tilt = |s, tilt| { ..s, tilt }
}

expect Bike.yaw_per_tilt == 0.1
expect Bike.max_lean.to_radians() == 0.3490658503988659

# Bike doesn't import Pose, and `Motion` is open, so the records here stand in
# for it: `segment`, `gaze_yaw` and `focus` are the caller's own fields.

## A rider well along a segment, leaning a little to the right.
riding = {
	segment: 3,
	along: Along.metres(120.5),
	across: Across.metres(2.25),
	yaw: Angle.Turn.radians(0.375),
	speed: Speed.metres_a_step(0.8),
	tilt: Angle.Lean.radians(0.125),
	heading: Angle.Bearing.radians(4.5),
	gaze_yaw: Angle.Turn.radians(0.625),
	focus: 0.25,
}

first_step = Bike.simulate_rider_step(
	riding,
	{ lean_step: Angle.Lean.radians(0.05), accel: Acceleration.metres_a_step_each_step(0.01) },
)

second_step = Bike.simulate_rider_step(
	first_step,
	{
		lean_step: Angle.Lean.radians(0.0 - 0.02),
		accel: Acceleration.metres_a_step_each_step(0.005),
	},
)

third_step = Bike.simulate_rider_step(
	second_step,
	{ lean_step: Angle.upright, accel: Acceleration.steady },
)

expect
	[first_step, second_step, third_step].join_map(
		|s| [
			s.yaw.to_radians(),
			s.speed.to_metres_a_step(),
			s.tilt.to_radians(),
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
expect first_step.focus == 0.25
expect third_step.gaze_yaw.to_radians() == 0.625
expect third_step.focus == 0.25
expect first_step.segment == 3
expect second_step.segment == 3
expect third_step.segment == 3

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
		tilt: Angle.upright,
		heading: Angle.north,
	}
	a = Bike.simulate_rider_step(at_start, { lean_step: Angle.upright, accel: Acceleration.steady })
	b = Bike.simulate_rider_step(
		at_start,
		{ lean_step: Angle.Lean.radians(0.5), accel: Acceleration.metres_a_step_each_step(0.25) },
	)
	[
		a.across.to_metres(),
		a.yaw.to_radians(),
		a.heading.to_radians(),
		a.tilt.to_radians(),
		a.speed.to_metres_a_step(),
		b.tilt.to_radians(),
		b.speed.to_metres_a_step(),
		b.yaw.to_radians(),
		b.heading.to_radians(),
		Bike.yaw_per_tilt,
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
	segment: 7,
	along: Along.metres(11.0),
	across: Across.metres(2.5),
	yaw: Angle.Turn.radians(0.75),
	speed: Speed.metres_a_step(3.25),
	tilt: Angle.Lean.radians(0.125),
	heading: Angle.Bearing.radians(4.5),
	gaze_yaw: Angle.Turn.radians(0.375),
	focus: 0.75,
}

numbers_of = |s| [
	s.along.to_metres(),
	s.across.to_metres(),
	s.yaw.to_radians(),
	s.speed.to_metres_a_step(),
	s.tilt.to_radians(),
	s.heading.to_radians(),
	s.gaze_yaw.to_radians(),
	s.focus,
]

leaned_once = Bike.with_tilt(probe, Angle.Lean.radians(1.5))

# `with_tilt` changes the tilt and nothing else, and the last one holds.
expect
	numbers_of(Bike.with_tilt(probe, Angle.Lean.radians(9.5)))
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

expect Bike.with_tilt(probe, Angle.Lean.radians(9.5)).segment == 7

expect
	numbers_of(Bike.with_tilt(leaned_once, Angle.Lean.radians(9.5)))
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
