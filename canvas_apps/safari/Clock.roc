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

	## How many steps this clock is past `earlier`. A clock before `earlier` is
	## no count of steps.
	steps_since : Clock, Clock -> Steps
	steps_since = |Clock.(n), Clock.(earlier)|
		if n < earlier {
			crash "Clock.steps_since: this clock comes before the one it counts from"
		} else {
			Steps.of(n - earlier)
		}

	## The clock `length` steps on.
	plus : Clock, Steps -> Clock
	plus = |Clock.(n), length| Clock.(n + length.to_u32())

	## The clock `length` steps back. The ride's first step has none before it.
	minus : Clock, Steps -> Clock
	minus = |Clock.(n), length| {
		back = length.to_u32()
		if back > n {
			crash "Clock.minus: the ride starts at step 0, and nothing comes before it"
		} else {
			Clock.(n - back)
		}
	}

	is_lt : Clock, Clock -> Bool
	is_lt = |Clock.(n), Clock.(other)| n < other

	to_str : Clock -> Str
	to_str = |Clock.(n)| n.to_str()

	is_eq : _
}

expect Clock.at_step(9).steps_since(Clock.at_step(9)) == Steps.zero
expect Clock.at_step(9).steps_since(Clock.at_step(8)) == Steps.one_step
expect Clock.at_step(9).steps_since(Clock.start) == Steps.of(9)
expect Clock.start.next().steps_since(Clock.start) == Steps.one_step
expect Clock.start.plus(Steps.zero) == Clock.start
expect Clock.at_step(9).plus(Steps.of(3)) == Clock.at_step(12)
expect Clock.at_step(9).minus(Steps.zero) == Clock.at_step(9)
expect Clock.at_step(9).minus(Steps.of(3)) == Clock.at_step(6)
expect Clock.at_step(9).minus(Steps.of(9)) == Clock.start
expect Clock.at_step(8) < Clock.at_step(9)
expect !(Clock.at_step(9) < Clock.at_step(9))
expect !(Clock.at_step(10) < Clock.at_step(9))
