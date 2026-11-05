## A whole number of the ride's steps: how long something lasts on the ride's
## clock. Two `Clock`s subtract to one.
Steps :: U32.{

	of : U32 -> Steps
	of = |count| Steps.(count)

	to_f64 : Steps -> F64
	to_f64 = |Steps.(n)| n.to_f64()

	zero : Steps
	zero = Steps.(0)

	one_step : Steps
	one_step = Steps.(1)

	plus : Steps, Steps -> Steps
	plus = |Steps.(n), Steps.(other)| Steps.(n + other)

	times : Steps, U32 -> Steps
	times = |Steps.(n), factor| Steps.(n * factor)

	## How far into a cycle of `period` steps this many steps land.
	wrapped_to : Steps, Steps -> Steps
	wrapped_to = |Steps.(n), Steps.(period)| Steps.(n % period)

	is_gt : Steps, Steps -> Bool
	is_gt = |Steps.(n), Steps.(other)| n > other

	is_gte : Steps, Steps -> Bool
	is_gte = |Steps.(n), Steps.(other)| n >= other

	is_lt : Steps, Steps -> Bool
	is_lt = |Steps.(n), Steps.(other)| n < other

	is_eq : _
}

expect Steps.zero.to_f64() == 0.0
expect Steps.one_step.to_f64() == 1.0
expect Steps.of(5).plus(Steps.of(7)).to_f64() == 12.0
expect Steps.of(37).times(3).to_f64() == 111.0
expect Steps.of(37).times(0).to_f64() == 0.0

## A count of steps wrapped to a cycle of 120.
phase_of : U32 -> F64
phase_of = |count| Steps.of(count).wrapped_to(Steps.of(120)).to_f64()

# At, just under and just over the cycle's ends.
expect phase_of(0) == 0.0
expect phase_of(1) == 1.0
expect phase_of(119) == 119.0
expect phase_of(120) == 0.0
expect phase_of(121) == 1.0
expect phase_of(239) == 119.0
expect phase_of(240) == 0.0

expect Steps.of(3) > Steps.of(2)
expect !(Steps.of(3) > Steps.of(3))
expect Steps.of(3) >= Steps.of(3)
expect !(Steps.of(2) >= Steps.of(3))
expect Steps.of(2) < Steps.of(3)
expect !(Steps.of(3) < Steps.of(3))
expect Steps.of(3) == Steps.of(3)
expect !(Steps.of(3) == Steps.of(4))
