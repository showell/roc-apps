## Float holds the arithmetic on F64 that the standard library doesn't give us the
## same way on every target: rounding, floors, a remainder, and exp.
Float :: [].{

	round : F64 -> F64
	round = |x| {
		t = I64.to_f64(F64.to_i64_wrap(x))
		f = (x - t)
		if f >= 0.5 {
			t + 1.0
		} else if f <= (0.0 - 0.5) {
			t - 1.0
		} else {
			t
		}
	}

	floor : F64 -> F64
	floor = |x| {
		t = I64.to_f64(F64.to_i64_wrap(x))
		if t > x {
			t - 1.0
		} else {
			t
		}
	}

	mod : F64, F64 -> F64
	mod = |x, m| x - (m * floor((x / m)))

	ln2 : F64
	ln2 = 0.6931471805599453

	exp_series : F64 -> F64
	exp_series = |r| {
		t1 = r
		t2 = ((t1 * r) / 2.0)
		t3 = ((t2 * r) / 3.0)
		t4 = ((t3 * r) / 4.0)
		t5 = ((t4 * r) / 5.0)
		t6 = ((t5 * r) / 6.0)
		t7 = ((t6 * r) / 7.0)
		t8 = ((t7 * r) / 8.0)
		t9 = ((t8 * r) / 9.0)
		t10 = ((t9 * r) / 10.0)
		t11 = ((t10 * r) / 11.0)
		t12 = ((t11 * r) / 12.0)
		1.0 + t1 + t2 + t3 + t4 + t5 + t6 + t7 + t8 + t9 + t10 + t11 + t12
	}

	pow2_up : I64, F64 -> F64
	pow2_up = |k, acc|
		if k <= 0 {
			acc
		} else {
			pow2_up((k - 1), (acc * 2.0))
		}

	pow2_down : I64, F64 -> F64
	pow2_down = |k, acc|
		if k >= 0 {
			acc
		} else {
			pow2_down((k + 1), (acc * 0.5))
		}

	pow2_int : I64 -> F64
	pow2_int = |k|
		if k >= 0 {
			pow2_up(k, 1.0)
		} else {
			pow2_down(k, 1.0)
		}

	exp : F64 -> F64
	exp = |x| {
		k = F64.to_i64_wrap(round((x / ln2)))
		exp_series((x - (I64.to_f64(k) * ln2))) * pow2_int(k)
	}

	ceil : F64 -> F64
	ceil = |x| 0.0 - floor((0.0 - x))
}

expect Float.round(-255.5) == -256.0
expect Float.round(-128.5) == -129.0
expect Float.round(-90.0) == -90.0
expect Float.round(-80.4) == -80.0
expect Float.round(-70.5) == -71.0
expect Float.round(-2.5) == -3.0
expect Float.round(-1.5) == -2.0
expect Float.round(-0.5000000000000001) == -1.0
expect Float.round(-0.5) == -1.0
expect Float.round(-0.49999999999999994) == -0.0
expect Float.round(-0.25) == -0.0
expect Float.round(0.0) == 0.0
expect Float.round(0.25) == 0.0
expect Float.round(0.49999999999999994) == 0.0
expect Float.round(0.5) == 1.0
expect Float.round(1.5) == 2.0
expect Float.round(2.5) == 3.0
expect Float.round(4.5) == 5.0
expect Float.round(14.5) == 15.0
expect Float.round(19.5) == 20.0
expect Float.round(29.5) == 30.0
expect Float.round(49.5) == 50.0
expect Float.round(70.5) == 71.0
expect Float.round(127.5) == 128.0
expect Float.round(128.5) == 129.0
expect Float.round(254.5) == 255.0
expect Float.round(255.0) == 255.0
expect Float.round(1048576.5) == 1048577.0

expect Float.floor(-1000.5) == -1001.0
expect Float.floor(-120.0) == -120.0
expect Float.floor(-119.5) == -120.0
expect Float.floor(-2.5) == -3.0
expect Float.floor(-2.0) == -2.0
expect Float.floor(-1.5) == -2.0
expect Float.floor(-1.0) == -1.0
expect Float.floor(-0.5) == -1.0
expect Float.floor(0.0) == 0.0
expect Float.floor(0.5) == 0.0
expect Float.floor(1.0) == 1.0
expect Float.floor(1.5) == 1.0
expect Float.floor(2.0) == 2.0
expect Float.floor(2.5) == 2.0
expect Float.floor(119.5) == 119.0
expect Float.floor(120.0) == 120.0
expect Float.floor(1000.5) == 1000.0

