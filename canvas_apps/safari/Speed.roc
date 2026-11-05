## Safari's speeds. A speed is how many metres something covers in one step
## of the ride; the rider and the truck each hold one. An `Acceleration` is
## a type of its own, so no speed can be mistaken for one: `accelerated_by`
## takes one, and `acceleration_to` and `change_from` give one.
##
## Each operation does the plain float arithmetic its name says, so code
## moved onto this type computes exactly what it did before.
import Acceleration
import Beats
import Distance
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

	## The steady acceleration that brings this speed to `target` within this
	## distance.
	acceleration_to : Speed, { target : Speed, within : Distance } -> Acceleration
	acceleration_to = |Speed.(s), { target: Speed.(t), within }|
		Acceleration.metres_a_step_each_step((t * t - s * s) / (2.0 * within.to_metres()))

	times : Speed, F64 -> Speed
	times = |Speed.(s), factor| Speed.(s * factor)

	## How far this speed covers in `length`, at a beat a step.
	distance_in : Speed, Beats -> Distance
	distance_in = |Speed.(s), length| Distance.metres(s * length.to_f64())

	## How many beats this speed takes to cover `distance`, at a beat a step.
	beats_to_cover : Speed, Distance -> Beats
	beats_to_cover = |Speed.(s), distance| Beats.of(distance.to_metres() / s)

	## How far this speed covers in one step.
	step_length : Speed -> Distance
	step_length = |Speed.(s)| Distance.metres(s)

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

expect Speed.metres_a_step(2.0).distance_in(Beats.of(38.0)).to_metres() == 76.0
expect Speed.at_rest.distance_in(Beats.of(38.0)).to_metres() == 0.0
expect Speed.metres_a_step(2.0).beats_to_cover(Distance.metres(5.0)).to_f64() == 2.5
expect Speed.metres_a_step(0.5).beats_to_cover(Distance.metres(5.0)).to_f64() == 10.0
expect Speed.metres_a_step(0.5).step_length().to_metres() == 0.5
