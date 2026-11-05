## The ride's clock: which step of the ride this is. It starts at zero and
## moves on by one with every step, so it is always whole.
import Steps

Clock :: U32.{

	## The clock as a ride starts.
	start : Clock
	start = Clock.(0)

	## The clock at step `number` of a ride.
	at_step : U32 -> Clock
	at_step = |number| Clock.(number)

	## The clock one step on.
	next : Clock -> Clock
	next = |Clock.(n)| Clock.(n + 1)

	## How many steps this clock is past `earlier`.
	minus : Clock, Clock -> Steps
	minus = |Clock.(n), Clock.(earlier)| Steps.of(n - earlier)

	to_f64 : Clock -> F64
	to_f64 = |Clock.(n)| n.to_f64()

	to_str : Clock -> Str
	to_str = |Clock.(n)| n.to_str()

	is_eq : _
}
