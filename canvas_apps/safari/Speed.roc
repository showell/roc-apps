## Safari's speeds. A speed is how many metres something covers in one step
## of the ride; the rider and the truck each hold one. An `Acceleration` is
## a type of its own, so no speed can be mistaken for one: `accelerated_by`
## takes one, and `acceleration_to` and `change_from` give one.
##
## Each operation does the plain float arithmetic its name says, so code
## moved onto this type computes exactly what it did before.
import Acceleration
import Distance
import Steps

Speed :: F64.{

	metres_a_step : F64 -> Speed
	metres_a_step = |metres| Speed.(metres)

	to_metres_a_step : Speed -> F64
	to_metres_a_step = |Speed.(s)| s

	## Standing still.
	at_rest : Speed
	at_rest = Speed.(0.0)

	## Anything this slow counts as standing still.
	standstill : Speed
	standstill = Speed.(0.000001)

	## This speed after `acceleration`, the change over one step.
	accelerated_by : Speed, Acceleration -> Speed
	accelerated_by = |Speed.(s), acceleration| Speed.(s + acceleration.to_metres_a_step_each_step())

	## The acceleration over one step that took `earlier` to this speed.
	change_from : Speed, Speed -> Acceleration
	change_from = |Speed.(s), Speed.(earlier)| Acceleration.metres_a_step_each_step(s - earlier)

	## The steady acceleration that brings this speed to `target` within this
	## distance.
	acceleration_to : Speed, { target : Speed, within : Distance } -> Acceleration
	acceleration_to = |Speed.(s), { target: Speed.(t), within }|
		Acceleration.metres_a_step_each_step((t * t - s * s) / (2.0 * within.to_metres()))

	times : Speed, F64 -> Speed
	times = |Speed.(s), factor| Speed.(s * factor)

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

expect Speed.metres_a_step(2.0).distance_in(Steps.of(38)).to_metres() == 76.0
expect Speed.at_rest.distance_in(Steps.of(38)).to_metres() == 0.0
expect Speed.metres_a_step(0.5).step_length().to_metres() == 0.5
