# Oscillator -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Random
import Units

Oscillator :: [].{
	OscBank : { ob_oscs : List(Oscillator.OscState), ob_count : I64, ob_sample_rate : Units.Frequency }
	OscState : { osc_freq : Units.Frequency, osc_phase : I64, osc_amp : I64, osc_type : I64, osc_param : I64 }

	osc_type_sine : I64
	osc_type_sine = 0

	osc_type_square : I64
	osc_type_square = 1

	osc_type_saw : I64
	osc_type_saw = 2

	osc_type_tri : I64
	osc_type_tri = 3

	osc_type_pulse : I64
	osc_type_pulse = 4

	osc_type_noise : I64
	osc_type_noise = 5

	osc_bank_new : Units.Frequency -> Oscillator.OscBank
	osc_bank_new = |sr| { ob_oscs: [], ob_count: 0, ob_sample_rate: sr }

	osc_add : Oscillator.OscBank, Units.Frequency, I64, I64, I64 -> Oscillator.OscBank
	osc_add = |bank, freq, amp, wave_type, param| ({
		osc = { osc_freq: freq, osc_phase: 0, osc_amp: amp, osc_type: wave_type, osc_param: param }
		{ ob_oscs: List.append(bank.ob_oscs, osc), ob_count: (bank.ob_count + 1), ob_sample_rate: bank.ob_sample_rate }
	})

	osc_eval : Oscillator.OscState, I64, I64 -> I64
	osc_eval = |osc, phase, idx| (if (osc.osc_type == osc_type_sine) { osc_sine_val(phase, osc.osc_amp) } else { (if (osc.osc_type == osc_type_square) { osc_square_val(phase, osc.osc_amp) } else { (if (osc.osc_type == osc_type_saw) { osc_saw_val(phase, osc.osc_amp) } else { (if (osc.osc_type == osc_type_tri) { osc_tri_val(phase, osc.osc_amp) } else { (if (osc.osc_type == osc_type_pulse) { osc_pulse_val(phase, osc.osc_amp, osc.osc_param) } else { (if (osc.osc_type == osc_type_noise) { osc_noise_val(idx, osc.osc_amp) } else { 0 }) }) }) }) }) })

	osc_sine_val : I64, I64 -> I64
	osc_sine_val = |phase, amp| ({
		x = phase
		x3 = I64.div_trunc_by((I64.div_trunc_by((x * x), 1000) * x), 1000)
		x5 = I64.div_trunc_by((I64.div_trunc_by((x3 * x), 1000) * x), 1000)
		I64.div_trunc_by((amp * ((x - I64.div_trunc_by(x3, 6)) + I64.div_trunc_by(x5, 120))), 1000)
	})

	osc_square_val : I64, I64 -> I64
	osc_square_val = |phase, amp| (if (phase >= 0) { amp } else { (-amp) })

	osc_saw_val : I64, I64 -> I64
	osc_saw_val = |phase, amp| I64.div_trunc_by((amp * phase), 3142)

	osc_tri_val : I64, I64 -> I64
	osc_tri_val = |phase, amp| ({
		abs_p = (if (phase < 0) { (-phase) } else { phase })
		I64.div_trunc_by((amp * (3142 - (2 * abs_p))), 3142)
	})

	osc_pulse_val : I64, I64, I64 -> I64
	osc_pulse_val = |phase, amp, duty| ({
		threshold = (I64.div_trunc_by((duty * 6283), 1000) - 3142)
		(if (phase < threshold) { amp } else { (-amp) })
	})

	osc_noise_val : I64, I64 -> I64
	osc_noise_val = |idx, amp| ({
		hash = Random.mix_bits(idx, 9173)
		positive = (if (hash < 0) { (-hash) } else { hash })
		normalized = ((positive - (I64.div_trunc_by(positive, 2000) * 2000)) - 1000)
		I64.div_trunc_by((amp * normalized), 1000)
	})

	osc_phase_at : I64, I64, I64 -> I64
	osc_phase_at = |freq, sample_idx, sample_rate| ({
		period = I64.div_trunc_by((sample_rate * 1000), freq)
		pos = I64.div_trunc_by(((sample_idx * 1000) * 6283), period)
		wrapped = (pos - (I64.div_trunc_by(pos, 6283) * 6283))
		(wrapped - 3142)
	})

	osc_bank_render : Oscillator.OscBank, I64 -> List(I64)
	osc_bank_render = |bank, num_samples| osc_bank_loop(bank, num_samples, 0, [])

	osc_bank_loop : Oscillator.OscBank, I64, I64, List(I64) -> List(I64)
	osc_bank_loop = |bank, n, i, acc| (if (i >= n) { acc } else { ({
		sample = osc_bank_sample(bank, i)
		osc_bank_loop(bank, n, (i + 1), List.append(acc, sample))
	}) })

	osc_bank_sample : Oscillator.OscBank, I64 -> I64
	osc_bank_sample = |bank, sample_idx| osc_mix_loop(bank.ob_oscs, bank.ob_sample_rate, sample_idx, 0, bank.ob_count, 0)

	osc_mix_loop : List(Oscillator.OscState), I64, I64, I64, I64, I64 -> I64
	osc_mix_loop = |oscs, sr, idx, i, n, acc| (if (i >= n) { acc } else { ({
		osc = (List.get(oscs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		phase = osc_phase_at(osc.osc_freq, idx, sr)
		val = osc_eval(osc, phase, idx)
		osc_mix_loop(oscs, sr, idx, (i + 1), n, (acc + val))
	}) })

	osc_fm : I64, I64, I64, I64, I64, I64 -> I64
	osc_fm = |carrier_freq, mod_freq, mod_depth, amp, sample_idx, sr| ({
		mod_phase = osc_phase_at(mod_freq, sample_idx, sr)
		mod_val = osc_sine_val(mod_phase, mod_depth)
		inst_freq = (carrier_freq + mod_val)
		car_phase = osc_phase_at(inst_freq, sample_idx, sr)
		osc_sine_val(car_phase, amp)
	})

	osc_fm_render : I64, I64, I64, I64, I64, I64 -> List(I64)
	osc_fm_render = |carrier, modulator, depth, amp, sr, n| osc_fm_loop(carrier, modulator, depth, amp, sr, n, 0, [])

	osc_fm_loop : I64, I64, I64, I64, I64, I64, I64, List(I64) -> List(I64)
	osc_fm_loop = |car, mod, depth, amp, sr, n, i, acc| (if (i >= n) { acc } else { ({
		val = osc_fm(car, mod, depth, amp, i, sr)
		osc_fm_loop(car, mod, depth, amp, sr, n, (i + 1), List.append(acc, val))
	}) })

	osc_ring_mod : List(I64), List(I64) -> List(I64)
	osc_ring_mod = |a, b| osc_ring_loop(a, b, 0, osc_min_len(U64.to_i64_wrap(List.len(a)), U64.to_i64_wrap(List.len(b))), [])

	osc_ring_loop : List(I64), List(I64), I64, I64, List(I64) -> List(I64)
	osc_ring_loop = |a, b, i, n, acc| (if (i >= n) { acc } else { ({
		val = I64.div_trunc_by(((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), 1000)
		osc_ring_loop(a, b, (i + 1), n, List.append(acc, val))
	}) })

	osc_min_len : I64, I64 -> I64
	osc_min_len = |a, b| (if (a < b) { a } else { b })

	osc_peak : List(I64) -> I64
	osc_peak = |samples| osc_peak_loop(samples, 0, U64.to_i64_wrap(List.len(samples)), 0)

	osc_peak_loop : List(I64), I64, I64, I64 -> I64
	osc_peak_loop = |samples, i, n, best| (if (i >= n) { best } else { ({
		v = (List.get(samples, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		abs_v = (if (v < 0) { (-v) } else { v })
		osc_peak_loop(samples, (i + 1), n, (if (abs_v > best) { abs_v } else { best }))
	}) })
}
