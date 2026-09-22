# Sound -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Maybe
import Text

Sound :: [].{
	Waveform : [WavSine, WavSquare, WavTriangle, WavNoise, WavSilence]
	SoundEffect : { snd_name : List(U8), snd_wave : Sound.Waveform, snd_freq : I64, snd_duration : I64, snd_volume : I64, snd_priority : I64 }
	SoundQueue : { sq_pending : List(Sound.SoundEffect), sq_count : I64, sq_max : I64 }
	SoundStep : { ss_effect : Sound.SoundEffect, ss_delay : I64 }
	SoundSeq : { sseq_steps : List(Sound.SoundStep), sseq_count : I64, sseq_current : I64, sseq_elapsed : I64, sseq_done : Bool }
	SoundSeqResult : { ssr_seq : Sound.SoundSeq, ssr_queue : Sound.SoundQueue }

	sound_effect : List(U8), Sound.Waveform, I64, I64, I64 -> Sound.SoundEffect
	sound_effect = |name, wave, freq, dur, vol| { snd_name: name, snd_wave: wave, snd_freq: freq, snd_duration: dur, snd_volume: vol, snd_priority: 0 }

	sound_effect_pri : List(U8), Sound.Waveform, I64, I64, I64, I64 -> Sound.SoundEffect
	sound_effect_pri = |name, wave, freq, dur, vol, pri| { snd_name: name, snd_wave: wave, snd_freq: freq, snd_duration: dur, snd_volume: vol, snd_priority: pri }

	sound_queue_new : I64 -> Sound.SoundQueue
	sound_queue_new = |max_size| { sq_pending: [], sq_count: 0, sq_max: max_size }

	sq_enqueue : Sound.SoundQueue, Sound.SoundEffect -> Sound.SoundQueue
	sq_enqueue = |sq, snd| (if (sq.sq_count >= sq.sq_max) { sq } else { { sq_pending: List.append(sq.sq_pending, snd), sq_count: (sq.sq_count + 1), sq_max: sq.sq_max } })

	sq_drain : Sound.SoundQueue -> Sound.SoundQueue
	sq_drain = |sq| { sq_pending: [], sq_count: 0, sq_max: sq.sq_max }

	sq_peek : Sound.SoundQueue -> Maybe.Maybe(Sound.SoundEffect)
	sq_peek = |sq| (if (sq.sq_count <= 0) { None } else { Just((List.get(sq.sq_pending, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))) })

	sq_is_empty : Sound.SoundQueue -> Bool
	sq_is_empty = |sq| (sq.sq_count == 0)

	snd_click : Sound.SoundEffect
	snd_click = sound_effect([24, 23, 17, 24, 34], WavSquare, 800, 50, 500)

	snd_beep : Sound.SoundEffect
	snd_beep = sound_effect([32, 13, 13, 31], WavSine, 440, 200, 700)

	snd_error : Sound.SoundEffect
	snd_error = sound_effect([13, 21, 21, 16, 21], WavSquare, 220, 300, 800)

	snd_success : Sound.SoundEffect
	snd_success = sound_effect([19, 25, 24, 24, 13, 19, 19], WavSine, 880, 150, 600)

	snd_warning : Sound.SoundEffect
	snd_warning = sound_effect([27, 15, 21, 18, 17, 18, 29], WavTriangle, 660, 250, 700)

	snd_notify : Sound.SoundEffect
	snd_notify = sound_effect([18, 16, 14, 17, 28, 30], WavSine, 1200, 100, 400)

	snd_tick : Sound.SoundEffect
	snd_tick = sound_effect([14, 17, 24, 34], WavSquare, 1000, 30, 300)

	snd_whoosh : Sound.SoundEffect
	snd_whoosh = sound_effect([27, 20, 16, 16, 19, 20], WavNoise, 0, 200, 500)

	sound_step : Sound.SoundEffect, I64 -> Sound.SoundStep
	sound_step = |fx, delay| { ss_effect: fx, ss_delay: delay }

	sound_seq : List(Sound.SoundStep) -> Sound.SoundSeq
	sound_seq = |steps| { sseq_steps: steps, sseq_count: U64.to_i64_wrap(List.len(steps)), sseq_current: 0, sseq_elapsed: 0, sseq_done: False }

	sound_seq_tick : Sound.SoundSeq, I64, Sound.SoundQueue -> Sound.SoundSeqResult
	sound_seq_tick = |seq, dt, sq| (if seq.sseq_done { { ssr_seq: seq, ssr_queue: sq } } else { (if (seq.sseq_current >= seq.sseq_count) { { ssr_seq: { sseq_steps: seq.sseq_steps, sseq_count: seq.sseq_count, sseq_current: seq.sseq_current, sseq_elapsed: seq.sseq_elapsed, sseq_done: True }, ssr_queue: sq } } else { ({
		step = (List.get(seq.sseq_steps, I64.to_u64_wrap(seq.sseq_current)) ?? crash("list-at out of range"))
		new_elapsed = (seq.sseq_elapsed + dt)
		(if (new_elapsed >= step.ss_delay) { ({
			sq2 = sq_enqueue(sq, step.ss_effect)
			next = { sseq_steps: seq.sseq_steps, sseq_count: seq.sseq_count, sseq_current: (seq.sseq_current + 1), sseq_elapsed: 0, sseq_done: False }
			{ ssr_seq: next, ssr_queue: sq2 }
		}) } else { { ssr_seq: { sseq_steps: seq.sseq_steps, sseq_count: seq.sseq_count, sseq_current: seq.sseq_current, sseq_elapsed: new_elapsed, sseq_done: False }, ssr_queue: sq } })
	}) }) })

	waveform_name : Sound.Waveform -> List(U8)
	waveform_name = |w| (match w {
		WavSine => [19, 17, 18, 13]
		WavSquare => [19, 37, 25, 15, 21, 13]
		WavTriangle => [14, 21, 17, 15, 18, 29, 23, 13]
		WavNoise => [18, 16, 17, 19, 13]
		WavSilence => [19, 17, 23, 13, 18, 24, 13]
	})

	format_sound : Sound.SoundEffect -> List(U8)
	format_sound = |s| List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(s.snd_name, [2]), waveform_name(s.snd_wave)), [2]), Text.show_int(s.snd_freq)), [20, 38, 2]), Text.show_int(s.snd_duration)), [26, 19, 2, 33, 16, 23, 77]), Text.show_int(s.snd_volume))

	eq_Waveform : Sound.Waveform, Sound.Waveform -> Bool
	eq_Waveform = |ex, ey| (match ex {
		WavSine => (match ey {
			WavSine => True
			_ => False
		})
		WavSquare => (match ey {
			WavSquare => True
			_ => False
		})
		WavTriangle => (match ey {
			WavTriangle => True
			_ => False
		})
		WavNoise => (match ey {
			WavNoise => True
			_ => False
		})
		WavSilence => (match ey {
			WavSilence => True
			_ => False
		})
	})
}
