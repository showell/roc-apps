## Safari's accelerations. An acceleration is how much a speed changes over
## one step of the ride, in metres a step for each step, and a negative one
## slows the speed down. The throttle hands one from gate to gate, and `Speed`
## applies one to a speed and works one out from two.
##
## Each operation does the plain float arithmetic its name says, so code
## moved onto this type computes exactly what it did before.
Acceleration :: F64.{

	metres_a_step_each_step : F64 -> Acceleration
	metres_a_step_each_step = |metres| Acceleration.(metres)

	to_metres_a_step_each_step : Acceleration -> F64
	to_metres_a_step_each_step = |Acceleration.(a)| a

	## Holding speed.
	steady : Acceleration
	steady = Acceleration.(0.0)

	times : Acceleration, F64 -> Acceleration
	times = |Acceleration.(a), factor| Acceleration.(a * factor)

	is_gt : Acceleration, Acceleration -> Bool
	is_gt = |Acceleration.(a), Acceleration.(other)| a > other

	is_lt : Acceleration, Acceleration -> Bool
	is_lt = |Acceleration.(a), Acceleration.(other)| a < other

	is_eq : _
}
