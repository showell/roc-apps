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
