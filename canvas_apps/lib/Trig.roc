# Trig -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).

Trig :: [].{

	deg : F64
	deg = 0.017453292519943295

	wrap : F64, I64 -> F64
	wrap = |x, fuel| (
		if fuel <= 0 {
			x
		} else {
			(
				if x > F64.pi {
					wrap((x - F64.tau), (fuel - 1))
				} else {
					(
						if x < (0.0 - F64.pi) {
							wrap((x + F64.tau), (fuel - 1))
						} else {
							x
						}
					)
				}
			)
		}
	)

	## Nought to one and back, once every `tau / 3.4` seconds: the breathing a
	## waiting prompt and a piece of food both do.
	pulse : F64 -> F64
	pulse = |t| 0.5 + 0.5 * (t * 3.4).sin()

	r_sign : F64 -> F64
	r_sign = |x| (
		if x > 0.0 {
			1.0
		} else {
			(
				if x < 0.0 {
					(0.0 - 1.0)
				} else {
					0.0
				}
			)
		}
	)
}
