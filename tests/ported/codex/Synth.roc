# Synth -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Envelope
import MathLib
import Units

Synth :: [].{
	WaveType : [WaveSine, WaveSquare, WaveSaw, WaveTriangle]
	LpfState := { lpf_prev : I64, lpf_alpha : I64 }.{
		is_eq : Synth.LpfState, Synth.LpfState -> Bool
		is_eq = |a, b| eq_LpfState(a, b)
	}
	Note := { note_freq : Units.Frequency, note_start : I64, note_duration : I64, note_wave : Synth.WaveType }.{
		is_eq : Synth.Note, Synth.Note -> Bool
		is_eq = |a, b| eq_Note(a, b)
	}

	osc_sine : I64, I64 -> I64
	osc_sine = |phase, amplitude| ({
		x : I64
		x = phase
		x3 : I64
		x3 = I64.div_trunc_by((I64.div_trunc_by((x * x), 1000) * x), 1000)
		x5 : I64
		x5 = I64.div_trunc_by((I64.div_trunc_by((x3 * x), 1000) * x), 1000)
		I64.div_trunc_by((amplitude * ((x - I64.div_trunc_by(x3, 6)) + I64.div_trunc_by(x5, 120))), 1000)
	})

	osc_square : I64, I64 -> I64
	osc_square = |phase, amplitude| (if (phase >= 0) { amplitude } else { (-amplitude) })

	osc_saw : I64, I64 -> I64
	osc_saw = |phase, amplitude| I64.div_trunc_by((amplitude * phase), 3142)

	osc_triangle : I64, I64 -> I64
	osc_triangle = |phase, amplitude| ({
		abs_phase : I64
		abs_phase = (if (phase < 0) { (-phase) } else { phase })
		I64.div_trunc_by((amplitude * (3142 - (2 * abs_phase))), 3142)
	})

	synth_phase : I64, I64, I64 -> I64
	synth_phase = |freq, sample_idx, sample_rate| ({
		period : I64
		period = I64.div_trunc_by((sample_rate * 1000), freq)
		pos : I64
		pos = I64.div_trunc_by(((sample_idx * 1000) * 6283), period)
		wrapped : I64
		wrapped = (pos - (I64.div_trunc_by(pos, 6283) * 6283))
		(wrapped - 3142)
	})

	synth_sample : Synth.WaveType, I64, I64 -> I64
	synth_sample = |wave, phase, amp| (match wave {
		WaveSine => osc_sine(phase, amp)
		WaveSquare => osc_square(phase, amp)
		WaveSaw => osc_saw(phase, amp)
		WaveTriangle => osc_triangle(phase, amp)
	})

	synth_generate : Synth.WaveType, Units.Frequency, I64, Units.Frequency, I64 -> List(I64)
	synth_generate = |wave, freq, amp, sample_rate, num_samples| synth_gen_loop(wave, freq, amp, sample_rate, num_samples, 0, [])

	synth_gen_loop : Synth.WaveType, I64, I64, I64, I64, I64, List(I64) -> List(I64)
	synth_gen_loop = |wave, freq, amp, sr, n, i, acc| (if (i >= n) { acc } else { ({
		phase : I64
		phase = synth_phase(freq, i, sr)
		synth_gen_loop(wave, freq, amp, sr, n, (i + 1), List.append(acc, synth_sample(wave, phase, amp)))
	}) })

	lpf_new : I64 -> Synth.LpfState
	lpf_new = |alpha| Synth.LpfState.{ lpf_prev: 0, lpf_alpha: alpha }

	lpf_tick : Synth.LpfState, I64 -> Synth.LpfState
	lpf_tick = |state, input| ({
		a : I64
		a = state.lpf_alpha
		out : I64
		out = I64.div_trunc_by(((a * input) + ((1000 - a) * state.lpf_prev)), 1000)
		Synth.LpfState.{ lpf_prev: out, lpf_alpha: a }
	})

	lpf_value : Synth.LpfState -> I64
	lpf_value = |state| state.lpf_prev

	lpf_apply : I64, List(I64) -> List(I64)
	lpf_apply = |alpha, samples| lpf_apply_loop(lpf_new(alpha), samples, 0, U64.to_i64_wrap(List.len(samples)), [])

	lpf_apply_loop : Synth.LpfState, List(I64), I64, I64, List(I64) -> List(I64)
	lpf_apply_loop = |state, samples, i, n, acc| (if (i >= n) { acc } else { ({
		new_state = lpf_tick(state, (List.get(samples, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))
		lpf_apply_loop(new_state, samples, (i + 1), n, List.append(acc, lpf_value(new_state)))
	}) })

	mix_signals : List(I64), List(I64), I64, I64 -> List(I64)
	mix_signals = |a, b, vol_a, vol_b| mix_loop(a, b, vol_a, vol_b, 0, synth_min_len(U64.to_i64_wrap(List.len(a)), U64.to_i64_wrap(List.len(b))), [])

	mix_loop : List(I64), List(I64), I64, I64, I64, I64, List(I64) -> List(I64)
	mix_loop = |a, b, va, vb, i, n, acc| (if (i >= n) { acc } else { ({
		mixed : I64
		mixed = (I64.div_trunc_by(((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * va), 1000) + I64.div_trunc_by(((List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * vb), 1000))
		mix_loop(a, b, va, vb, (i + 1), n, List.append(acc, mixed))
	}) })

	synth_min_len : I64, I64 -> I64
	synth_min_len = |a, b| (if (a < b) { a } else { b })

	mix_scale : List(I64), I64 -> List(I64)
	mix_scale = |samples, vol| mix_scale_loop(samples, vol, 0, U64.to_i64_wrap(List.len(samples)), [])

	mix_scale_loop : List(I64), I64, I64, I64, List(I64) -> List(I64)
	mix_scale_loop = |samples, vol, i, n, acc| (if (i >= n) { acc } else { mix_scale_loop(samples, vol, (i + 1), n, List.append(acc, I64.div_trunc_by(((List.get(samples, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * vol), 1000))) })

	synth_apply_env : List(I64), Envelope.AdsrEnvelope, I64, I64 -> List(I64)
	synth_apply_env = |samples, env, sample_rate, note_off_sample| synth_env_loop(samples, env, sample_rate, note_off_sample, 0, U64.to_i64_wrap(List.len(samples)), [])

	synth_env_loop : List(I64), Envelope.AdsrEnvelope, I64, I64, I64, I64, List(I64) -> List(I64)
	synth_env_loop = |samples, env, sr, note_off, i, n, acc| (if (i >= n) { acc } else { ({
		time : I64
		time = I64.div_trunc_by((i * 1000), sr)
		released : Bool
		released = (i >= note_off)
		note_off_time : I64
		note_off_time = I64.div_trunc_by((note_off * 1000), sr)
		amp : I64
		amp = Envelope.adsr_eval(env, time, note_off_time, released)
		val : I64
		val = I64.div_trunc_by(((List.get(samples, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * amp), 1000)
		synth_env_loop(samples, env, sr, note_off, (i + 1), n, List.append(acc, val))
	}) })

	note_new : Units.Frequency, I64, I64, Synth.WaveType -> Synth.Note
	note_new = |freq, start, dur, wave| Synth.Note.{ note_freq: freq, note_start: start, note_duration: dur, note_wave: wave }

	synth_render_note : Synth.Note, I64, I64, Envelope.AdsrEnvelope -> List(I64)
	synth_render_note = |note, amp, sample_rate, env| ({
		total_samples : I64
		total_samples = I64.div_trunc_by(((note.note_duration + env.env_release) * sample_rate), 1000)
		raw : List(I64)
		raw = synth_generate(note.note_wave, note.note_freq, amp, sample_rate, total_samples)
		note_off : I64
		note_off = I64.div_trunc_by((note.note_duration * sample_rate), 1000)
		synth_apply_env(raw, env, sample_rate, note_off)
	})

	synth_peak : List(I64) -> I64
	synth_peak = |samples| synth_peak_loop(samples, 0, U64.to_i64_wrap(List.len(samples)), 0)

	synth_peak_loop : List(I64), I64, I64, I64 -> I64
	synth_peak_loop = |samples, i, n, best| (if (i >= n) { best } else { ({
		v : I64
		v = (List.get(samples, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		abs_v : I64
		abs_v = (if (v < 0) { (-v) } else { v })
		synth_peak_loop(samples, (i + 1), n, (if (abs_v > best) { abs_v } else { best }))
	}) })

	synth_rms : List(I64) -> I64
	synth_rms = |samples| ({
		n : I64
		n = U64.to_i64_wrap(List.len(samples))
		(if (n == 0) { 0 } else { ({
			sum_sq : I64
			sum_sq = synth_sum_sq(samples, 0, n, 0)
			MathLib.math_isqrt(I64.div_trunc_by(sum_sq, n))
		}) })
	})

	synth_sum_sq : List(I64), I64, I64, I64 -> I64
	synth_sum_sq = |samples, i, n, acc| (if (i >= n) { acc } else { ({
		v : I64
		v = (List.get(samples, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		synth_sum_sq(samples, (i + 1), n, (acc + I64.div_trunc_by((v * v), 1000)))
	}) })

	synth_zero_crossings : List(I64) -> I64
	synth_zero_crossings = |samples| ({
		n : I64
		n = U64.to_i64_wrap(List.len(samples))
		(if (n < 2) { 0 } else { synth_zc_loop(samples, 1, n, 0) })
	})

	synth_zc_loop : List(I64), I64, I64, I64 -> I64
	synth_zc_loop = |samples, i, n, count| (if (i >= n) { count } else { ({
		prev : I64
		prev = (List.get(samples, I64.to_u64_wrap((i - 1))) ?? crash("list-at out of range"))
		curr : I64
		curr = (List.get(samples, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		crossed : Bool
		crossed = (if (prev >= 0) { (curr < 0) } else { (curr >= 0) })
		synth_zc_loop(samples, (i + 1), n, (if crossed { (count + 1) } else { count }))
	}) })

	eq_WaveType : Synth.WaveType, Synth.WaveType -> Bool
	eq_WaveType = |ex, ey| (match ex {
		WaveSine => (match ey {
			WaveSine => True
			_ => False
		})
		WaveSquare => (match ey {
			WaveSquare => True
			_ => False
		})
		WaveSaw => (match ey {
			WaveSaw => True
			_ => False
		})
		WaveTriangle => (match ey {
			WaveTriangle => True
			_ => False
		})
	})

	eq_LpfState : Synth.LpfState, Synth.LpfState -> Bool
	eq_LpfState = |ex, ey| ((ex.lpf_prev == ey.lpf_prev) and (ex.lpf_alpha == ey.lpf_alpha))

	eq_Note : Synth.Note, Synth.Note -> Bool
	eq_Note = |ex, ey| ((((ex.note_freq == ey.note_freq) and (ex.note_start == ey.note_start)) and (ex.note_duration == ey.note_duration)) and eq_WaveType(ex.note_wave, ey.note_wave))
}
