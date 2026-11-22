## A length in metres: how long a segment is, how tall a tree stands, how far
## the rider is from a cat. A length measured toward something can run past it,
## so a gap goes negative once the rider is beyond what it is measured to.
import lib.Fraction

Distance :: F64.{

	metres : F64 -> Distance
	metres = |m| Distance.(m)

	to_metres : Distance -> F64
	to_metres = |Distance.(distance)| distance

	## No length at all.
	zero : Distance
	zero = Distance.(0.0)

	plus : Distance, Distance -> Distance
	plus = |Distance.(distance), Distance.(other)| Distance.(distance + other)

	minus : Distance, Distance -> Distance
	minus = |Distance.(distance), Distance.(other)| Distance.(distance - other)

	times : Distance, F64 -> Distance
	times = |Distance.(distance), factor| Distance.(distance * factor)

	## This fraction of this length.
	scaled_by : Distance, Fraction -> Distance
	scaled_by = |Distance.(distance), fraction| Distance.(distance * fraction.to_f64())

	divided_by : Distance, F64 -> Distance
	divided_by = |Distance.(distance), divisor| Distance.(distance / divisor)

	## This length measured the other way.
	opposite : Distance -> Distance
	opposite = |Distance.(distance)| Distance.(0.0 - distance)

	## How many of `whole` this is, which can pass 1.
	ratio_to : Distance, Distance -> F64
	ratio_to = |Distance.(distance), Distance.(whole)| distance / whole

	## The smaller of this length and `other`.
	min : Distance, Distance -> Distance
	min = |Distance.(distance), Distance.(other)| Distance.(F64.min(distance, other))

	## The larger of this length and `other`.
	max : Distance, Distance -> Distance
	max = |Distance.(distance), Distance.(other)| Distance.(F64.max(distance, other))

	is_gt : Distance, Distance -> Bool
	is_gt = |Distance.(distance), Distance.(other)| distance > other

	is_gte : Distance, Distance -> Bool
	is_gte = |Distance.(distance), Distance.(other)| distance >= other

	is_lt : Distance, Distance -> Bool
	is_lt = |Distance.(distance), Distance.(other)| distance < other

	is_lte : Distance, Distance -> Bool
	is_lte = |Distance.(distance), Distance.(other)| distance <= other

	is_eq : _
}

## Just under, at and just over 2.5 m, and how `<`, `<=`, `>`, `>=` and `==`
## answer against 2.5 m there.
expect
	[
		(2.0, [True, True, False, False, False]),
		(2.5, [False, True, False, True, True]),
		(3.0, [False, False, True, True, False]),
	].all(
		|(metres, want)| {
			length = Distance.metres(metres)
			held = Distance.metres(2.5)
			[
				length < held,
				length <= held,
				length > held,
				length >= held,
				length == held,
			] == want
		},
	)
