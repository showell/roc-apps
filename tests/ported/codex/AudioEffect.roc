# AudioEffect -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CircularBuffer

AudioEffect :: [].{

	fx_delay : List(I64), I64, I64, I64 -> List(I64)
	fx_delay = |samples, delay_samples, feedback, mix| fx_delay_loop(samples, delay_samples, feedback, mix, 0, U64.to_i64_wrap(List.len(samples)), CircularBuffer.circbuf_new(delay_samples), [])

	fx_delay_loop : List(I64), I64, I64, I64, I64, I64, CircularBuffer.CircBuf, List(I64) -> List(I64)
	fx_delay_loop = |samples, delay, feedback, mix, i, n, buf, acc| (if (i >= n) { acc } else { ({
		dry : I64
		dry = (List.get(samples, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		wet : I64
		wet = fx_circbuf_read(buf)
		mixed : I64
		mixed = (I64.div_trunc_by((dry * (1000 - mix)), 1000) + I64.div_trunc_by((wet * mix), 1000))
		to_buf : I64
		to_buf = (dry + I64.div_trunc_by((wet * feedback), 1000))
		new_buf = CircularBuffer.circbuf_push_back(buf, to_buf)
		fx_delay_loop(samples, delay, feedback, mix, (i + 1), n, new_buf, List.append(acc, mixed))
	}) })

	fx_circbuf_read : CircularBuffer.CircBuf -> I64
	fx_circbuf_read = |buf| ({
		front = CircularBuffer.circbuf_front(buf)
		(match front {
			Just(v) => v
			None => 0
		})
	})

	fx_reverb : List(I64), I64, I64 -> List(I64)
	fx_reverb = |samples, room_size, _damping| ({
		d1 : List(I64)
		d1 = fx_delay(samples, room_size, 400, 300)
		d2 : List(I64)
		d2 = fx_delay(samples, I64.div_trunc_by((room_size * 3), 4), 350, 250)
		d3 : List(I64)
		d3 = fx_delay(samples, I64.div_trunc_by(room_size, 2), 300, 200)
		fx_mix3(d1, d2, d3)
	})

	fx_mix3 : List(I64), List(I64), List(I64) -> List(I64)
	fx_mix3 = |a, b, c| fx_mix3_loop(a, b, c, 0, fx_min3(U64.to_i64_wrap(List.len(a)), U64.to_i64_wrap(List.len(b)), U64.to_i64_wrap(List.len(c))), [])

	fx_mix3_loop : List(I64), List(I64), List(I64), I64, I64, List(I64) -> List(I64)
	fx_mix3_loop = |a, b, c, i, n, acc| (if (i >= n) { acc } else { ({
		val : I64
		val = I64.div_trunc_by((((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) + (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) + (List.get(c, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), 3)
		fx_mix3_loop(a, b, c, (i + 1), n, List.append(acc, val))
	}) })

	fx_min3 : I64, I64, I64 -> I64
	fx_min3 = |a, b, c| ({
		ab : I64
		ab = (if (a < b) { a } else { b })
		(if (ab < c) { ab } else { c })
	})

	fx_distortion : List(I64), I64 -> List(I64)
	fx_distortion = |samples, drive| fx_dist_loop(samples, drive, 0, U64.to_i64_wrap(List.len(samples)), [])

	fx_dist_loop : List(I64), I64, I64, I64, List(I64) -> List(I64)
	fx_dist_loop = |samples, drive, i, n, acc| (if (i >= n) { acc } else { ({
		val : I64
		val = I64.div_trunc_by(((List.get(samples, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * drive), 1000)
		clipped : I64
		clipped = fx_soft_clip(val)
		fx_dist_loop(samples, drive, (i + 1), n, List.append(acc, clipped))
	}) })

	fx_soft_clip : I64 -> I64
	fx_soft_clip = |x| (if (x > 1000) { 1000 } else { (if (x < (0 - 1000)) { (0 - 1000) } else { ({
		x3 : I64
		x3 = I64.div_trunc_by((I64.div_trunc_by((x * x), 1000) * x), 1000)
		(x - I64.div_trunc_by(x3, 3))
	}) }) })

	fx_compress : List(I64), I64, I64 -> List(I64)
	fx_compress = |samples, threshold, ratio| fx_comp_loop(samples, threshold, ratio, 0, U64.to_i64_wrap(List.len(samples)), [])

	fx_comp_loop : List(I64), I64, I64, I64, I64, List(I64) -> List(I64)
	fx_comp_loop = |samples, thresh, ratio, i, n, acc| (if (i >= n) { acc } else { ({
		val : I64
		val = (List.get(samples, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		abs_val : I64
		abs_val = (if (val < 0) { (-val) } else { val })
		compressed : I64
		compressed = (if (abs_val > thresh) { ({
			over : I64
			over = (abs_val - thresh)
			reduced : I64
			reduced = (thresh + I64.div_trunc_by((over * 1000), ratio))
			(if (val < 0) { (-reduced) } else { reduced })
		}) } else { val })
		fx_comp_loop(samples, thresh, ratio, (i + 1), n, List.append(acc, compressed))
	}) })

	fx_eq3 : List(I64), I64, I64, I64 -> List(I64)
	fx_eq3 = |samples, low_gain, mid_gain, high_gain| fx_eq3_loop(samples, low_gain, mid_gain, high_gain, 0, U64.to_i64_wrap(List.len(samples)), 0, 0, [])

	fx_eq3_loop : List(I64), I64, I64, I64, I64, I64, I64, I64, List(I64) -> List(I64)
	fx_eq3_loop = |samples, lg, mg, hg, i, n, lp_prev, hp_prev, acc| (if (i >= n) { acc } else { ({
		val : I64
		val = (List.get(samples, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		lp : I64
		lp = I64.div_trunc_by(((lp_prev * 900) + (val * 100)), 1000)
		hp : I64
		hp = (val - I64.div_trunc_by(((hp_prev * 900) + (val * 100)), 1000))
		mp : I64
		mp = ((val - lp) - hp)
		out : I64
		out = ((I64.div_trunc_by((lp * lg), 1000) + I64.div_trunc_by((mp * mg), 1000)) + I64.div_trunc_by((hp * hg), 1000))
		fx_eq3_loop(samples, lg, mg, hg, (i + 1), n, lp, hp, List.append(acc, out))
	}) })

	fx_chorus : List(I64), I64, I64, I64 -> List(I64)
	fx_chorus = |samples, depth, rate, mix| fx_chorus_loop(samples, depth, rate, mix, 0, U64.to_i64_wrap(List.len(samples)), CircularBuffer.circbuf_new((depth * 2)), [])

	fx_chorus_loop : List(I64), I64, I64, I64, I64, I64, CircularBuffer.CircBuf, List(I64) -> List(I64)
	fx_chorus_loop = |samples, depth, rate, mix, i, n, buf, acc| (if (i >= n) { acc } else { ({
		dry : I64
		dry = (List.get(samples, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		_lfo = (depth + I64.div_trunc_by((depth * fx_lfo(i, rate)), 1000))
		delayed : I64
		delayed = fx_circbuf_read(buf)
		mixed : I64
		mixed = (I64.div_trunc_by((dry * (1000 - mix)), 1000) + I64.div_trunc_by((delayed * mix), 1000))
		new_buf = CircularBuffer.circbuf_push_back(buf, dry)
		fx_chorus_loop(samples, depth, rate, mix, (i + 1), n, new_buf, List.append(acc, mixed))
	}) })

	fx_lfo : I64, I64 -> I64
	fx_lfo = |sample, rate| ({
		phase : I64
		phase = I64.div_trunc_by(((sample * rate) * 6283), 44100)
		wrapped : I64
		wrapped = (phase - (I64.div_trunc_by(phase, 6283) * 6283))
		x : I64
		x = (wrapped - 3142)
		(x - I64.div_trunc_by((I64.div_trunc_by((x * x), 1000) * x), 6000))
	})

	fx_normalize : List(I64), I64 -> List(I64)
	fx_normalize = |samples, target| ({
		peak : I64
		peak = fx_find_peak(samples, 0, U64.to_i64_wrap(List.len(samples)), 0)
		(if (peak == 0) { samples } else { ({
			gain : I64
			gain = I64.div_trunc_by((target * 1000), peak)
			fx_norm_loop(samples, gain, 0, U64.to_i64_wrap(List.len(samples)), [])
		}) })
	})

	fx_norm_loop : List(I64), I64, I64, I64, List(I64) -> List(I64)
	fx_norm_loop = |samples, gain, i, n, acc| (if (i >= n) { acc } else { fx_norm_loop(samples, gain, (i + 1), n, List.append(acc, I64.div_trunc_by(((List.get(samples, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * gain), 1000))) })

	fx_find_peak : List(I64), I64, I64, I64 -> I64
	fx_find_peak = |samples, i, n, best| (if (i >= n) { best } else { ({
		v : I64
		v = (List.get(samples, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		abs_v : I64
		abs_v = (if (v < 0) { (-v) } else { v })
		fx_find_peak(samples, (i + 1), n, (if (abs_v > best) { abs_v } else { best }))
	}) })
}
