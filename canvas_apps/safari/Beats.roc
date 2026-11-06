## A length of an animation, counted in beats, where a `Beat` is a place in one.
## Beats are fractional and tied to no clock: the cat freezes at beat 10 on whichever
## step of the ride that falls, and a rule in `Animation` says how the rider's
## approach moves through them.
##
## Each operation does the plain float arithmetic its name says, so code
## moved onto this type computes exactly what it did before.
import Fraction

Beats :: F64.{

	of : F64 -> Beats
	of = |count| Beats.(count)

	to_f64 : Beats -> F64
	to_f64 = |Beats.(b)| b

	plus : Beats, Beats -> Beats
	plus = |Beats.(b), Beats.(other)| Beats.(b + other)

	times : Beats, F64 -> Beats
	times = |Beats.(b), factor| Beats.(b * factor)

	## This fraction of these beats.
	portion : Beats, Fraction -> Beats
	portion = |Beats.(b), fraction| Beats.(b * fraction.to_f64())

	## How many of `whole` this is, which can pass 1.
	ratio_to : Beats, Beats -> F64
	ratio_to = |Beats.(b), Beats.(whole)| b / whole

	is_eq : _
}

expect Beats.of(1.5).plus(Beats.of(2.25)).to_f64() == 3.75
expect Beats.of(38.0).times(0.5).to_f64() == 19.0
expect Beats.of(38.0).portion(Fraction.of(0.25)).to_f64() == 9.5

# A ratio can be under 1, 1 itself, or past it.
expect Beats.of(2.0).ratio_to(Beats.of(8.0)) == 0.25
expect Beats.of(8.0).ratio_to(Beats.of(8.0)) == 1.0
expect Beats.of(12.0).ratio_to(Beats.of(8.0)) == 1.5

expect Beats.of(2.5) == Beats.of(2.5)
expect !(Beats.of(2.5) == Beats.of(3.0))
