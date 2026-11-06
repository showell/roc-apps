## A place in an animation, in beats from its start. `Beat` and `Beats` mirror
## `Along` and `Distance`: a length added to a place gives a place, and two
## places give the length between them, but two places can't be added.
##
## Each operation does the plain float arithmetic its name says, so code
## moved onto this type computes exactly what it did before.
import Beats

Beat :: F64.{

	of : F64 -> Beat
	of = |beat| Beat.(beat)

	to_f64 : Beat -> F64
	to_f64 = |Beat.(b)| b

	## The animation's start.
	start : Beat
	start = Beat.(0.0)

	## The place this many beats from the animation's start.
	at : Beats -> Beat
	at = |beats| Beat.(beats.to_f64())

	## How many beats this place is from the animation's start.
	from_start : Beat -> Beats
	from_start = |Beat.(b)| Beats.of(b)

	## The place `beats` further on.
	plus : Beat, Beats -> Beat
	plus = |Beat.(b), beats| Beat.(b + beats.to_f64())

	## How many beats this place is after `other`: negative when it is before.
	beats_from : Beat, Beat -> Beats
	beats_from = |Beat.(b), Beat.(other)| Beats.of(b - other)

	is_lt : Beat, Beat -> Bool
	is_lt = |Beat.(b), Beat.(other)| b < other

	is_lte : Beat, Beat -> Bool
	is_lte = |Beat.(b), Beat.(other)| b <= other

	is_eq : _
}

expect Beat.start.to_f64() == 0.0
expect Beat.at(Beats.of(2.5)) == Beat.of(2.5)
expect Beat.of(2.5).from_start() == Beats.of(2.5)
expect Beat.of(1.5).plus(Beats.of(2.25)).to_f64() == 3.75
expect Beat.of(4.0).beats_from(Beat.of(1.5)).to_f64() == 2.5
expect Beat.of(1.5).beats_from(Beat.of(4.0)).to_f64() == -2.5

expect Beat.of(2.0) < Beat.of(2.5)
expect !(Beat.of(2.5) < Beat.of(2.5))
expect Beat.of(2.5) <= Beat.of(2.5)
expect !(Beat.of(3.0) <= Beat.of(2.5))
expect Beat.of(2.5) == Beat.of(2.5)
expect !(Beat.of(2.5) == Beat.of(3.0))
