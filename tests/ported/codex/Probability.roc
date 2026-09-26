# Probability -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Probability :: [].{
	NormalDist := { mu : I64, sigma : I64 }.{
		is_eq : Probability.NormalDist, Probability.NormalDist -> Bool
		is_eq = |a, b| eq_NormalDist(a, b)
	}
	PoissonDist := { lambda : I64 }.{
		is_eq : Probability.PoissonDist, Probability.PoissonDist -> Bool
		is_eq = |a, b| eq_PoissonDist(a, b)
	}
	BinomialDist := { n : I64, p : I64 }.{
		is_eq : Probability.BinomialDist, Probability.BinomialDist -> Bool
		is_eq = |a, b| eq_BinomialDist(a, b)
	}
	ExponentialDist := { lambda : I64 }.{
		is_eq : Probability.ExponentialDist, Probability.ExponentialDist -> Bool
		is_eq = |a, b| eq_ExponentialDist(a, b)
	}

	prob_sqrt_2pi : I64
	prob_sqrt_2pi = 2507

	prob_scale : I64
	prob_scale = 1000

	prob_exp_neg_one : I64
	prob_exp_neg_one = 368

	normal : I64, I64 -> Probability.NormalDist
	normal = |mu, sigma| Probability.NormalDist.{ mu: mu, sigma: sigma }

	normal_standard : Probability.NormalDist
	normal_standard = Probability.NormalDist.{ mu: 0, sigma: prob_scale }

	normal_pdf : Probability.NormalDist, I64 -> I64
	normal_pdf = |d, x| ({
		z : I64
		z = I64.div_trunc_by(((x - d.mu) * prob_scale), d.sigma)
		z2 : I64
		z2 = I64.div_trunc_by((z * z), prob_scale)
		exp_term : I64
		exp_term = prob_exp_neg(I64.div_trunc_by(z2, 2))
		I64.div_trunc_by((exp_term * prob_scale), I64.div_trunc_by((d.sigma * prob_sqrt_2pi), prob_scale))
	})

	normal_cdf : Probability.NormalDist, I64 -> I64
	normal_cdf = |d, x| ({
		z : I64
		z = I64.div_trunc_by(((x - d.mu) * prob_scale), d.sigma)
		prob_standard_normal_cdf(z)
	})

	prob_standard_normal_cdf : I64 -> I64
	prob_standard_normal_cdf = |z| ({
		t : I64
		t = I64.div_trunc_by((prob_scale * prob_scale), (prob_scale + I64.div_trunc_by((2316 * (if (z < 0) { (0 - z) } else { z })), 10000)))
		poly : I64
		poly = prob_horner_cdf(t)
		density : I64
		density = prob_exp_neg(I64.div_trunc_by((z * z), (2 * prob_scale)))
		tail : I64
		tail = I64.div_trunc_by(((density * poly) + I64.div_trunc_by(prob_sqrt_2pi, 2)), prob_sqrt_2pi)
		(if (z < 0) { tail } else { (prob_scale - tail) })
	})

	prob_horner_cdf : I64 -> I64
	prob_horner_cdf = |t| ({
		a1 : I64
		a1 = 319
		a2 : I64
		a2 = (0 - 356)
		a3 : I64
		a3 = 1781
		a4 : I64
		a4 = (0 - 1821)
		a5 : I64
		a5 = 1330
		I64.div_trunc_by((t * (a1 + I64.div_trunc_by((t * (a2 + I64.div_trunc_by((t * (a3 + I64.div_trunc_by((t * (a4 + I64.div_trunc_by((t * a5), prob_scale))), prob_scale))), prob_scale))), prob_scale))), prob_scale)
	})

	poisson : I64 -> Probability.PoissonDist
	poisson = |lam| Probability.PoissonDist.{ lambda: lam }

	poisson_pmf : Probability.PoissonDist, I64 -> I64
	poisson_pmf = |d, k| (if (k < 0) { 0 } else { ({
		exp_neg_lam : I64
		exp_neg_lam = prob_exp_neg(d.lambda)
		lam_k : I64
		lam_k = prob_pow(d.lambda, k)
		k_fact : I64
		k_fact = prob_factorial(k)
		I64.div_trunc_by(I64.div_trunc_by((exp_neg_lam * lam_k), prob_scale), k_fact)
	}) })

	binomial : I64, I64 -> Probability.BinomialDist
	binomial = |trials, prob| Probability.BinomialDist.{ n: trials, p: prob }

	binomial_pmf : Probability.BinomialDist, I64 -> I64
	binomial_pmf = |d, k| (if (k < 0) { 0 } else { (if (k > d.n) { 0 } else { ({
		c : I64
		c = prob_choose(d.n, k)
		pk : I64
		pk = prob_pow(d.p, k)
		qnk : I64
		qnk = prob_pow((prob_scale - d.p), (d.n - k))
		denom : I64
		denom = prob_pow(prob_scale, d.n)
		I64.div_trunc_by(((c * pk) * qnk), denom)
	}) }) })

	binomial_mean : Probability.BinomialDist -> I64
	binomial_mean = |d| I64.div_trunc_by((d.n * d.p), prob_scale)

	binomial_variance : Probability.BinomialDist -> I64
	binomial_variance = |d| I64.div_trunc_by((I64.div_trunc_by((d.n * d.p), prob_scale) * (prob_scale - d.p)), prob_scale)

	exponential : I64 -> Probability.ExponentialDist
	exponential = |lam| Probability.ExponentialDist.{ lambda: lam }

	exponential_pdf : Probability.ExponentialDist, I64 -> I64
	exponential_pdf = |d, x| (if (x < 0) { 0 } else { I64.div_trunc_by((d.lambda * prob_exp_neg(I64.div_trunc_by((d.lambda * x), prob_scale))), prob_scale) })

	exponential_cdf : Probability.ExponentialDist, I64 -> I64
	exponential_cdf = |d, x| (if (x < 0) { 0 } else { (prob_scale - prob_exp_neg(I64.div_trunc_by((d.lambda * x), prob_scale))) })

	exponential_mean : Probability.ExponentialDist -> I64
	exponential_mean = |d| I64.div_trunc_by((prob_scale * prob_scale), d.lambda)

	uniform_bound : I64, I64, I64 -> I64
	uniform_bound = |lo, hi, seed| (if (hi <= lo) { lo } else { ({
		range : I64
		range = ((hi - lo) + 1)
		positive : I64
		positive = (if (seed < 0) { (0 - seed) } else { seed })
		(lo + (positive - (I64.div_trunc_by(positive, range) * range)))
	}) })

	prob_exp_neg : I64 -> I64
	prob_exp_neg = |x| (if (x <= 0) { prob_scale } else { (if (x > 20000) { 0 } else { ({
		whole : I64
		whole = I64.div_trunc_by(x, prob_scale)
		frac : I64
		frac = (x - (whole * prob_scale))
		prob_exp_fold(whole, prob_exp_neg_loop(frac, prob_scale, prob_scale, 1, 10))
	}) }) })

	prob_exp_fold : I64, I64 -> I64
	prob_exp_fold = |n, acc| (if (n <= 0) { acc } else { prob_exp_fold((n - 1), I64.div_trunc_by(((acc * prob_exp_neg_one) + I64.div_trunc_by(prob_scale, 2)), prob_scale)) })

	prob_exp_neg_loop : I64, I64, I64, I64, I64 -> I64
	prob_exp_neg_loop = |x, term, sum, i, max_terms| (if (i > max_terms) { sum } else { ({
		term2 : I64
		term2 = (0 - I64.div_trunc_by((term * x), (i * prob_scale)))
		prob_exp_neg_loop(x, term2, (sum + term2), (i + 1), max_terms)
	}) })

	prob_pow : I64, I64 -> I64
	prob_pow = |base, exp| (if (exp <= 0) { prob_scale } else { prob_pow_loop(base, exp, prob_scale) })

	prob_pow_loop : I64, I64, I64 -> I64
	prob_pow_loop = |base, exp, acc| (if (exp <= 0) { acc } else { prob_pow_loop(base, (exp - 1), I64.div_trunc_by((acc * base), prob_scale)) })

	prob_factorial : I64 -> I64
	prob_factorial = |n| prob_fact_loop(n, 1)

	prob_fact_loop : I64, I64 -> I64
	prob_fact_loop = |n, acc| (if (n <= 1) { acc } else { prob_fact_loop((n - 1), (acc * n)) })

	prob_choose : I64, I64 -> I64
	prob_choose = |n, k| (if (k > n) { 0 } else { (if (k == 0) { 1 } else { prob_choose_loop(n, k, 1, 0) }) })

	prob_choose_loop : I64, I64, I64, I64 -> I64
	prob_choose_loop = |n, k, acc, i| (if (i >= k) { acc } else { prob_choose_loop(n, k, I64.div_trunc_by((acc * (n - i)), (i + 1)), (i + 1)) })

	eq_NormalDist : Probability.NormalDist, Probability.NormalDist -> Bool
	eq_NormalDist = |ex, ey| ((ex.mu == ey.mu) and (ex.sigma == ey.sigma))

	eq_PoissonDist : Probability.PoissonDist, Probability.PoissonDist -> Bool
	eq_PoissonDist = |ex, ey| (ex.lambda == ey.lambda)

	eq_BinomialDist : Probability.BinomialDist, Probability.BinomialDist -> Bool
	eq_BinomialDist = |ex, ey| ((ex.n == ey.n) and (ex.p == ey.p))

	eq_ExponentialDist : Probability.ExponentialDist, Probability.ExponentialDist -> Bool
	eq_ExponentialDist = |ex, ey| (ex.lambda == ey.lambda)
}
