## The sums for moving smoothly between two values. A fraction runs from 0 at
## the start of a move to 1 at its end.

Easing :: [].{

	## `x`, held between 0 and 1.
	clamp01 : F64 -> F64
	clamp01 = |x|
		if x < 0.0 {
			0.0
		} else if x > 1.0 {
			1.0
		} else {
			x
		}

	## The value `fraction` of the way from `from` to `to`.
	lerp : {
		from : F64,
		to : F64,
		fraction : F64,
	} -> F64
	lerp = |
		{
			from,
			to,
			fraction,
		},
	| from + (to - from) * fraction

	## A fraction that starts and ends gently: `t` itself at 0, a half and 1,
	## and slower than `t` near either end.
	smoothstep : F64 -> F64
	smoothstep = |t| t * t * (3.0 - 2.0 * t)
}