expect Float.ceil(-1000.5) == -1000.0
expect Float.ceil(-120.0) == -120.0
expect Float.ceil(-119.5) == -119.0
expect Float.ceil(-2.5) == -2.0
expect Float.ceil(-2.0) == -2.0
expect Float.ceil(-1.5) == -1.0
expect Float.ceil(-1.0) == -1.0
expect Float.ceil(-0.5) == 0.0
expect Float.ceil(0.0) == 0.0
expect Float.ceil(0.5) == 1.0
expect Float.ceil(1.0) == 1.0
expect Float.ceil(1.5) == 2.0
expect Float.ceil(2.0) == 2.0
expect Float.ceil(2.5) == 3.0
expect Float.ceil(119.5) == 120.0
expect Float.ceil(120.0) == 120.0
expect Float.ceil(1000.5) == 1001.0

expect Float.mod(-1000.0, 120.0) == 80.0
expect Float.mod(-240.0, 120.0) == -0.0
expect Float.mod(-239.5, 120.0) == 0.5
expect Float.mod(-120.0, 120.0) == -0.0
expect Float.mod(-119.5, 120.0) == 0.5
expect Float.mod(-0.5, 120.0) == 119.5
expect Float.mod(0.0, 120.0) == 0.0
expect Float.mod(0.5, 120.0) == 0.5
expect Float.mod(119.5, 120.0) == 119.5
expect Float.mod(120.0, 120.0) == 0.0
expect Float.mod(240.5, 120.0) == 0.5
expect Float.mod(1000.0, 120.0) == 40.0
expect Float.mod(3600.25, 120.0) == 0.25
expect Float.mod(-1000.0, 7.5) == 5.0
expect Float.mod(-240.0, 7.5) == -0.0
expect Float.mod(-239.5, 7.5) == 0.5
expect Float.mod(-120.0, 7.5) == -0.0
expect Float.mod(-119.5, 7.5) == 0.5
expect Float.mod(-0.5, 7.5) == 7.0
expect Float.mod(0.0, 7.5) == 0.0
expect Float.mod(0.5, 7.5) == 0.5
expect Float.mod(119.5, 7.5) == 7.0
expect Float.mod(120.0, 7.5) == 0.0
expect Float.mod(240.5, 7.5) == 0.5
expect Float.mod(1000.0, 7.5) == 2.5
expect Float.mod(3600.25, 7.5) == 0.25
expect Float.mod(-1000.0, -120.0) == -40.0
expect Float.mod(-240.0, -120.0) == -0.0
expect Float.mod(-239.5, -120.0) == -119.5
expect Float.mod(-120.0, -120.0) == -0.0
expect Float.mod(-119.5, -120.0) == -119.5
expect Float.mod(-0.5, -120.0) == -0.5
expect Float.mod(0.0, -120.0) == 0.0
expect Float.mod(0.5, -120.0) == -119.5
expect Float.mod(119.5, -120.0) == -0.5
expect Float.mod(120.0, -120.0) == 0.0
expect Float.mod(240.5, -120.0) == -119.5
expect Float.mod(1000.0, -120.0) == -80.0
expect Float.mod(3600.25, -120.0) == -119.75

expect Float.pow2_int(-55) == F64.from_bits(4359484439294640128)
expect Float.pow2_int(-20) == F64.from_bits(4517110426252607488)
expect Float.pow2_int(-8) == 0.00390625
expect Float.pow2_int(-1) == 0.5
expect Float.pow2_int(0) == 1.0
expect Float.pow2_int(1) == 2.0
expect Float.pow2_int(8) == 256.0
expect Float.pow2_int(20) == 1048576.0
expect Float.pow2_int(55) == F64.from_bits(4854880398305394688)

# Each is within 1e-15 of its want, scaled up by a want past 1.
expect
	[
		(-100.0, F64.from_bits(3957129287720677213)),
		(-50.0, F64.from_bits(4282120040917895231)),
		(-20.0, F64.from_bits(4477057993643618919)),
		(-5.0, 0.006737946999085467),
		(-2.5, 0.0820849986238988),
		(-1.0, 0.36787944117144233),
		(-0.6931471805599453, 0.5),
		(-0.3465735902799727, 0.7071067811865475),
		(-0.34657359027997264, 0.7071067811865475),
		(-0.05, 0.951229424500714),
		(0.0, 1.0),
		(0.05, 1.0512710963760241),
		(0.3465735902799727, 1.4142135623730951),
		(0.6931471805599453, 2.0),
		(1.0, 2.7182818284590455),
		(2.5, 12.182493960703473),
		(5.0, 148.4131591025766),
		(20.0, 485165195.4097903),
	].all(|(x, want)| (Float.exp(x) - want).abs() <= 0.000000000000001 * want.abs().max(1.0))
