# AudioAnalysis -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import MathLib
import Tuple
import Units

AudioAnalysis :: [].{
	AudioFeatures := { af_peak : I64, af_rms : I64, af_centroid : Units.Frequency, af_bpm : I64, af_duration_ms : I64 }.{
		is_eq : AudioAnalysis.AudioFeatures, AudioAnalysis.AudioFeatures -> Bool
		is_eq = |a, b| a.af_peak == b.af_peak and a.af_rms == b.af_rms and a.af_centroid == b.af_centroid and a.af_bpm == b.af_bpm and a.af_duration_ms == b.af_duration_ms
	}

	audio_peak : List(I64) -> I64
	audio_peak = |samples| aa_peak_loop(samples, 0, U64.to_i64_wrap(List.len(samples)), 0)

	aa_peak_loop : List(I64), I64, I64, I64 -> I64
	aa_peak_loop = |samples, i, n, best| (if (i >= n) { best } else { ({
		v = (List.get(samples, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		abs_v = (if (v < 0) { (-v) } else { v })
		aa_peak_loop(samples, (i + 1), n, (if (abs_v > best) { abs_v } else { best }))
	}) })

	audio_rms : List(I64) -> I64
	audio_rms = |samples| ({
		n = U64.to_i64_wrap(List.len(samples))
		(if (n == 0) { 0 } else { ({
			sum_sq = aa_sum_sq(samples, 0, n, 0)
			MathLib.math_isqrt(I64.div_trunc_by(sum_sq, n))
		}) })
	})

	aa_sum_sq : List(I64), I64, I64, I64 -> I64
	aa_sum_sq = |samples, i, n, acc| (if (i >= n) { acc } else { ({
		v = (List.get(samples, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		aa_sum_sq(samples, (i + 1), n, (acc + I64.div_trunc_by((v * v), 1000)))
	}) })

	audio_envelope : List(I64), I64 -> List(I64)
	audio_envelope = |samples, window_size| aa_env_loop(samples, window_size, 0, U64.to_i64_wrap(List.len(samples)), [])

	aa_env_loop : List(I64), I64, I64, I64, List(I64) -> List(I64)
	aa_env_loop = |samples, ws, i, n, acc| (if ((i + ws) > n) { acc } else { ({
		rms = aa_window_rms(samples, i, ws)
		aa_env_loop(samples, ws, (i + ws), n, List.append(acc, rms))
	}) })

	aa_window_rms : List(I64), I64, I64 -> I64
	aa_window_rms = |samples, start, ws| MathLib.math_isqrt(I64.div_trunc_by(aa_window_sum_sq(samples, start, ws, 0), ws))

	aa_window_sum_sq : List(I64), I64, I64, I64 -> I64
	aa_window_sum_sq = |samples, start, ws, acc| (if (ws <= 0) { acc } else { ({
		v = (List.get(samples, I64.to_u64_wrap(start)) ?? crash("list-at out of range"))
		aa_window_sum_sq(samples, (start + 1), (ws - 1), (acc + I64.div_trunc_by((v * v), 1000)))
	}) })

	audio_onsets : List(I64) -> List(I64)
	audio_onsets = |envelope| aa_onset_loop(envelope, 1, U64.to_i64_wrap(List.len(envelope)), [])

	aa_onset_loop : List(I64), I64, I64, List(I64) -> List(I64)
	aa_onset_loop = |env, i, n, acc| (if (i >= n) { acc } else { ({
		diff = ((List.get(env, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) - (List.get(env, I64.to_u64_wrap((i - 1))) ?? crash("list-at out of range")))
		onset = (if (diff > 0) { diff } else { 0 })
		aa_onset_loop(env, (i + 1), n, List.append(acc, onset))
	}) })

	audio_estimate_bpm : List(I64), Units.Frequency, I64 -> I64
	audio_estimate_bpm = |envelope, sample_rate, window_size| ({
		onsets = audio_onsets(envelope)
		env_rate = I64.div_trunc_by(sample_rate, window_size)
		min_lag = I64.div_trunc_by((env_rate * 60), 200)
		max_lag = aa_min_val(I64.div_trunc_by((env_rate * 60), 50), I64.div_trunc_by(U64.to_i64_wrap(List.len(onsets)), 2))
		best_lag = aa_autocorr(onsets, min_lag, max_lag, 0, min_lag)
		(if (best_lag <= 0) { 120 } else { ({
			bpm = I64.div_trunc_by((60 * env_rate), best_lag)
			(if (bpm < 50) { 50 } else { (if (bpm > 200) { 200 } else { bpm }) })
		}) })
	})

	aa_autocorr : List(I64), I64, I64, I64, I64 -> I64
	aa_autocorr = |onsets, lag, max_lag, best_corr, best_lag| (if (lag > max_lag) { best_lag } else { ({
		corr = aa_corr_at(onsets, lag, 0, (U64.to_i64_wrap(List.len(onsets)) - lag), 0)
		(if (corr > best_corr) { aa_autocorr(onsets, (lag + 1), max_lag, corr, lag) } else { aa_autocorr(onsets, (lag + 1), max_lag, best_corr, best_lag) })
	}) })

	aa_corr_at : List(I64), I64, I64, I64, I64 -> I64
	aa_corr_at = |onsets, lag, i, n, acc| (if (i >= n) { acc } else { aa_corr_at(onsets, lag, (i + 1), n, (acc + I64.div_trunc_by(((List.get(onsets, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * (List.get(onsets, I64.to_u64_wrap((i + lag))) ?? crash("list-at out of range"))), 1000))) })

	audio_spectral_centroid : List(I64), Units.Frequency -> Units.Frequency
	audio_spectral_centroid = |samples, sample_rate| ({
		n = aa_min_val(256, U64.to_i64_wrap(List.len(samples)))
		weighted = aa_centroid_loop(samples, sample_rate, n, 1, 0, 0)
		(if (aa_centroid_mag(weighted) == 0) { 1000 } else { I64.div_trunc_by(aa_centroid_freq(weighted), aa_centroid_mag(weighted)) })
	})

	aa_centroid_freq : Tuple.Tup2(I64, I64) -> I64
	aa_centroid_freq = |c| (match c {
		MkTup2(w, _) => w
	})

	aa_centroid_mag : Tuple.Tup2(I64, I64) -> I64
	aa_centroid_mag = |c| (match c {
		MkTup2(_, m) => m
	})

	aa_centroid_loop : List(I64), I64, I64, I64, I64, I64 -> Tuple.Tup2(I64, I64)
	aa_centroid_loop = |samples, sr, n, bin, w_sum, m_sum| (if (bin >= I64.div_trunc_by(n, 2)) { MkTup2(w_sum, m_sum) } else { ({
		mag = aa_dft_mag(samples, n, bin)
		hz = I64.div_trunc_by((bin * sr), n)
		aa_centroid_loop(samples, sr, n, (bin + 1), (w_sum + I64.div_trunc_by((hz * mag), 1000)), (m_sum + mag))
	}) })

	aa_dft_mag : List(I64), I64, I64 -> I64
	aa_dft_mag = |samples, n, bin| ({
		result = aa_dft_loop(samples, n, bin, 0, 0, 0)
		(match result {
			MkTup2(r, i) => MathLib.math_isqrt((I64.div_trunc_by((r * r), 1000) + I64.div_trunc_by((i * i), 1000)))
		})
	})

	aa_dft_loop : List(I64), I64, I64, I64, I64, I64 -> Tuple.Tup2(I64, I64)
	aa_dft_loop = |samples, n, bin, i, re, im| (if (i >= n) { MkTup2(re, im) } else { ({
		angle = I64.div_trunc_by(((i * bin) * 6283), n)
		cos_val = aa_cos(angle)
		sin_val = aa_sin(angle)
		v = (List.get(samples, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		aa_dft_loop(samples, n, bin, (i + 1), (re + I64.div_trunc_by((v * cos_val), 1000)), (im - I64.div_trunc_by((v * sin_val), 1000)))
	}) })

	audio_analyze : List(I64), Units.Frequency -> AudioAnalysis.AudioFeatures
	audio_analyze = |samples, sample_rate| ({
		peak = audio_peak(samples)
		rms = audio_rms(samples)
		centroid = audio_spectral_centroid(samples, sample_rate)
		env = audio_envelope(samples, 2048)
		bpm = audio_estimate_bpm(env, sample_rate, 2048)
		dur = I64.div_trunc_by((U64.to_i64_wrap(List.len(samples)) * 1000), sample_rate)
		AudioAnalysis.AudioFeatures.{ af_peak: peak, af_rms: rms, af_centroid: centroid, af_bpm: bpm, af_duration_ms: dur }
	})

	audio_vibe : AudioAnalysis.AudioFeatures -> CceText
	audio_vibe = |f| ({
		energy = (if (f.af_rms > 700) { "high-energy" } else { (if (f.af_rms > 300) { "moderate" } else { "soft" }) })
		tempo = (if (f.af_bpm > 140) { "fast" } else { (if (f.af_bpm > 100) { "mid-tempo" } else { "relaxed" }) })
		CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(energy, ", "), tempo), " ("), CceText.show_int(f.af_bpm)), " BPM)")
	})

	aa_sin : I64 -> I64
	aa_sin = |x| ({
		x3 = I64.div_trunc_by((I64.div_trunc_by((x * x), 1000) * x), 1000)
		(x - I64.div_trunc_by(x3, 6))
	})

	aa_cos : I64 -> I64
	aa_cos = |x| ({
		x2 = I64.div_trunc_by((x * x), 1000)
		x4 = I64.div_trunc_by((x2 * x2), 1000)
		((1000 - I64.div_trunc_by(x2, 2)) + I64.div_trunc_by(x4, 24))
	})

	aa_min_val : I64, I64 -> I64
	aa_min_val = |a, b| (if (a < b) { a } else { b })

	format_audio_features : AudioAnalysis.AudioFeatures -> CceText
	format_audio_features = |f| CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("peak=", CceText.show_int(f.af_peak)), " rms="), CceText.show_int(f.af_rms)), " centroid="), CceText.show_int(f.af_centroid)), "Hz bpm="), CceText.show_int(f.af_bpm)), " dur="), CceText.show_int(f.af_duration_ms)), "ms")
}
