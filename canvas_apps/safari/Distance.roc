## A length in metres: how long a segment is, how tall a tree stands, how far
## the rider is from a cat. A length measured toward something can run past it,
## so a gap goes negative once the rider is beyond what it is measured to.

Distance :: F64.{

	metres : F64 -> Distance
	metres = |metres| Distance.(metres)

	to_metres : Distance -> F64
	to_metres = |Distance.(d)| d

	## No length at all.
	zero : Distance
	zero = Distance.(0.0)

	plus : Distance, Distance -> Distance
	plus = |Distance.(d), Distance.(other)| Distance.(d + other)

	minus : Distance, Distance -> Distance
	minus = |Distance.(d), Distance.(other)| Distance.(d - other)

	times : Distance, F64 -> Distance
	times = |Distance.(d), factor| Distance.(d * factor)

	divided_by : Distance, F64 -> Distance
	divided_by = |Distance.(d), divisor| Distance.(d / divisor)

	## This length measured the other way.
	opposite : Distance -> Distance
	opposite = |Distance.(d)| Distance.(0.0 - d)

	## How many of `whole` this is, which can pass 1.
	ratio_to : Distance, Distance -> F64
	ratio_to = |Distance.(d), Distance.(whole)| d / whole

	## The smaller of this length and `other`.
	min : Distance, Distance -> Distance
	min = |Distance.(d), Distance.(other)| Distance.(d.min(other))

	## The larger of this length and `other`.
	max : Distance, Distance -> Distance
	max = |Distance.(d), Distance.(other)| Distance.(d.max(other))

	is_gt : Distance, Distance -> Bool
	is_gt = |Distance.(d), Distance.(other)| d > other

	is_gte : Distance, Distance -> Bool
	is_gte = |Distance.(d), Distance.(other)| d >= other

	is_lt : Distance, Distance -> Bool
	is_lt = |Distance.(d), Distance.(other)| d < other

	is_lte : Distance, Distance -> Bool
	is_lte = |Distance.(d), Distance.(other)| d <= other

	is_eq : _
}
