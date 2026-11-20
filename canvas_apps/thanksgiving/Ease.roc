## Ease turns a count of ticks into how far through a motion it is, the
## arithmetic every timeline module shares: a ramp from 0 to 1, a smooth
## start and stop, and a spring that overshoots and settles.
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

	## A ramp's fraction, sprung: it shoots past 1 and settles back, as a
	## thing that pops into being does.
	springy : F64 -> F64
	springy = |progress| {
		past = progress - 1.0
		1.0 + (overshoot + 1.0) * past * past * past + overshoot * past * past
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

# How far `springy` overshoots: at 2.5 it peaks about a sixth past 1.
overshoot : F64
overshoot = 2.5

expect Ease.ramp(-3, 10) == 0.0 and Ease.ramp(5, 10) == 0.5 and Ease.ramp(12, 10) == 1.0
expect Ease.springy(0.0) == 0.0 and Ease.springy(1.0) == 1.0 and Ease.springy(0.7) > 1.0
