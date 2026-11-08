## Safari's speeds. A speed is how many metres something covers in one step
## of the ride; the rider and the truck each hold one. An `Acceleration` is
## a type of its own, so no speed can be mistaken for one: `accelerated_by`
## takes one, and `acceleration_to` gives one.
import Acceleration
import Distance
import Fraction
import Steps

Speed :: F64.{

	## A speed of this many metres a step. Nothing in the ride goes backwards,
	## so a negative speed means the sum behind it is wrong.
	metres_a_step : F64 -> Speed
	metres_a_step = |metres|
		if metres < 0.0 {
			crash "Speed.metres_a_step: this speed is below zero, so the sum behind it is wrong"
		} else {
			Speed.(metres)
		}

	to_metres_a_step : Speed -> F64
	to_metres_a_step = |Speed.(s)| s

	## Standing still.
	at_rest : Speed
	at_rest = Speed.(0.0)

	## This speed after `acceleration`, the change over one step, or `BelowRest`
	## when that would take it below zero.
	accelerated_by_try : Speed, Acceleration -> Try(Speed, [BelowRest])
	accelerated_by_try = |Speed.(s), acceleration| {
		after = s + acceleration.to_metres_a_step_each_step()
		if after < 0.0 {
			Err(BelowRest)
		} else {
			Ok(Speed.(after))
		}
	}

	## This speed after `acceleration`, the change over one step. Nothing in the
	## ride goes backwards, so a speed below zero means the braking behind it is
	## wrong.
	accelerated_by : Speed, Acceleration -> Speed
	accelerated_by = |speed, acceleration|
		Speed.accelerated_by_try(speed, acceleration)
			?? crash "Speed.accelerated_by: this acceleration takes the speed below zero, so the braking behind it is wrong"

	## The steady acceleration that brings this speed to `target` within this
	## distance.
	acceleration_to : Speed, { target : Speed, within : Distance } -> Acceleration
	acceleration_to = |Speed.(s), { target: Speed.(t), within }|
		Acceleration.metres_a_step_each_step((t * t - s * s) / (2.0 * within.to_metres()))

	times : Speed, F64 -> Speed
	times = |Speed.(s), factor| Speed.metres_a_step(s * factor)

	## This fraction of this speed.
	scaled_by : Speed, Fraction -> Speed
	scaled_by = |Speed.(s), fraction| Speed.(s * fraction.to_f64())

	## How far this speed covers in `length`.
	distance_in : Speed, Steps -> Distance
	distance_in = |Speed.(s), length| Distance.metres(s * length.to_f64())

	## How many whole steps this speed takes to cover `distance`, a part step
	## dropped. Nothing goes backwards, and a speed at rest covers nothing, so
	## either means the sum behind it is wrong.
	steps_to_cover : Speed, Distance -> Steps
	steps_to_cover = |Speed.(s), distance| {
		metres = distance.to_metres()
		if metres < 0.0 {
			crash "Speed.steps_to_cover: this distance is below zero, so the sum behind it is wrong"
		} else if s == 0.0 {
			crash "Speed.steps_to_cover: a speed at rest covers nothing, so the sum behind it is wrong"
		} else {
			whole_steps =
				(metres / s).floor_to_u32_try()
					?? crash "Speed.steps_to_cover: more steps than a ride's clock counts"
			Steps.of(whole_steps)
		}
	}

	## How far this speed covers in one step.
	step_length : Speed -> Distance
	step_length = |Speed.(s)| Distance.metres(s)

	## The smaller of this speed and `other`.
	min : Speed, Speed -> Speed
	min = |Speed.(s), Speed.(other)| Speed.(s.min(other))

	## The larger of this speed and `other`.
	max : Speed, Speed -> Speed
	max = |Speed.(s), Speed.(other)| Speed.(s.max(other))

	is_gt : Speed, Speed -> Bool
	is_gt = |Speed.(s), Speed.(other)| s > other

	is_lt : Speed, Speed -> Bool
	is_lt = |Speed.(s), Speed.(other)| s < other

	is_lte : Speed, Speed -> Bool
	is_lte = |Speed.(s), Speed.(other)| s <= other

	is_eq : _
}

# Rest is the slowest speed, and still a speed.
expect Speed.metres_a_step(0.0) == Speed.at_rest

# A part step is dropped: just short of a whole number of steps, at it, and
# just past it.
expect
	[
		(0.0, 0),
		(9.9, 7),
		(10.0, 8),
		(10.1, 8),
	].all(
		|(metres, steps)| {
			speed = Speed.metres_a_step(1.25)
			speed.steps_to_cover(Distance.metres(metres)) == Steps.of(steps)
		},
	)

half_metre_a_step : Speed
half_metre_a_step = Speed.metres_a_step(0.5)

# Braking to rest exactly, or short of it, is a speed, and a hair harder goes
# below rest.
expect
	[
		(-0.25, Ok(Speed.metres_a_step(0.25))),
		(-0.5, Ok(Speed.at_rest)),
		(-0.5000001, Err(BelowRest)),
	].all(
		|(loss, want)| {
			acceleration = Acceleration.metres_a_step_each_step(loss)
			half_metre_a_step.accelerated_by_try(acceleration) == want
		},
	)

# Scaling by nothing is rest, and by a positive factor a speed.
expect half_metre_a_step.times(0.0) == Speed.at_rest
expect half_metre_a_step.times(3.0) == Speed.metres_a_step(1.5)
