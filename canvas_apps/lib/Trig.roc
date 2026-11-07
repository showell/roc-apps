## Trig holds the angle arithmetic that F64's builtins don't have: degrees, a turn
## wrapped into one circle and a pulse.
Trig :: [].{

	## Radians in a degree.
	degree : F64
	degree = 0.017453292519943295

	## The turn `x`, taken a whole circle at a time to between minus pi and pi. A
	## turn of more than `most_wrapped_circles` circles crashes, because no angle
	## here grows that far unless it is a bug.
	wrap : F64 -> F64
	wrap = |x| wrap_within(x, most_wrapped_circles)

	## Nought to one and back, once every `tau / 3.4` seconds: the breathing a
	## waiting prompt and a piece of food both do.
	pulse : F64 -> F64
	pulse = |t| 0.5 + 0.5 * (t * 3.4).sin()
}

most_wrapped_circles : I64
most_wrapped_circles = 64

## The turn `x`, taken to between minus pi and pi in at most `circles_left` circles.
wrap_within : F64, I64 -> F64
wrap_within = |x, circles_left|
	if x > F64.pi and circles_left > 0 {
		wrap_within(x - F64.tau, circles_left - 1)
	} else if x < -F64.pi and circles_left > 0 {
		wrap_within(x + F64.tau, circles_left - 1)
	} else if x > F64.pi or x < -F64.pi {
		crash "Trig.wrap: a turn of more circles than an angle here can reach"
	} else {
		x
	}

expect
	[
		(0.0, 0.0),
		(3.0, 3.0),
		(-3.0, -3.0),
		(4.0, 4.0 - F64.tau),
		(-4.0, F64.tau - 4.0),
		(8.0, 8.0 - F64.tau),
	].all(|(x, want)| Trig.wrap(x) == want)

# The most circles a turn can be taken round, one way or the other.
expect wrap_within(8.0, 1) == 8.0 - F64.tau
expect wrap_within(-8.0, 1) == F64.tau - 8.0
expect wrap_within(3.0, 0) == 3.0
