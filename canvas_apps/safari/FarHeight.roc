## A height above the horizon of something infinitely far away, in pixels
## through the lens at rest: the sun, the mountains, the rolling land. It is the
## ride's cheat for the far scenery. Such a thing is placed only by its bearing
## and this height, so it never comes nearer however far the rider goes, and
## only the lens changes how tall it is drawn. It is signed, and below the
## horizon it is negative.
##
## A far height becomes pixels on the screen only through `Lens.y_for_height`.

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

	divided_by : FarHeight, F64 -> FarHeight
	divided_by = |FarHeight.(h), divisor| FarHeight.(h / divisor)

	## This height measured the other way from the horizon.
	opposite : FarHeight -> FarHeight
	opposite = |FarHeight.(h)| FarHeight.(0.0 - h)

	## How far from the horizon this height is, above or below.
	abs : FarHeight -> FarHeight
	abs = |FarHeight.(h)| FarHeight.(h.abs())

	## How many of `whole` this is, which can pass 1 or go negative.
	portion : FarHeight, FarHeight -> F64
	portion = |FarHeight.(h), FarHeight.(whole)| h / whole

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

expect FarHeight.of(-2.5).to_f64() == -2.5
expect FarHeight.zero.to_f64() == 0.0

expect FarHeight.of(1.5).plus(FarHeight.of(2.25)).to_f64() == 3.75
expect FarHeight.of(1.5).minus(FarHeight.of(2.25)).to_f64() == -0.75
expect FarHeight.of(1.5).times(-2.0).to_f64() == -3.0
expect FarHeight.of(3.0).divided_by(2.0).to_f64() == 1.5

expect FarHeight.of(3.0).opposite().to_f64() == -3.0
expect FarHeight.of(-3.0).opposite().to_f64() == 3.0

# The sums downstream can see the sign of a zero, so `opposite` is a subtraction.
expect FarHeight.zero.opposite().to_f64().to_bits() == (0.0).to_bits()

expect FarHeight.of(3.0).abs().to_f64() == 3.0
expect FarHeight.of(-3.0).abs().to_f64() == 3.0

expect FarHeight.of(2.0).portion(FarHeight.of(8.0)) == 0.25
expect FarHeight.of(12.0).portion(FarHeight.of(8.0)) == 1.5
expect FarHeight.of(-2.0).portion(FarHeight.of(8.0)) == -0.25

expect FarHeight.of(2.0).max(FarHeight.of(3.0)).to_f64() == 3.0
expect FarHeight.of(3.0).max(FarHeight.of(2.0)).to_f64() == 3.0

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
