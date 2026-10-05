# Sound -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText

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

	sound_queue_new : I64 -> Sound.SoundQueue
	sound_queue_new = |max_size| Sound.SoundQueue.{ sq_pending: [], sq_count: 0, sq_max: max_size }

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
