## Safari's accelerations. An acceleration is how much a speed changes over
## one step of the ride, in metres a step for each step, and a negative one
## slows the speed down. The throttle hands one from limit to limit, and `Speed`
## applies one to a speed and works one out from two.
Acceleration :: F64.{

	metres_a_step_each_step : F64 -> Acceleration
	metres_a_step_each_step = |metres| Acceleration.(metres)

	to_metres_a_step_each_step : Acceleration -> F64
	to_metres_a_step_each_step = |Acceleration.(acceleration)| acceleration

	## Holding speed.
	steady : Acceleration
	steady = Acceleration.(0.0)

	times : Acceleration, F64 -> Acceleration
	times = |Acceleration.(acceleration), factor| Acceleration.(acceleration * factor)

	## The smaller of this acceleration and `other`: the harder brake, or the
	## gentler push.
	min : Acceleration, Acceleration -> Acceleration
	min = |Acceleration.(acceleration), Acceleration.(other)| Acceleration.(F64.min(acceleration, other))

	is_gt : Acceleration, Acceleration -> Bool
	is_gt = |Acceleration.(acceleration), Acceleration.(other)| acceleration > other

	is_lt : Acceleration, Acceleration -> Bool
	is_lt = |Acceleration.(acceleration), Acceleration.(other)| acceleration < other

	is_eq : _
}

harder : Acceleration
harder = Acceleration.metres_a_step_each_step(-0.5)

gentler : Acceleration
gentler = Acceleration.metres_a_step_each_step(-0.25)

expect Acceleration.min(harder, gentler) == harder
expect Acceleration.min(gentler, harder) == harder
expect Acceleration.min(gentler, Acceleration.steady) == gentler
expect
	Acceleration.min(Acceleration.steady, Acceleration.metres_a_step_each_step(0.25))
		== Acceleration.steady
