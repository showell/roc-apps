## A length measured in the cat's own height: how high a leap raises it, or
## where its head sits across its body, whatever size it stands on screen. It is
## signed: a place left of the cat's middle is negative, and so is the change
## between two heights on the way down.
##
## Each operation does the plain float arithmetic its name says, so code
## moved onto this type computes exactly what it did before.

CatHeights :: F64.{

	of : F64 -> CatHeights
	of = |heights| CatHeights.(heights)

	to_f64 : CatHeights -> F64
	to_f64 = |CatHeights.(h)| h

	## No length at all.
	zero : CatHeights
	zero = CatHeights.(0.0)

	plus : CatHeights, CatHeights -> CatHeights
	plus = |CatHeights.(h), CatHeights.(other)| CatHeights.(h + other)

	minus : CatHeights, CatHeights -> CatHeights
	minus = |CatHeights.(h), CatHeights.(other)| CatHeights.(h - other)

	times : CatHeights, F64 -> CatHeights
	times = |CatHeights.(h), factor| CatHeights.(h * factor)

	is_eq : _
}

expect CatHeights.of(0.18).to_f64() == 0.18
expect CatHeights.of(-0.48).to_f64() == -0.48
expect CatHeights.zero.to_f64() == 0.0
expect CatHeights.of(1.5).plus(CatHeights.of(2.25)).to_f64() == 3.75
expect CatHeights.of(1.5).minus(CatHeights.of(2.25)).to_f64() == -0.75
expect CatHeights.of(1.5).times(2.0).to_f64() == 3.0
expect CatHeights.of(1.5).times(-2.0).to_f64() == -3.0
expect CatHeights.of(2.5) == CatHeights.of(2.5)
expect !(CatHeights.of(2.5) == CatHeights.of(3.0))
