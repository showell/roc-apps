## A whole number of the ride's steps: how long something lasts on the ride's
## clock. `Clock.steps_since` gives the one between two `Clock`s.
Steps :: U32.{

	of : U32 -> Steps
	of = |count| Steps.(count)

	to_f64 : Steps -> F64
	to_f64 = |Steps.(count)| count.to_f64()

	## The steps a list `count` long plays for, a step to each of its items.
	of_count : U64 -> Steps
	of_count = |count| Steps.(count.to_u32_try() ?? crash "Steps.of_count: an animation is fewer than 2^32 steps long")

	to_u32 : Steps -> U32
	to_u32 = |Steps.(count)| count

	to_u64 : Steps -> U64
	to_u64 = |Steps.(count)| count.to_u64()

	zero : Steps
	zero = Steps.(0)

	one_step : Steps
	one_step = Steps.(1)

	plus : Steps, Steps -> Steps
	plus = |Steps.(count), Steps.(other)| Steps.(count + other)

	times : Steps, U32 -> Steps
	times = |Steps.(count), factor| Steps.(count * factor)

	## This many steps as a share of `whole`.
	ratio_to : Steps, Steps -> F64
	ratio_to = |Steps.(count), Steps.(whole)| count.to_f64() / whole.to_f64()

	## The fewer of this many steps and `other`.
	min : Steps, Steps -> Steps
	min = |Steps.(count), Steps.(other)| Steps.(U32.min(count, other))

	## How far into a cycle of `period` steps this many steps land.
	wrapped_to : Steps, Steps -> Steps
	wrapped_to = |Steps.(count), Steps.(period)| Steps.(count % period)

	is_gt : Steps, Steps -> Bool
	is_gt = |Steps.(count), Steps.(other)| count > other

	is_gte : Steps, Steps -> Bool
	is_gte = |Steps.(count), Steps.(other)| count >= other

	is_lt : Steps, Steps -> Bool
	is_lt = |Steps.(count), Steps.(other)| count < other

	is_eq : _
}

expect [0, 1, 38].all(|count| Steps.of_count(count).to_u64() == count)
expect Steps.of(3).ratio_to(Steps.of(4)) == 0.75
expect Steps.of(8).ratio_to(Steps.of(4)) == 2.0
expect Steps.min(Steps.of(3), Steps.of(4)) == Steps.of(3)
expect Steps.min(Steps.of(5), Steps.of(4)) == Steps.of(4)
expect Steps.min(Steps.of(4), Steps.of(4)) == Steps.of(4)
