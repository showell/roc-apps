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

	## This speed after `acceleration`, the change over one step. Nothing in the
	## ride goes backwards, so a speed below zero means the braking behind it is
	## wrong.
	accelerated_by : Speed, Acceleration -> Speed
	accelerated_by = |Speed.(s), acceleration| {
		after = s + acceleration.to_metres_a_step_each_step()
		if after < 0.0 {
			crash "Speed.accelerated_by: this acceleration takes the speed below zero, so the braking behind it is wrong"
		} else {
			Speed.(after)
		}
	}

	## The steady acceleration that brings this speed to `target` within this
	## distance.
	acceleration_to : Speed, { target : Speed, within : Distance } -> Acceleration
	acceleration_to = |Speed.(s), { target: Speed.(t), within }|
		Acceleration.metres_a_step_each_step((t * t - s * s) / (2.0 * within.to_metres()))

	times : Speed, F64 -> Speed
	times = |Speed.(s), factor| Speed.(s * factor)

	## This fraction of this speed.
	scaled_by : Speed, Fraction -> Speed
	scaled_by = |Speed.(s), fraction| Speed.(s * fraction.to_f64())

	## How far this speed covers in `length`.
	distance_in : Speed, Steps -> Distance
	distance_in = |Speed.(s), length| Distance.metres(s * length.to_f64())

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

half_metre_a_step : Speed
half_metre_a_step = Speed.metres_a_step(0.5)

# Braking to a stop exactly is still a speed.
expect {
	loss = Acceleration.metres_a_step_each_step(-0.5)
	half_metre_a_step.accelerated_by(loss) == Speed.at_rest
}
