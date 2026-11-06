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
