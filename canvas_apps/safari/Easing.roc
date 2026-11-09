## The sums for moving smoothly between two values. A fraction runs from 0 at
## the start of a move to 1 at its end.
import lib.Fraction

Easing :: [].{

	## The value `fraction` of the way from `from` to `to`.
	lerp : {
		from : F64,
		to : F64,
		fraction : Fraction,
	} -> F64
	lerp = |{ from, to, fraction }| from + (to - from) * fraction.to_f64()

	## A fraction that starts and ends gently: `t` itself at 0, a half and 1,
	## and slower than `t` near either end.
	smoothstep : Fraction -> Fraction
	smoothstep = |fraction| {
		t = fraction.to_f64()
		Fraction.of(t * t * (3.0 - 2.0 * t))
	}

}

expect
	[
		(0.25, 3.0),
		(0.0, 2.0),
		(1.0, 6.0),
		(0.75, 5.0),
	].all(
		|(ratio, value)| {
			got = Easing.lerp({
				from: 2.0,
				to: 6.0,
				fraction: Fraction.of(ratio),
			})
			got == value
		},
	)

expect
	[
		(0.0, 0.0),
		(0.25, 0.15625),
		(0.5, 0.5),
		(0.75, 0.84375),
		(1.0, 1.0),
	].all(|(ratio, eased)| Easing.smoothstep(Fraction.of(ratio)).to_f64() == eased)
