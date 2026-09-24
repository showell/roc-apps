# DiffusionScheduler -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import MathLib

DiffusionScheduler :: [].{
	NoiseSchedule : { ns_betas : List(I64), ns_alphas : List(I64), ns_alpha_cumprod : List(I64), ns_steps : I64 }

	linear_schedule : I64, I64, I64 -> DiffusionScheduler.NoiseSchedule
	linear_schedule = |steps, beta_start, beta_end| ({
		betas = ns_build_linear(steps, beta_start, beta_end, 0, [])
		alphas = ns_compute_alphas(betas, 0, steps, [])
		alpha_cp = ns_compute_cumprod(alphas, 0, steps, 1000, [])
		{ ns_betas: betas, ns_alphas: alphas, ns_alpha_cumprod: alpha_cp, ns_steps: steps }
	})

	ns_build_linear : I64, I64, I64, I64, List(I64) -> List(I64)
	ns_build_linear = |steps, start, stop, i, acc| (if (i >= steps) { acc } else { ({
		beta = (start + I64.div_trunc_by(((stop - start) * i), (steps - 1)))
		ns_build_linear(steps, start, stop, (i + 1), List.append(acc, beta))
	}) })

	cosine_schedule : I64 -> DiffusionScheduler.NoiseSchedule
	cosine_schedule = |steps| ({
		alpha_cp = ns_build_cosine(steps, 0, [])
		betas = ns_cumprod_to_betas(alpha_cp, 0, steps, [])
		alphas = ns_compute_alphas(betas, 0, steps, [])
		{ ns_betas: betas, ns_alphas: alphas, ns_alpha_cumprod: alpha_cp, ns_steps: steps }
	})

	ns_build_cosine : I64, I64, List(I64) -> List(I64)
	ns_build_cosine = |steps, i, acc| (if (i >= steps) { acc } else { ({
		t = I64.div_trunc_by((i * 1000), steps)
		angle = I64.div_trunc_by(((t + 8) * 1571), 1008)
		cos_val = ns_cos(angle)
		alpha_bar = I64.div_trunc_by((cos_val * cos_val), 1000)
		clamped = (if (alpha_bar < 1) { 1 } else { (if (alpha_bar > 999) { 999 } else { alpha_bar }) })
		ns_build_cosine(steps, (i + 1), List.append(acc, clamped))
	}) })

	ns_cumprod_to_betas : List(I64), I64, I64, List(I64) -> List(I64)
	ns_cumprod_to_betas = |acp, i, n, acc| (if (i >= n) { acc } else { ({
		prev = (if (i == 0) { 1000 } else { (List.get(acp, I64.to_u64_wrap((i - 1))) ?? crash("list-at out of range")) })
		cur = (List.get(acp, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		beta = (if (prev == 0) { 0 } else { (1000 - I64.div_trunc_by((cur * 1000), prev)) })
		clamped = (if (beta < 1) { 1 } else { (if (beta > 999) { 999 } else { beta }) })
		ns_cumprod_to_betas(acp, (i + 1), n, List.append(acc, clamped))
	}) })

	diffusion_add_noise : List(I64), List(I64), I64, DiffusionScheduler.NoiseSchedule -> List(I64)
	diffusion_add_noise = |x0, noise, t, schedule| ({
		alpha_bar = (List.get(schedule.ns_alpha_cumprod, I64.to_u64_wrap(t)) ?? crash("list-at out of range"))
		sqrt_ab = MathLib.math_isqrt((alpha_bar * 1000))
		sqrt_one_minus = MathLib.math_isqrt(((1000 - alpha_bar) * 1000))
		ns_noise_mix(x0, noise, sqrt_ab, sqrt_one_minus, 0, U64.to_i64_wrap(List.len(x0)), [])
	})

	ns_noise_mix : List(I64), List(I64), I64, I64, I64, I64, List(I64) -> List(I64)
	ns_noise_mix = |x0, noise, sa, sn, i, n, acc| (if (i >= n) { acc } else { ({
		val = (I64.div_trunc_by(((List.get(x0, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * sa), 1000) + I64.div_trunc_by(((List.get(noise, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * sn), 1000))
		ns_noise_mix(x0, noise, sa, sn, (i + 1), n, List.append(acc, val))
	}) })

	diffusion_reverse_step : List(I64), List(I64), I64, DiffusionScheduler.NoiseSchedule -> List(I64)
	diffusion_reverse_step = |xt, predicted_noise, t, schedule| ({
		beta = (List.get(schedule.ns_betas, I64.to_u64_wrap(t)) ?? crash("list-at out of range"))
		alpha = (List.get(schedule.ns_alphas, I64.to_u64_wrap(t)) ?? crash("list-at out of range"))
		alpha_bar = (List.get(schedule.ns_alpha_cumprod, I64.to_u64_wrap(t)) ?? crash("list-at out of range"))
		sqrt_alpha = MathLib.math_isqrt((alpha * 1000))
		coeff = I64.div_trunc_by((beta * 1000), MathLib.math_isqrt(((1000 - alpha_bar) * 1000)))
		ns_denoise_step(xt, predicted_noise, sqrt_alpha, coeff, 0, U64.to_i64_wrap(List.len(xt)), [])
	})

	ns_denoise_step : List(I64), List(I64), I64, I64, I64, I64, List(I64) -> List(I64)
	ns_denoise_step = |xt, noise, sa, coeff, i, n, acc| (if (i >= n) { acc } else { ({
		val = I64.div_trunc_by((((List.get(xt, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) - I64.div_trunc_by(((List.get(noise, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * coeff), 1000)) * 1000), sa)
		ns_denoise_step(xt, noise, sa, coeff, (i + 1), n, List.append(acc, val))
	}) })

	diffusion_ddim_step : List(I64), List(I64), I64, I64, DiffusionScheduler.NoiseSchedule -> List(I64)
	diffusion_ddim_step = |xt, predicted_noise, t, t_prev, schedule| ({
		at = (List.get(schedule.ns_alpha_cumprod, I64.to_u64_wrap(t)) ?? crash("list-at out of range"))
		ap = (if (t_prev >= 0) { (List.get(schedule.ns_alpha_cumprod, I64.to_u64_wrap(t_prev)) ?? crash("list-at out of range")) } else { 1000 })
		sqrt_at = MathLib.math_isqrt((at * 1000))
		sqrt_ap = MathLib.math_isqrt((ap * 1000))
		sqrt_one_minus_at = MathLib.math_isqrt(((1000 - at) * 1000))
		ns_ddim_combine(xt, predicted_noise, sqrt_at, sqrt_ap, sqrt_one_minus_at, 0, U64.to_i64_wrap(List.len(xt)), [])
	})

	ns_ddim_combine : List(I64), List(I64), I64, I64, I64, I64, I64, List(I64) -> List(I64)
	ns_ddim_combine = |xt, noise, sat, sap, somat, i, n, acc| (if (i >= n) { acc } else { ({
		x0_pred = (if (somat == 0) { (List.get(xt, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) } else { I64.div_trunc_by((((List.get(xt, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) - I64.div_trunc_by(((List.get(noise, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * somat), 1000)) * 1000), sat) })
		val = I64.div_trunc_by((x0_pred * sap), 1000)
		ns_ddim_combine(xt, noise, sat, sap, somat, (i + 1), n, List.append(acc, val))
	}) })

	ns_compute_alphas : List(I64), I64, I64, List(I64) -> List(I64)
	ns_compute_alphas = |betas, i, n, acc| (if (i >= n) { acc } else { ns_compute_alphas(betas, (i + 1), n, List.append(acc, (1000 - (List.get(betas, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	ns_compute_cumprod : List(I64), I64, I64, I64, List(I64) -> List(I64)
	ns_compute_cumprod = |alphas, i, n, running, acc| (if (i >= n) { acc } else { ({
		new_val = I64.div_trunc_by((running * (List.get(alphas, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), 1000)
		ns_compute_cumprod(alphas, (i + 1), n, new_val, List.append(acc, new_val))
	}) })

	ns_cos : I64 -> I64
	ns_cos = |x| ({
		x2 = I64.div_trunc_by((x * x), 1000)
		x4 = I64.div_trunc_by((x2 * x2), 1000)
		((1000 - I64.div_trunc_by(x2, 2)) + I64.div_trunc_by(x4, 24))
	})

	schedule_snr : DiffusionScheduler.NoiseSchedule, I64 -> I64
	schedule_snr = |schedule, t| ({
		abar = (List.get(schedule.ns_alpha_cumprod, I64.to_u64_wrap(t)) ?? crash("list-at out of range"))
		(if (abar >= 1000) { 999999 } else { I64.div_trunc_by((abar * 1000), (1000 - abar)) })
	})

	format_schedule : DiffusionScheduler.NoiseSchedule -> CceText
	format_schedule = |s| CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("steps=", CceText.show_int(s.ns_steps)), " beta[0]="), CceText.show_int((List.get(s.ns_betas, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))), " beta[-1]="), CceText.show_int((List.get(s.ns_betas, I64.to_u64_wrap((s.ns_steps - 1))) ?? crash("list-at out of range")))), " abar[-1]="), CceText.show_int((List.get(s.ns_alpha_cumprod, I64.to_u64_wrap((s.ns_steps - 1))) ?? crash("list-at out of range"))))
}
