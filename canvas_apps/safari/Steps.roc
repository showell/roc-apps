## A whole number of the ride's steps: how long something lasts on the ride's
## clock. `Clock.steps_since` gives the one between two `Clock`s.
Steps :: U32.{

	of : U32 -> Steps
	of = |count| Steps.(count)

	to_f64 : Steps -> F64
	to_f64 = |Steps.(n)| n.to_f64()

	to_u32 : Steps -> U32
	to_u32 = |Steps.(n)| n

	zero : Steps
	zero = Steps.(0)

	one_step : Steps
	one_step = Steps.(1)

	plus : Steps, Steps -> Steps
	plus = |Steps.(n), Steps.(other)| Steps.(n + other)

	times : Steps, U32 -> Steps
	times = |Steps.(n), factor| Steps.(n * factor)

	## This many steps as a share of `whole`.
	ratio_to : Steps, Steps -> F64
	ratio_to = |Steps.(n), Steps.(whole)| n.to_f64() / whole.to_f64()

	## The fewer of this many steps and `other`.
	min : Steps, Steps -> Steps
	min = |Steps.(n), Steps.(other)| Steps.(n.min(other))

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

expect Steps.of(3).ratio_to(Steps.of(4)) == 0.75
expect Steps.of(8).ratio_to(Steps.of(4)) == 2.0
expect Steps.of(3).min(Steps.of(4)) == Steps.of(3)
expect Steps.of(5).min(Steps.of(4)) == Steps.of(4)
expect Steps.of(4).min(Steps.of(4)) == Steps.of(4)
