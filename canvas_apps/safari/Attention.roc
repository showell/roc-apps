## How strongly something holds the rider's eye, from 0 upward. A look to the
## side at its fullest is 1, and a cat in the lane holds the eye harder than
## that, so this is no `Fraction`.
##
## Each operation does the plain float arithmetic its name says, so code
## moved onto this type computes exactly what it did before.
import Fraction

Attention :: F64.{

	of : F64 -> Attention
	of = |strength| Attention.(strength)

	from_fraction : Fraction -> Attention
	from_fraction = |fraction| Attention.(fraction.to_f64())

	to_f64 : Attention -> F64
	to_f64 = |Attention.(a)| a

	## Nothing is holding the rider's eye.
	none : Attention
	none = Attention.(0.0)

	## This fraction of this attention.
	portion : Attention, Fraction -> Attention
	portion = |Attention.(a), fraction| Attention.(fraction.to_f64() * a)

	## The stronger of this attention and `other`.
	max : Attention, Attention -> Attention
	max = |Attention.(a), Attention.(other)| Attention.(a.max(other))

	is_eq : _
}

expect Attention.none.to_f64() == 0.0
expect Attention.of(1.8).to_f64() == 1.8
expect Attention.from_fraction(Fraction.of(0.5)).to_f64() == 0.5
expect Attention.of(1.8).portion(Fraction.of(0.5)).to_f64() == 0.9
expect Attention.of(0.3).max(Attention.of(1.4)).to_f64() == 1.4
expect Attention.of(1.4).max(Attention.of(0.3)).to_f64() == 1.4
