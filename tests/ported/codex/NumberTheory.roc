# NumberTheory -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

NumberTheory :: [].{
	ExtGcdResult := { g : I64, x : I64, y : I64 }.{
		is_eq : NumberTheory.ExtGcdResult, NumberTheory.ExtGcdResult -> Bool
		is_eq = |a, b| a.g == b.g and a.x == b.x and a.y == b.y
	}
	FactorPair := { prime : I64, power : I64 }.{
		is_eq : NumberTheory.FactorPair, NumberTheory.FactorPair -> Bool
		is_eq = |a, b| a.prime == b.prime and a.power == b.power
	}
	FactorCountResult := { remaining : I64, count : I64 }.{
		is_eq : NumberTheory.FactorCountResult, NumberTheory.FactorCountResult -> Bool
		is_eq = |a, b| a.remaining == b.remaining and a.count == b.count
	}

	gcd : I64, I64 -> I64
	gcd = |a, b| ({
		x = (if (a < 0) { (0 - a) } else { a })
		y = (if (b < 0) { (0 - b) } else { b })
		gcd_loop(x, y)
	})

	gcd_loop : I64, I64 -> I64
	gcd_loop = |a, b| (if (b == 0) { a } else { gcd_loop(b, (a - (I64.div_trunc_by(a, b) * b))) })

	lcm : I64, I64 -> I64
	lcm = |a, b| (if (a == 0) { 0 } else { (if (b == 0) { 0 } else { ({
		g = gcd(a, b)
		(I64.div_trunc_by(a, g) * b)
	}) }) })

	mod_exp : I64, I64, I64 -> I64
	mod_exp = |base, exp, m| (if (m == 1) { 0 } else { mod_exp_loop((base - (I64.div_trunc_by(base, m) * m)), exp, m, 1) })

	mod_exp_loop : I64, I64, I64, I64 -> I64
	mod_exp_loop = |base, exp, m, result| (if (exp <= 0) { result } else { (if (I64.bitwise_and(exp, 1) == 1) { ({
		r2 = ((result * base) - (I64.div_trunc_by((result * base), m) * m))
		mod_exp_loop(((base * base) - (I64.div_trunc_by((base * base), m) * m)), I64.shr_zf_wrap(exp, I64.to_u8_wrap(1)), m, r2)
	}) } else { mod_exp_loop(((base * base) - (I64.div_trunc_by((base * base), m) * m)), I64.shr_zf_wrap(exp, I64.to_u8_wrap(1)), m, result) }) })

	mod_inverse : I64, I64 -> I64
	mod_inverse = |a, m| ({
		r = extended_gcd(a, m)
		x = r.x
		(if (x < 0) { (x + m) } else { x })
	})

	extended_gcd : I64, I64 -> NumberTheory.ExtGcdResult
	extended_gcd = |a, b| (if (b == 0) { NumberTheory.ExtGcdResult.{ g: a, x: 1, y: 0 } } else { ({
		r = extended_gcd(b, (a - (I64.div_trunc_by(a, b) * b)))
		NumberTheory.ExtGcdResult.{ g: r.g, x: r.y, y: (r.x - (I64.div_trunc_by(a, b) * r.y)) }
	}) })

	is_prime : I64 -> Bool
	is_prime = |n| (if (n < 2) { False } else { (if (n < 4) { True } else { (if (I64.bitwise_and(n, 1) == 0) { False } else { (if ((n - (I64.div_trunc_by(n, 3) * 3)) == 0) { False } else { is_prime_loop(n, 5) }) }) }) })

	is_prime_loop : I64, I64 -> Bool
	is_prime_loop = |n, i| (if ((i * i) > n) { True } else { (if ((n - (I64.div_trunc_by(n, i) * i)) == 0) { False } else { (if ((n - (I64.div_trunc_by(n, (i + 2)) * (i + 2))) == 0) { False } else { is_prime_loop(n, (i + 6)) }) }) })

	primes_up_to : I64 -> List(I64)
	primes_up_to = |limit| (if (limit < 2) { [] } else { sieve_collect(limit, 2, []) })

	sieve_collect : I64, I64, List(I64) -> List(I64)
	sieve_collect = |limit, candidate, acc| (if (candidate > limit) { acc } else { (if is_prime(candidate) { sieve_collect(limit, (candidate + 1), List.append(acc, candidate)) } else { sieve_collect(limit, (candidate + 1), acc) }) })

	factor : I64 -> List(NumberTheory.FactorPair)
	factor = |n| (if (n <= 1) { [] } else { factor_loop(n, 2, []) })

	factor_loop : I64, I64, List(NumberTheory.FactorPair) -> List(NumberTheory.FactorPair)
	factor_loop = |n, d, acc| (if ((d * d) > n) { (if (n > 1) { List.append(acc, NumberTheory.FactorPair.{ prime: n, power: 1 }) } else { acc }) } else { (if ((n - (I64.div_trunc_by(n, d) * d)) == 0) { ({
		r = factor_count(n, d, 0)
		factor_loop(r.remaining, (d + 1), List.append(acc, NumberTheory.FactorPair.{ prime: d, power: r.count }))
	}) } else { factor_loop(n, (d + 1), acc) }) })

	factor_count : I64, I64, I64 -> NumberTheory.FactorCountResult
	factor_count = |n, d, c| (if ((n - (I64.div_trunc_by(n, d) * d)) == 0) { factor_count(I64.div_trunc_by(n, d), d, (c + 1)) } else { NumberTheory.FactorCountResult.{ remaining: n, count: c } })

	euler_totient : I64 -> I64
	euler_totient = |n| (if (n <= 1) { 1 } else { euler_totient_loop(n, n, 2) })

	euler_totient_loop : I64, I64, I64 -> I64
	euler_totient_loop = |n, result, p| (if ((p * p) > n) { (if (n > 1) { (result - I64.div_trunc_by(result, n)) } else { result }) } else { (if ((n - (I64.div_trunc_by(n, p) * p)) == 0) { ({
		n2 = euler_drain(n, p)
		euler_totient_loop(n2, (result - I64.div_trunc_by(result, p)), (p + 1))
	}) } else { euler_totient_loop(n, result, (p + 1)) }) })

	euler_drain : I64, I64 -> I64
	euler_drain = |n, p| (if (n <= 0) { 0 } else { (if ((n - (I64.div_trunc_by(n, p) * p)) == 0) { euler_drain(I64.div_trunc_by(n, p), p) } else { n }) })
}
