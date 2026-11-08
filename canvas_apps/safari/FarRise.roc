## A span up and down at infinity, in pixels through the lens at rest: how far
## apart two far heights stand, measured along the vertical. The sun's radius is
## a far rise, and so is how far the snowline dips under the highest peak. A far
## height is a place above the horizon, and the difference of two is a far rise
## (`FarHeight.minus`). A far height raised by a far rise is another far height
## (`FarHeight.plus`). It is signed, and a span measured downward is negative.
##
## A far rise becomes pixels on the screen only through `Lens.size_on_screen`.
import Fraction

FarRise :: F64.{

	of : F64 -> FarRise
	of = |count| FarRise.(count)

	to_f64 : FarRise -> F64
	to_f64 = |FarRise.(r)| r

	## The two spans end to end.
	plus : FarRise, FarRise -> FarRise
	plus = |FarRise.(r), FarRise.(other)| FarRise.(r + other)

	times : FarRise, F64 -> FarRise
	times = |FarRise.(r), factor| FarRise.(r * factor)

	## This fraction of this span.
	scaled_by : FarRise, Fraction -> FarRise
	scaled_by = |FarRise.(r), fraction| FarRise.(r * fraction.to_f64())

	## How long this span is, upward or downward.
	abs : FarRise -> FarRise
	abs = |FarRise.(r)| FarRise.(r.abs())

	## How many of `whole` this is, which can pass 1 or go negative.
	ratio_to : FarRise, FarRise -> F64
	ratio_to = |FarRise.(r), FarRise.(whole)| r / whole

	is_gt : FarRise, FarRise -> Bool
	is_gt = |FarRise.(r), FarRise.(other)| r > other

	is_gte : FarRise, FarRise -> Bool
	is_gte = |FarRise.(r), FarRise.(other)| r >= other

	is_lt : FarRise, FarRise -> Bool
	is_lt = |FarRise.(r), FarRise.(other)| r < other

	is_lte : FarRise, FarRise -> Bool
	is_lte = |FarRise.(r), FarRise.(other)| r <= other

	is_eq : _
}

shorter : FarRise
shorter = FarRise.of(-1.0)

longer : FarRise
longer = FarRise.of(2.0)

expect shorter.plus(longer) == FarRise.of(1.0)
expect longer.times(1.5) == FarRise.of(3.0)
expect longer.scaled_by(Fraction.of(0.25)) == FarRise.of(0.5)
expect shorter.abs() == FarRise.of(1.0)
expect longer.abs() == longer
expect shorter.ratio_to(longer) == -0.5
expect longer.ratio_to(longer) == 1.0

expect shorter < longer
expect !(longer < longer)
expect shorter <= longer
expect longer <= longer
expect !(longer <= shorter)
expect longer > shorter
expect !(longer > longer)
expect longer >= longer
expect !(shorter >= longer)
expect longer == longer
expect !(shorter == longer)
