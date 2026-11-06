# Trig -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import DeviceMath

Trig :: [].{

	half_pi : F64
	half_pi = DeviceMath.dm_half_pi

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

	atan_half_step : F64 -> F64
	atan_half_step = |t| (t / (1.0 + DeviceMath.real_sqrt((1.0 + (t * t)))))

	atan_halve : F64, I64 -> F64
	atan_halve = |t, n| (
		if n <= 0 {
			t
		} else {
			atan_halve(atan_half_step(t), (n - 1))
		}
	)

	atan_series : F64 -> F64
	atan_series = |u| (
		{
			u2 = (u * u)
			u3 = (u2 * u)
			u5 = (u3 * u2)
			u7 = (u5 * u2)
			u9 = (u7 * u2)
			u11 = (u9 * u2)
			(((((u - (u3 / 3.0)) + (u5 / 5.0)) - (u7 / 7.0)) + (u9 / 9.0)) - (u11 / 11.0))
		}
	)

	atan_core : F64 -> F64
	atan_core = |t| (16.0 * atan_series(atan_halve(t, 4)))

	r_atan : F64 -> F64
	r_atan = |t| (
		if t > 1.0 {
			(half_pi - atan_core((1.0 / t)))
		} else {
			(
				if t < (0.0 - 1.0) {
					((0.0 - half_pi) - atan_core((1.0 / t)))
				} else {
					atan_core(t)
				}
			)
		}
	)

	r_atan2 : F64, F64 -> F64
	r_atan2 = |y, x| (
		if x > 0.0 {
			r_atan((y / x))
		} else {
			(
				if x < 0.0 {
					(
						if y >= 0.0 {
							(r_atan((y / x)) + F64.pi)
						} else {
							(r_atan((y / x)) - F64.pi)
						}
					)
				} else {
					(
						if y > 0.0 {
							half_pi
						} else {
							(
								if y < 0.0 {
									(0.0 - half_pi)
								} else {
									0.0
								}
							)
						}
					)
				}
			)
		}
	)

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

expect
	[
		(0.0, 0.0),
		(0.25, 0.24497866312686414),
		(0.5, 0.4636476090008061),
		(1.0, 0.7853981633974483),
		(2.0, 1.1071487177940904),
		(4.0, 1.3258176636680326),
	].all(|(slope, angle)| (Trig.r_atan(slope) - angle).abs() <= 0.000000000000001)
