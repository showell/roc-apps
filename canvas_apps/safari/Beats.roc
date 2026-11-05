## A place along an animation, or a length of one, counted in beats. Beats are
## fractional and tied to no clock: the cat freezes at beat 10 on whichever
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

	zero : Beats
	zero = Beats.(0.0)

	plus : Beats, Beats -> Beats
	plus = |Beats.(b), Beats.(other)| Beats.(b + other)

	minus : Beats, Beats -> Beats
	minus = |Beats.(b), Beats.(other)| Beats.(b - other)

	times : Beats, F64 -> Beats
	times = |Beats.(b), factor| Beats.(b * factor)

	## This fraction of these beats.
	portion : Beats, Fraction -> Beats
	portion = |Beats.(b), fraction| Beats.(b * fraction.to_f64())

	## How many of `whole` this is, which can pass 1.
	ratio_to : Beats, Beats -> F64
	ratio_to = |Beats.(b), Beats.(whole)| b / whole

	is_lt : Beats, Beats -> Bool
	is_lt = |Beats.(b), Beats.(other)| b < other

	is_lte : Beats, Beats -> Bool
	is_lte = |Beats.(b), Beats.(other)| b <= other

	is_eq : _
}
