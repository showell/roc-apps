## The motorcycle the rider sits on: where it is on its segment, which way it
## points, how fast it goes and how far it leans, and the physics that moves it
## a step. The lean steers the motorcycle, and it moves along the middle of the
## step's turn.
import Acceleration
import Across
import Along
import Angle
import Speed
import VehicleLimits

## The motorcycle at one step. `along` and `across` place it on its segment,
## and `yaw` is its turn from the segment's axis. `lean` is how far it tips.
Motorcycle := {
	along : Along,
	across : Across,
	yaw : Angle.Turn,
	speed : Speed,
	lean : Angle.Lean,
}.{

	initial : Motorcycle
	initial = {
		along: Along.start,
		across: Across.middle,
		yaw: Angle.straight_ahead,
		speed: VehicleLimits.starting_speed,
		lean: Angle.upright,
	}

	## What the rider sets for a step: the lean the motorcycle takes, and the
	## speed it goes.
	Controls : { lean : Angle.Lean, speed : Speed }

	## The motorcycle one step on, at the lean and speed its controls set.
	motorcycle_at_next_step : Motorcycle, Motorcycle.Controls -> Motorcycle
	motorcycle_at_next_step = |motorcycle, { lean, speed }| {
		step_length = speed.step_length()
		turn = lean.steer(turn_per_lean)
		mid = motorcycle.yaw.plus(turn.times(0.5)).to_radians()
		{
			along: motorcycle.along.plus(step_length.times(mid.cos())),
			across: motorcycle.across.plus(step_length.times(mid.sin())),
			yaw: motorcycle.yaw.plus(turn),
			speed,
			lean,
		}
	}

	## The controls that keep this motorcycle's lean and speed as they are.
	steady_controls : Motorcycle -> Motorcycle.Controls
	steady_controls = |motorcycle| { lean: motorcycle.lean, speed: motorcycle.speed }

	with_lean : Motorcycle, Angle.Lean -> Motorcycle
	with_lean = |motorcycle, lean| { ..motorcycle, lean }

	is_eq : _
}

## How far the motorcycle turns in a step for each radian of lean.
turn_per_lean : F64
turn_per_lean = 0.1

## A motorcycle well along a segment, leaning a little to the right.
riding : Motorcycle
riding = {
	along: Along.metres(120.5),
	across: Across.metres(2.25),
	yaw: Angle.Turn.radians(0.375),
	speed: Speed.metres_a_step(0.8),
	lean: Angle.Lean.radians(0.125),
}

# The first two steps change the lean and the speed a little from the step
# before, and the third keeps them.
first_step : Motorcycle
first_step = riding.motorcycle_at_next_step({
	lean: riding.lean.plus(Angle.LeanChange.radians(0.05)),
	speed: riding.speed.accelerated_by(Acceleration.metres_a_step_each_step(0.01)),
})

second_step : Motorcycle
second_step = first_step.motorcycle_at_next_step({
	lean: first_step.lean.plus(Angle.LeanChange.radians(-0.02)),
	speed: first_step.speed.accelerated_by(Acceleration.metres_a_step_each_step(0.005)),
})

third_step : Motorcycle
third_step = second_step.motorcycle_at_next_step(second_step.steady_controls())

expect
	[
		(first_step.yaw.to_radians(), 0.3925),
		(first_step.speed.to_metres_a_step(), 0.81),
		(first_step.lean.to_radians(), 0.175),
		(second_step.yaw.to_radians(), 0.40800000000000003),
		(second_step.speed.to_metres_a_step(), 0.8150000000000001),
		(second_step.lean.to_radians(), 0.155),
		(third_step.yaw.to_radians(), 0.42350000000000004),
		(third_step.speed.to_metres_a_step(), 0.8150000000000001),
		(third_step.lean.to_radians(), 0.155),
	].all(|(got, want)| got == want)

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
	a = Motorcycle.initial.motorcycle_at_next_step(Motorcycle.initial.steady_controls())
	b = Motorcycle.motorcycle_at_next_step(
		Motorcycle.initial,
		{ lean: Angle.Lean.radians(0.5), speed: Speed.metres_a_step(0.55) },
	)
	[
		(a.across.to_metres(), 0.0),
		(a.yaw.to_radians(), 0.0),
		(a.lean.to_radians(), 0.0),
		(a.speed.to_metres_a_step(), 0.3),
		(b.lean.to_radians(), 0.5),
		(b.speed.to_metres_a_step(), 0.55),
		(b.yaw.to_radians(), 0.05),
	].all(|(got, want)| got == want)
}
