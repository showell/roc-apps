## Safari's speeds. A speed is how many metres something covers in one step
## of the ride; the rider and the truck each hold one. An `Acceleration` is
## a type of its own, so no speed can be mistaken for one: `accelerated_by`
## takes one, and `acceleration_to` and `change_from` give one.
##
## Each operation does the plain float arithmetic its name says, so code
## moved onto this type computes exactly what it did before.
import Acceleration
import lib.DeviceMath

Speed :: F64.{

	metres_a_step : F64 -> Speed
	metres_a_step = |metres| Speed.(metres)

	to_metres_a_step : Speed -> F64
	to_metres_a_step = |Speed.(s)| s

	## Standing still.
	at_rest : Speed
	at_rest = Speed.(0.0)

	## This speed after `acceleration`, the change over one step.
	accelerated_by : Speed, Acceleration -> Speed
	accelerated_by = |Speed.(s), acceleration| Speed.(s + acceleration.to_metres_a_step_each_step())

	## The acceleration over one step that took `earlier` to this speed.
	change_from : Speed, Speed -> Acceleration
	change_from = |Speed.(s), Speed.(earlier)| Acceleration.metres_a_step_each_step(s - earlier)

	## The steady acceleration that brings this speed to `target` over
	## `within` metres.
	acceleration_to : Speed, { target : Speed, within : F64 } -> Acceleration
	acceleration_to = |Speed.(s), { target: Speed.(t), within }|
		Acceleration.metres_a_step_each_step((t * t - s * s) / (2.0 * within))

	times : Speed, F64 -> Speed
	times = |Speed.(s), factor| Speed.(s * factor)

	## How many metres this speed covers in `steps` steps.
	distance_in : Speed, F64 -> F64
	distance_in = |Speed.(s), steps| s * steps

	## How many steps this speed takes to cover `metres`.
	steps_to_cover : Speed, F64 -> F64
	steps_to_cover = |Speed.(s), metres| metres / s

	## The smaller of this speed and `other`.
	min : Speed, Speed -> Speed
	min = |Speed.(s), Speed.(other)| Speed.(DeviceMath.real_min(s, other))

	## The larger of this speed and `other`.
	max : Speed, Speed -> Speed
	max = |Speed.(s), Speed.(other)| Speed.(DeviceMath.real_max(s, other))

	is_gt : Speed, Speed -> Bool
	is_gt = |Speed.(s), Speed.(other)| s > other

	is_lt : Speed, Speed -> Bool
	is_lt = |Speed.(s), Speed.(other)| s < other

	is_lte : Speed, Speed -> Bool
	is_lte = |Speed.(s), Speed.(other)| s <= other

	is_eq : _
}
