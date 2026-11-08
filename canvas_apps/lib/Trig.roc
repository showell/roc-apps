## Trig holds the angle arithmetic that F64's builtins don't have: degrees and a
## pulse.
Trig :: [].{

	## Radians in a degree.
	degree : F64
	degree = 0.017453292519943295

	## Degrees in a radian.
	degrees_per_radian : F64
	degrees_per_radian = 57.29577951308232

	## A sine wave raised to run from nought to one and back, at `t` seconds,
	## once every `tau / 3.4` seconds. The rate 3.4 is chosen by eye, as a slow
	## breath.
	pulse : F64 -> F64
	pulse = |t| 0.5 + 0.5 * (t * 3.4).sin()
}
