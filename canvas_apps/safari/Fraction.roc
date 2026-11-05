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

not_a_number : F64
not_a_number = F64.from_bits(9221120237041090560)

infinity : F64
infinity = F64.from_bits(9218868437227405312)

negative_zero : F64
negative_zero = F64.from_bits(9223372036854775808)

is_fraction : F64 -> Bool
is_fraction = |ratio|
	match Fraction.from_ratio(ratio) {
		Ok(_) => True
		Err(OutOfRange) => False
	}

expect
	[
		(0.0, True),
		(negative_zero, True),
		(0.5, True),
		(1.0, True),
		(-0.000001, False),
		(1.000001, False),
		(not_a_number, False),
		(infinity, False),
	].all(|(ratio, answer)| is_fraction(ratio) == answer)

expect
	[
		(-0.5, 0.0),
		(-0.000001, 0.0),
		(0.0, 0.0),
		(0.25, 0.25),
		(1.0, 1.0),
		(1.000001, 1.0),
		(1.5, 1.0),
	].all(|(ratio, clamped)| Fraction.clamp(ratio).to_f64() == clamped)

# The sums downstream of a clamp can see the sign, so it stays.
expect Fraction.clamp(negative_zero).to_f64().to_bits() == negative_zero.to_bits()

expect Fraction.zero.to_f64() == 0.0
expect Fraction.whole.to_f64() == 1.0
expect Fraction.of(0.5).times(Fraction.of(0.25)).to_f64() == 0.125
expect Fraction.of(0.25).complement().to_f64() == 0.75
expect Fraction.zero.complement().to_f64() == 1.0
expect Fraction.whole.complement().to_f64() == 0.0
expect Fraction.of(0.25).max(Fraction.of(0.5)).to_f64() == 0.5
expect Fraction.of(0.5).max(Fraction.of(0.25)).to_f64() == 0.5

lesser : Fraction
lesser = Fraction.of(0.25)

greater : Fraction
greater = Fraction.of(0.5)

expect lesser < greater
expect !(greater < greater)
expect !(greater < lesser)
expect lesser <= greater
expect greater <= greater
expect !(greater <= lesser)
expect !(lesser >= greater)
expect greater >= greater
expect greater >= lesser
expect greater == greater
expect !(lesser == greater)
