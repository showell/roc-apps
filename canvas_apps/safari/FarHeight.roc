## A height above the horizon of something infinitely far away, in pixels
## through the lens at rest: the sun, the mountains, the rolling land. It is the
## ride's cheat for the far scenery. Such a thing is placed only by its bearing
## and this height, so it never comes nearer however far the rider goes, and
## only the lens changes how high it is drawn. It is signed, and below the
## horizon it is negative.
##
## A far height is a place. How far apart two stand is a `FarRise`, and only a
## far rise moves a far height up or down. Two far heights never add.
import FarRise

FarHeight :: F64.{

	of : F64 -> FarHeight
	of = |count| FarHeight.(count)

	to_f64 : FarHeight -> F64
	to_f64 = |FarHeight.(h)| h

	## Level with the horizon.
	zero : FarHeight
	zero = FarHeight.(0.0)

	## This height raised by `rise`.
	plus : FarHeight, FarRise -> FarHeight
	plus = |FarHeight.(h), rise| FarHeight.(h + rise.to_f64())

	## This height lowered by `rise`.
	lowered_by : FarHeight, FarRise -> FarHeight
	lowered_by = |FarHeight.(h), rise| FarHeight.(h - rise.to_f64())

	## How far this height stands above `other`, below it once negative.
	minus : FarHeight, FarHeight -> FarRise
	minus = |FarHeight.(h), FarHeight.(other)| FarRise.of(h - other)

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

lower : FarHeight
lower = FarHeight.of(-1.0)

higher : FarHeight
higher = FarHeight.of(2.0)

expect higher.minus(lower) == FarRise.of(3.0)
expect lower.minus(higher) == FarRise.of(-3.0)
expect lower.plus(FarRise.of(3.0)) == higher
expect higher.lowered_by(FarRise.of(3.0)) == lower
expect lower.max(higher) == higher
expect higher.max(lower) == higher

# The sums downstream can see the sign of a zero, so lowering the horizon by
# nothing stays a positive zero.
expect FarHeight.zero.lowered_by(FarRise.of(0.0)).to_f64().to_bits() == (0.0).to_bits()

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
