# Sound -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import Maybe

Sound :: [].{
	Waveform : [WavSine, WavSquare, WavTriangle, WavNoise, WavSilence]
	SoundEffect := { snd_name : CceText, snd_wave : Sound.Waveform, snd_freq : I64, snd_duration : I64, snd_volume : I64, snd_priority : I64 }.{
		is_eq : Sound.SoundEffect, Sound.SoundEffect -> Bool
		is_eq = |a, b| eq_SoundEffect(a, b)
	}
	SoundQueue := { sq_pending : List(Sound.SoundEffect), sq_count : I64, sq_max : I64 }.{
		is_eq : Sound.SoundQueue, Sound.SoundQueue -> Bool
		is_eq = |a, b| eq_SoundQueue(a, b)
	}
	SoundStep := { ss_effect : Sound.SoundEffect, ss_delay : I64 }.{
		is_eq : Sound.SoundStep, Sound.SoundStep -> Bool
		is_eq = |a, b| eq_SoundStep(a, b)
	}
	SoundSeq := { sseq_steps : List(Sound.SoundStep), sseq_count : I64, sseq_current : I64, sseq_elapsed : I64, sseq_done : Bool }.{
		is_eq : Sound.SoundSeq, Sound.SoundSeq -> Bool
		is_eq = |a, b| eq_SoundSeq(a, b)
	}
	SoundSeqResult := { ssr_seq : Sound.SoundSeq, ssr_queue : Sound.SoundQueue }.{
		is_eq : Sound.SoundSeqResult, Sound.SoundSeqResult -> Bool
		is_eq = |a, b| eq_SoundSeqResult(a, b)
	}

	sound_effect : CceText, Sound.Waveform, I64, I64, I64 -> Sound.SoundEffect
	sound_effect = |name, wave, freq, dur, vol| Sound.SoundEffect.{ snd_name: name, snd_wave: wave, snd_freq: freq, snd_duration: dur, snd_volume: vol, snd_priority: 0 }

	sound_effect_pri : CceText, Sound.Waveform, I64, I64, I64, I64 -> Sound.SoundEffect
	sound_effect_pri = |name, wave, freq, dur, vol, pri| Sound.SoundEffect.{ snd_name: name, snd_wave: wave, snd_freq: freq, snd_duration: dur, snd_volume: vol, snd_priority: pri }

	sound_queue_new : I64 -> Sound.SoundQueue
	sound_queue_new = |max_size| Sound.SoundQueue.{ sq_pending: [], sq_count: 0, sq_max: max_size }

	sq_enqueue : Sound.SoundQueue, Sound.SoundEffect -> Sound.SoundQueue
	sq_enqueue = |sq, snd| (if (sq.sq_count >= sq.sq_max) { sq } else { Sound.SoundQueue.{ sq_pending: List.append(sq.sq_pending, snd), sq_count: (sq.sq_count + 1), sq_max: sq.sq_max } })

	sq_drain : Sound.SoundQueue -> Sound.SoundQueue
	sq_drain = |sq| Sound.SoundQueue.{ sq_pending: [], sq_count: 0, sq_max: sq.sq_max }

	sq_peek : Sound.SoundQueue -> Maybe.Maybe(Sound.SoundEffect)
	sq_peek = |sq| (if (sq.sq_count <= 0) { None } else { Just((List.get(sq.sq_pending, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))) })

	sq_is_empty : Sound.SoundQueue -> Bool
	sq_is_empty = |sq| (sq.sq_count == 0)

	snd_click : Sound.SoundEffect
	snd_click = sound_effect("click", WavSquare, 800, 50, 500)

	snd_beep : Sound.SoundEffect
	snd_beep = sound_effect("beep", WavSine, 440, 200, 700)

	snd_error : Sound.SoundEffect
	snd_error = sound_effect("error", WavSquare, 220, 300, 800)

	snd_success : Sound.SoundEffect
	snd_success = sound_effect("success", WavSine, 880, 150, 600)

	snd_warning : Sound.SoundEffect
	snd_warning = sound_effect("warning", WavTriangle, 660, 250, 700)

	snd_notify : Sound.SoundEffect
	snd_notify = sound_effect("notify", WavSine, 1200, 100, 400)

	snd_tick : Sound.SoundEffect
	snd_tick = sound_effect("tick", WavSquare, 1000, 30, 300)

	snd_whoosh : Sound.SoundEffect
	snd_whoosh = sound_effect("whoosh", WavNoise, 0, 200, 500)

	sound_step : Sound.SoundEffect, I64 -> Sound.SoundStep
	sound_step = |fx, delay| Sound.SoundStep.{ ss_effect: fx, ss_delay: delay }

	sound_seq : List(Sound.SoundStep) -> Sound.SoundSeq
	sound_seq = |steps| Sound.SoundSeq.{ sseq_steps: steps, sseq_count: U64.to_i64_wrap(List.len(steps)), sseq_current: 0, sseq_elapsed: 0, sseq_done: False }

	sound_seq_tick : Sound.SoundSeq, I64, Sound.SoundQueue -> Sound.SoundSeqResult
	sound_seq_tick = |seq, dt, sq| (if seq.sseq_done { Sound.SoundSeqResult.{ ssr_seq: seq, ssr_queue: sq } } else { (if (seq.sseq_current >= seq.sseq_count) { Sound.SoundSeqResult.{ ssr_seq: Sound.SoundSeq.{ sseq_steps: seq.sseq_steps, sseq_count: seq.sseq_count, sseq_current: seq.sseq_current, sseq_elapsed: seq.sseq_elapsed, sseq_done: True }, ssr_queue: sq } } else { ({
		step = (List.get(seq.sseq_steps, I64.to_u64_wrap(seq.sseq_current)) ?? crash("list-at out of range"))
		new_elapsed : I64
		new_elapsed = (seq.sseq_elapsed + dt)
		(if (new_elapsed >= step.ss_delay) { ({
			sq2 = sq_enqueue(sq, step.ss_effect)
			next = Sound.SoundSeq.{ sseq_steps: seq.sseq_steps, sseq_count: seq.sseq_count, sseq_current: (seq.sseq_current + 1), sseq_elapsed: 0, sseq_done: False }
			Sound.SoundSeqResult.{ ssr_seq: next, ssr_queue: sq2 }
		}) } else { Sound.SoundSeqResult.{ ssr_seq: Sound.SoundSeq.{ sseq_steps: seq.sseq_steps, sseq_count: seq.sseq_count, sseq_current: seq.sseq_current, sseq_elapsed: new_elapsed, sseq_done: False }, ssr_queue: sq } })
	}) }) })

	waveform_name : Sound.Waveform -> CceText
	waveform_name = |w| (match w {
		WavSine => "sine"
		WavSquare => "square"
		WavTriangle => "triangle"
		WavNoise => "noise"
		WavSilence => "silence"
	})

	format_sound : Sound.SoundEffect -> CceText
	format_sound = |s| CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(s.snd_name, " "), waveform_name(s.snd_wave)), " "), CceText.show_int(s.snd_freq)), "hz "), CceText.show_int(s.snd_duration)), "ms vol="), CceText.show_int(s.snd_volume))

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

	eq_SoundEffect : Sound.SoundEffect, Sound.SoundEffect -> Bool
	eq_SoundEffect = |ex, ey| ((((((ex.snd_name == ey.snd_name) and eq_Waveform(ex.snd_wave, ey.snd_wave)) and (ex.snd_freq == ey.snd_freq)) and (ex.snd_duration == ey.snd_duration)) and (ex.snd_volume == ey.snd_volume)) and (ex.snd_priority == ey.snd_priority))

	eq_SoundQueue : Sound.SoundQueue, Sound.SoundQueue -> Bool
	eq_SoundQueue = |ex, ey| (((ex.sq_pending == ey.sq_pending) and (ex.sq_count == ey.sq_count)) and (ex.sq_max == ey.sq_max))

	eq_SoundStep : Sound.SoundStep, Sound.SoundStep -> Bool
	eq_SoundStep = |ex, ey| (eq_SoundEffect(ex.ss_effect, ey.ss_effect) and (ex.ss_delay == ey.ss_delay))

	eq_SoundSeq : Sound.SoundSeq, Sound.SoundSeq -> Bool
	eq_SoundSeq = |ex, ey| (((((ex.sseq_steps == ey.sseq_steps) and (ex.sseq_count == ey.sseq_count)) and (ex.sseq_current == ey.sseq_current)) and (ex.sseq_elapsed == ey.sseq_elapsed)) and (ex.sseq_done == ey.sseq_done))

	eq_SoundSeqResult : Sound.SoundSeqResult, Sound.SoundSeqResult -> Bool
	eq_SoundSeqResult = |ex, ey| (eq_SoundSeq(ex.ssr_seq, ey.ssr_seq) and eq_SoundQueue(ex.ssr_queue, ey.ssr_queue))
}
