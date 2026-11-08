## A length on screen, in pixels, whole or not: how tall a cat stands, where a
## point lands, how long the camera's lens is. It is signed. A place on screen
## is measured from the corner, so a point off the left of the screen is
## negative.
##
## Pixels stop at the edge of `lib.Shapes`, which takes plain numbers, and at
## trigonometry.
import Fraction

Pixels :: F64.{

	of : F64 -> Pixels
	of = |count| Pixels.(count)

	to_f64 : Pixels -> F64
	to_f64 = |Pixels.(p)| p

	## No length at all.
	zero : Pixels
	zero = Pixels.(0.0)

	plus : Pixels, Pixels -> Pixels
	plus = |Pixels.(p), Pixels.(other)| Pixels.(p + other)

	minus : Pixels, Pixels -> Pixels
	minus = |Pixels.(p), Pixels.(other)| Pixels.(p - other)

	times : Pixels, F64 -> Pixels
	times = |Pixels.(p), factor| Pixels.(p * factor)

	## This fraction of this length.
	scaled_by : Pixels, Fraction -> Pixels
	scaled_by = |Pixels.(p), fraction| Pixels.(p * fraction.to_f64())

	divided_by : Pixels, F64 -> Pixels
	divided_by = |Pixels.(p), divisor| Pixels.(p / divisor)

	## This length measured the other way.
	opposite : Pixels -> Pixels
	opposite = |Pixels.(p)| Pixels.(0.0 - p)

	## This length, whichever way it is measured.
	abs : Pixels -> Pixels
	abs = |Pixels.(p)| Pixels.(p.abs())

	## How many of `whole` this is, which can pass 1 or go negative.
	ratio_to : Pixels, Pixels -> F64
	ratio_to = |Pixels.(p), Pixels.(whole)| p / whole

	## The larger of this length and `other`.
	max : Pixels, Pixels -> Pixels
	max = |Pixels.(p), Pixels.(other)| Pixels.(p.max(other))

	is_gt : Pixels, Pixels -> Bool
	is_gt = |Pixels.(p), Pixels.(other)| p > other

	is_gte : Pixels, Pixels -> Bool
	is_gte = |Pixels.(p), Pixels.(other)| p >= other

	is_lt : Pixels, Pixels -> Bool
	is_lt = |Pixels.(p), Pixels.(other)| p < other

	is_lte : Pixels, Pixels -> Bool
	is_lte = |Pixels.(p), Pixels.(other)| p <= other

	is_eq : _
}

# The sums downstream can see the sign of a zero, so `opposite` is a subtraction.
expect Pixels.zero.opposite().to_f64().to_bits() == (0.0).to_bits()

lesser : Pixels
lesser = Pixels.of(-1.0)

greater : Pixels
greater = Pixels.of(2.0)

expect lesser < greater
expect !(greater < greater)
expect !(greater < lesser)
expect lesser <= greater
expect greater <= greater
expect !(greater <= lesser)
expect greater > lesser
expect !(greater > greater)
expect !(lesser > greater)
expect greater >= lesser
expect greater >= greater
expect !(lesser >= greater)
expect greater == greater
expect !(lesser == greater)
