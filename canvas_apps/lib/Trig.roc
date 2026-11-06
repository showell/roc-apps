## Trig holds the angle arithmetic that F64's builtins don't have: degrees, a turn
## wrapped into one circle, a sign and a pulse.
Trig :: [].{

	## Radians in a degree.
	deg : F64
	deg = 0.017453292519943295

	## The turn `x`, taken a whole circle at a time to between minus pi and pi, in
	## at most `fuel` circles.
	wrap : F64, I64 -> F64
	wrap = |x, fuel|
		if fuel <= 0 {
			x
		} else if x > F64.pi {
			wrap(x - F64.tau, fuel - 1)
		} else if x < -F64.pi {
			wrap(x + F64.tau, fuel - 1)
		} else {
			x
		}

	## Nought to one and back, once every `tau / 3.4` seconds: the breathing a
	## waiting prompt and a piece of food both do.
	pulse : F64 -> F64
	pulse = |t| 0.5 + 0.5 * (t * 3.4).sin()

	## One for a positive `x`, minus one for a negative one, and nought for nought.
	sign : F64 -> F64
	sign = |x|
		if x > 0.0 {
			1.0
		} else if x < 0.0 {
			-1.0
		} else {
			0.0
		}
}

expect [(-0.5, -1.0), (0.0, 0.0), (0.5, 1.0)].all(|(x, want)| Trig.sign(x) == want)

expect
	[
		(0.0, 0.0),
		(3.0, 3.0),
		(-3.0, -3.0),
		(4.0, 4.0 - F64.tau),
		(-4.0, F64.tau - 4.0),
		(8.0, 8.0 - F64.tau),
	].all(|(x, want)| Trig.wrap(x, 64) == want)

# With no fuel left, a turn stays as it is.
expect Trig.wrap(8.0, 0) == 8.0
