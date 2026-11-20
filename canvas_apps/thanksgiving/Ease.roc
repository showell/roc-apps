## Ease turns a count of ticks into how far through a motion it is, the
## arithmetic every timeline module shares: a ramp from 0 to 1, a smooth
## start and stop, a whip that is fast off the mark, and a spring's wobble.
Ease :: [].{

	## How much of the way through something that starts at 0 and takes
	## `duration` ticks it is, `since` ticks in, held at each end.
	ramp : I64, I64 -> F64
	ramp = |since, duration|
		if since <= 0 {
			0.0
		} else if since >= duration {
			1.0
		} else {
			since.to_f64() / duration.to_f64()
		}

	## A ramp's fraction, eased so it starts and stops gently.
	smooth : F64 -> F64
	smooth = |progress| progress * progress * (3.0 - 2.0 * progress)

	## A ramp's fraction, whipped: it sets off at full speed and slows all
	## the way to a stop, as a camera snapped onto something does.
	whip : F64 -> F64
	whip = |progress| {
		left = 1.0 - progress
		1.0 - left * left * left
	}

	## How far a struck spring has swung `since` ticks after it was struck,
	## from -1 to 1: a wobble that dies away over a second and a half, 0
	## before the strike and after it.
	boing : I64 -> F64
	boing = |since|
		if since <= 0 {
			0.0
		} else {
			left = 1.0 - Ease.ramp(since, 90)
			left * left * (since.to_f64() * 0.45).sin()
		}
}

expect Ease.ramp(-3, 10) == 0.0 and Ease.ramp(5, 10) == 0.5 and Ease.ramp(12, 10) == 1.0
expect Ease.whip(0.0) == 0.0 and Ease.whip(1.0) == 1.0 and Ease.whip(0.5) > 0.8
