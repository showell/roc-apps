# Numeric -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Numeric :: [].{
	SimpsonSums := { odd : I64, even : I64 }.{
		is_eq : Numeric.SimpsonSums, Numeric.SimpsonSums -> Bool
		is_eq = |a, b| eq_SimpsonSums(a, b)
	}
	Rk4State := { rk_t : I64, rk_y : I64 }.{
		is_eq : Numeric.Rk4State, Numeric.Rk4State -> Bool
		is_eq = |a, b| eq_Rk4State(a, b)
	}
	Rk4VecState := { rkv_t : I64, rkv_y : List(I64) }.{
		is_eq : Numeric.Rk4VecState, Numeric.Rk4VecState -> Bool
		is_eq = |a, b| eq_Rk4VecState(a, b)
	}

	bisect : (I64 -> I64), I64, I64, I64 -> I64
	bisect = |f, a, b, max_iter| bisect_loop(f, a, b, max_iter, 0)

	bisect_loop : (I64 -> I64), I64, I64, I64, I64 -> I64
	bisect_loop = |f, a, b, max_iter, i| (if (i >= max_iter) { I64.div_trunc_by((a + b), 2) } else { ({
		mid : I64
		mid = I64.div_trunc_by((a + b), 2)
		fa : I64
		fa = f(a)
		fm : I64
		fm = f(mid)
		(if (fm == 0) { mid } else { (if ((fa * fm) < 0) { bisect_loop(f, a, mid, max_iter, (i + 1)) } else { bisect_loop(f, mid, b, max_iter, (i + 1)) }) })
	}) })

	newton : (I64 -> I64), (I64 -> I64), I64, I64 -> I64
	newton = |f, df, x0, max_iter| newton_loop(f, df, x0, max_iter, 0)

	newton_loop : (I64 -> I64), (I64 -> I64), I64, I64, I64 -> I64
	newton_loop = |f, df, x, max_iter, i| (if (i >= max_iter) { x } else { ({
		fx : I64
		fx = f(x)
		dfx : I64
		dfx = df(x)
		(if (dfx == 0) { x } else { ({
			x_next : I64
			x_next = (x - I64.div_trunc_by((fx * 1000), dfx))
			(if (num_abs((x_next - x)) < 1) { x_next } else { newton_loop(f, df, x_next, max_iter, (i + 1)) })
		}) })
	}) })

	integrate_simpson : (I64 -> I64), I64, I64, I64 -> I64
	integrate_simpson = |f, a, b, n| ({
		steps : I64
		steps = (if ((n - (I64.div_trunc_by(n, 2) * 2)) == 0) { n } else { (n + 1) })
		h : I64
		h = I64.div_trunc_by(((b - a) * 1000), steps)
		fa : I64
		fa = f(a)
		fb : I64
		fb = f(b)
		interior = simpson_loop(f, a, h, steps, 1, 0, 0)
		I64.div_trunc_by(((((fa + fb) + (4 * interior.odd)) + (2 * interior.even)) * h), ((3 * 1000) * 1000))
	})

	simpson_loop : (I64 -> I64), I64, I64, I64, I64, I64, I64 -> Numeric.SimpsonSums
	simpson_loop = |f, a, h, n, i, odd_sum, even_sum| (if (i >= n) { Numeric.SimpsonSums.{ odd: odd_sum, even: even_sum } } else { ({
		x : I64
		x = (a + I64.div_trunc_by((i * h), 1000))
		fx : I64
		fx = f(x)
		(if ((i - (I64.div_trunc_by(i, 2) * 2)) == 1) { simpson_loop(f, a, h, n, (i + 1), (odd_sum + fx), even_sum) } else { simpson_loop(f, a, h, n, (i + 1), odd_sum, (even_sum + fx)) })
	}) })

	integrate_trapezoid : (I64 -> I64), I64, I64, I64 -> I64
	integrate_trapezoid = |f, a, b, n| ({
		h : I64
		h = I64.div_trunc_by(((b - a) * 1000), n)
		fa : I64
		fa = f(a)
		fb : I64
		fb = f(b)
		interior : I64
		interior = trap_loop(f, a, h, n, 1, 0)
		I64.div_trunc_by((((fa + fb) + (2 * interior)) * h), ((2 * 1000) * 1000))
	})

	trap_loop : (I64 -> I64), I64, I64, I64, I64, I64 -> I64
	trap_loop = |f, a, h, n, i, acc| (if (i >= n) { acc } else { ({
		x : I64
		x = (a + I64.div_trunc_by((i * h), 1000))
		trap_loop(f, a, h, n, (i + 1), (acc + f(x)))
	}) })

	rk4_step : (I64, I64 -> I64), I64, I64, I64 -> Numeric.Rk4State
	rk4_step = |f, t, y, h| ({
		k1 : I64
		k1 = f(t, y)
		k2 : I64
		k2 = f((t + I64.div_trunc_by(h, 2)), (y + I64.div_trunc_by((h * k1), (2 * 1000))))
		k3 : I64
		k3 = f((t + I64.div_trunc_by(h, 2)), (y + I64.div_trunc_by((h * k2), (2 * 1000))))
		k4 : I64
		k4 = f((t + h), (y + I64.div_trunc_by((h * k3), 1000)))
		y_next : I64
		y_next = (y + I64.div_trunc_by((h * (((k1 + (2 * k2)) + (2 * k3)) + k4)), (6 * 1000)))
		Numeric.Rk4State.{ rk_t: (t + h), rk_y: y_next }
	})

	rk4_solve : (I64, I64 -> I64), I64, I64, I64, I64 -> List(Numeric.Rk4State)
	rk4_solve = |f, t0, y0, t_end, steps| ({
		h : I64
		h = I64.div_trunc_by(((t_end - t0) * 1000), steps)
		rk4_solve_loop(f, t0, y0, h, steps, 0, [Numeric.Rk4State.{ rk_t: t0, rk_y: y0 }])
	})

	rk4_solve_loop : (I64, I64 -> I64), I64, I64, I64, I64, I64, List(Numeric.Rk4State) -> List(Numeric.Rk4State)
	rk4_solve_loop = |f, t, y, h, steps, i, acc| (if (i >= steps) { acc } else { ({
		next = rk4_step(f, t, y, h)
		rk4_solve_loop(f, next.rk_t, next.rk_y, h, steps, (i + 1), List.append(acc, next))
	}) })

	rk4_vec_step : (I64, List(I64) -> List(I64)), I64, List(I64), I64 -> Numeric.Rk4VecState
	rk4_vec_step = |f, t, y, h| ({
		n : I64
		n = U64.to_i64_wrap(List.len(y))
		k1 : List(I64)
		k1 = f(t, y)
		y2 : List(I64)
		y2 = rk4_vec_add(y, k1, I64.div_trunc_by(h, 2), n)
		k2 : List(I64)
		k2 = f((t + I64.div_trunc_by(h, 2)), y2)
		y3 : List(I64)
		y3 = rk4_vec_add(y, k2, I64.div_trunc_by(h, 2), n)
		k3 : List(I64)
		k3 = f((t + I64.div_trunc_by(h, 2)), y3)
		y4 : List(I64)
		y4 = rk4_vec_add(y, k3, h, n)
		k4 : List(I64)
		k4 = f((t + h), y4)
		y_next : List(I64)
		y_next = rk4_vec_combine(y, k1, k2, k3, k4, h, n, 0, [])
		Numeric.Rk4VecState.{ rkv_t: (t + h), rkv_y: y_next }
	})

	rk4_vec_add : List(I64), List(I64), I64, I64 -> List(I64)
	rk4_vec_add = |y, k, scale, n| rk4_va_loop(y, k, scale, n, 0, [])

	rk4_va_loop : List(I64), List(I64), I64, I64, I64, List(I64) -> List(I64)
	rk4_va_loop = |y, k, scale, n, i, acc| (if (i >= n) { acc } else { rk4_va_loop(y, k, scale, n, (i + 1), List.append(acc, ((List.get(y, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) + I64.div_trunc_by((scale * (List.get(k, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), 1000)))) })

	rk4_vec_combine : List(I64), List(I64), List(I64), List(I64), List(I64), I64, I64, I64, List(I64) -> List(I64)
	rk4_vec_combine = |y, k1, k2, k3, k4, h, n, i, acc| (if (i >= n) { acc } else { ({
		dy : I64
		dy = I64.div_trunc_by((((((List.get(k1, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) + (2 * (List.get(k2, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) + (2 * (List.get(k3, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) + (List.get(k4, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) * h), (6 * 1000))
		rk4_vec_combine(y, k1, k2, k3, k4, h, n, (i + 1), List.append(acc, ((List.get(y, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) + dy)))
	}) })

	num_abs : I64 -> I64
	num_abs = |x| (if (x < 0) { (0 - x) } else { x })

	eq_SimpsonSums : Numeric.SimpsonSums, Numeric.SimpsonSums -> Bool
	eq_SimpsonSums = |ex, ey| ((ex.odd == ey.odd) and (ex.even == ey.even))

	eq_Rk4State : Numeric.Rk4State, Numeric.Rk4State -> Bool
	eq_Rk4State = |ex, ey| ((ex.rk_t == ey.rk_t) and (ex.rk_y == ey.rk_y))

	eq_Rk4VecState : Numeric.Rk4VecState, Numeric.Rk4VecState -> Bool
	eq_Rk4VecState = |ex, ey| ((ex.rkv_t == ey.rkv_t) and (ex.rkv_y == ey.rkv_y))
}
