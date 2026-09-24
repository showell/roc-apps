# Envelope -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Envelope :: [].{
	AdsrEnvelope := { env_attack : I64, env_decay : I64, env_sustain_level : I64, env_release : I64 }.{
		is_eq : Envelope.AdsrEnvelope, Envelope.AdsrEnvelope -> Bool
		is_eq = |a, b| a.env_attack == b.env_attack and a.env_decay == b.env_decay and a.env_sustain_level == b.env_sustain_level and a.env_release == b.env_release
	}

	adsr_new : I64, I64, I64, I64 -> Envelope.AdsrEnvelope
	adsr_new = |attack, decay, sustain, release| Envelope.AdsrEnvelope.{ env_attack: attack, env_decay: decay, env_sustain_level: sustain, env_release: release }

	adsr_default : Envelope.AdsrEnvelope
	adsr_default = Envelope.AdsrEnvelope.{ env_attack: 100, env_decay: 200, env_sustain_level: 700, env_release: 300 }

	adsr_eval : Envelope.AdsrEnvelope, I64, I64, Bool -> I64
	adsr_eval = |env, time, note_off_time, released| (if released { adsr_release_phase(env, time, note_off_time) } else { adsr_attack_decay_sustain(env, time) })

	adsr_attack_decay_sustain : Envelope.AdsrEnvelope, I64 -> I64
	adsr_attack_decay_sustain = |env, t| (if (t < env.env_attack) { (if (env.env_attack == 0) { 1000 } else { I64.div_trunc_by((t * 1000), env.env_attack) }) } else { ({
		decay_t = (t - env.env_attack)
		(if (decay_t < env.env_decay) { ({
			progress = (if (env.env_decay == 0) { 1000 } else { I64.div_trunc_by((decay_t * 1000), env.env_decay) })
			(1000 - I64.div_trunc_by(((1000 - env.env_sustain_level) * progress), 1000))
		}) } else { env.env_sustain_level })
	}) })

	adsr_release_phase : Envelope.AdsrEnvelope, I64, I64 -> I64
	adsr_release_phase = |env, time, note_off| ({
		release_t = (time - note_off)
		(if (release_t >= env.env_release) { 0 } else { ({
			level_at_release = env.env_sustain_level
			(if (env.env_release == 0) { 0 } else { (level_at_release - I64.div_trunc_by((level_at_release * release_t), env.env_release)) })
		}) })
	})

	adsr_sample : Envelope.AdsrEnvelope, I64, I64, I64 -> List(I64)
	adsr_sample = |env, duration, release_at, steps| adsr_sample_loop(env, duration, release_at, steps, 0, [])

	adsr_sample_loop : Envelope.AdsrEnvelope, I64, I64, I64, I64, List(I64) -> List(I64)
	adsr_sample_loop = |env, dur, rel_at, steps, i, acc| (if (i > steps) { acc } else { ({
		t = I64.div_trunc_by((i * dur), steps)
		released = (t >= rel_at)
		val = adsr_eval(env, t, rel_at, released)
		adsr_sample_loop(env, dur, rel_at, steps, (i + 1), List.append(acc, val))
	}) })

	adsr_total_time : Envelope.AdsrEnvelope -> I64
	adsr_total_time = |env| ((env.env_attack + env.env_decay) + env.env_release)
}
