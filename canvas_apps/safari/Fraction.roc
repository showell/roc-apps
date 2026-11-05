## A ratio from 0 to 1: how far through a move, how near dusk, how bright a
## beacon. Only this module can build one, so a value of this type is always
## in range. Anything that can pass 1 has a type of its own.
##
## There are two ways in. `of` takes a ratio that can only be in range, and a
## ratio outside it means the sum that made it is wrong, so `of` crashes.
## `clamp` takes a ratio that can rightly fall outside, such as how far a
## rider has come along a stretch they haven't reached yet.
##
## Each operation does the plain float arithmetic its name says, so code
## moved onto this type computes exactly what it did before.
import lib.DeviceMath

Fraction :: F64.{

	## This ratio as a fraction. A value that is not a number is out of range.
	from_ratio : F64 -> Try(Fraction, [OutOfRange])
	from_ratio = |ratio|
		if ratio >= 0.0 and ratio <= 1.0 {
			Ok(Fraction.(ratio))
		} else {
			Err(OutOfRange)
		}

	## A ratio that can only be in range, as a fraction.
	of : F64 -> Fraction
	of = |ratio|
		match from_ratio(ratio) {
			Ok(fraction) => fraction
			Err(OutOfRange) => crash "Fraction.of: this ratio is outside 0 to 1, so the sum behind it is wrong"
		}

	## The fraction nearest this ratio.
	clamp : F64 -> Fraction
	clamp = |ratio|
		if ratio < 0.0 {
			zero
		} else if ratio > 1.0 {
			whole
		} else {
			of(ratio)
		}

	to_f64 : Fraction -> F64
	to_f64 = |Fraction.(f)| f

	zero : Fraction
	zero = Fraction.(0.0)

	whole : Fraction
	whole = Fraction.(1.0)

	## This fraction of `other`.
	times : Fraction, Fraction -> Fraction
	times = |Fraction.(f), Fraction.(other)| Fraction.(f * other)

	## What is left of the whole after this fraction.
	complement : Fraction -> Fraction
	complement = |Fraction.(f)| Fraction.(1.0 - f)

	## The larger of this fraction and `other`.
	max : Fraction, Fraction -> Fraction
	max = |Fraction.(f), Fraction.(other)| Fraction.(DeviceMath.real_max(f, other))

	is_lt : Fraction, Fraction -> Bool
	is_lt = |Fraction.(f), Fraction.(other)| f < other

	is_lte : Fraction, Fraction -> Bool
	is_lte = |Fraction.(f), Fraction.(other)| f <= other

	is_gte : Fraction, Fraction -> Bool
	is_gte = |Fraction.(f), Fraction.(other)| f >= other

	is_eq : _
}
