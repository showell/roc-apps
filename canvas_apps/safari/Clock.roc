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

expect Clock.start.to_f64() == 0.0
expect Clock.start.next().to_f64() == 1.0
expect Clock.start.next().next().to_f64() == 2.0
expect Clock.at_step(5699).next().to_f64() == 5700.0
expect Clock.at_step(0) == Clock.start
expect Clock.start.next() == Clock.at_step(1)
expect !(Clock.start == Clock.at_step(1))
expect !(Clock.at_step(7).next() == Clock.at_step(7))
expect Clock.at_step(9).minus(Clock.at_step(9)).to_f64() == 0.0
expect Clock.at_step(9).minus(Clock.at_step(8)).to_f64() == 1.0
expect Clock.at_step(9).minus(Clock.start).to_f64() == 9.0
expect Clock.start.next().minus(Clock.start).to_f64() == 1.0
expect Clock.start.to_str() == "0"
expect Clock.at_step(5700).to_str() == "5700"
