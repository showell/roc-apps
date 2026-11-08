## A height above the horizon of something infinitely far away, in pixels
## through the lens at rest: the sun, the mountains, the rolling land. It is the
## ride's cheat for the far scenery. Such a thing is placed only by its bearing
## and this height, so it never comes nearer however far the rider goes, and
## only the lens changes how tall it is drawn. It is signed, and below the
## horizon it is negative.
##
## A far height becomes pixels on the screen only through `Lens.size_on_screen`.
import Fraction

FarHeight :: F64.{

	of : F64 -> FarHeight
	of = |count| FarHeight.(count)

	to_f64 : FarHeight -> F64
	to_f64 = |FarHeight.(h)| h

	## Level with the horizon.
	zero : FarHeight
	zero = FarHeight.(0.0)

	plus : FarHeight, FarHeight -> FarHeight
	plus = |FarHeight.(h), FarHeight.(other)| FarHeight.(h + other)

	minus : FarHeight, FarHeight -> FarHeight
	minus = |FarHeight.(h), FarHeight.(other)| FarHeight.(h - other)

	times : FarHeight, F64 -> FarHeight
	times = |FarHeight.(h), factor| FarHeight.(h * factor)

	## This fraction of this height.
	scaled_by : FarHeight, Fraction -> FarHeight
	scaled_by = |FarHeight.(h), fraction| FarHeight.(h * fraction.to_f64())

	divided_by : FarHeight, F64 -> FarHeight
	divided_by = |FarHeight.(h), divisor| FarHeight.(h / divisor)

	## This height measured the other way from the horizon.
	opposite : FarHeight -> FarHeight
	opposite = |FarHeight.(h)| FarHeight.(0.0 - h)

	## How far from the horizon this height is, above or below.
	abs : FarHeight -> FarHeight
	abs = |FarHeight.(h)| FarHeight.(h.abs())

	## How many of `whole` this is, which can pass 1 or go negative.
	ratio_to : FarHeight, FarHeight -> F64
	ratio_to = |FarHeight.(h), FarHeight.(whole)| h / whole

	## The higher of this height and `other`.
	max : FarHeight, FarHeight -> FarHeight
	max = |FarHeight.(h), FarHeight.(other)| FarHeight.(h.max(other))

	is_gt : FarHeight, FarHeight -> Bool
	is_gt = |FarHeight.(h), FarHeight.(other)| h > other

	is_gte : FarHeight, FarHeight -> Bool
	is_gte = |FarHeight.(h), FarHeight.(other)| h >= other

	is_lt : FarHeight, FarHeight -> Bool
	is_lt = |FarHeight.(h), FarHeight.(other)| h < other

	is_lte : FarHeight, FarHeight -> Bool
	is_lte = |FarHeight.(h), FarHeight.(other)| h <= other

	is_eq : _
}

# The sums downstream can see the sign of a zero, so `opposite` is a subtraction.
expect FarHeight.zero.opposite().to_f64().to_bits() == (0.0).to_bits()

lower : FarHeight
lower = FarHeight.of(-1.0)

higher : FarHeight
higher = FarHeight.of(2.0)

expect lower < higher
expect !(higher < higher)
expect lower <= higher
expect higher <= higher
expect !(higher <= lower)
expect higher > lower
expect !(higher > higher)
expect higher >= higher
expect !(lower >= higher)
expect higher == higher
expect !(lower == higher)
