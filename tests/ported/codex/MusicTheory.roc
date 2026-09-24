# MusicTheory -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText

MusicTheory :: [].{

	note_freq : I64 -> I64
	note_freq = |midi_note| ({
		semitones = (midi_note - 69)
		I64.div_trunc_by((440 * mt_pow2_12ths(semitones)), 1000)
	})

	mt_pow2_12ths : I64 -> I64
	mt_pow2_12ths = |semitones| (if (semitones == 0) { 1000 } else { (if (semitones > 0) { mt_pos_semitones(semitones) } else { I64.div_trunc_by(1000000, mt_pos_semitones((-semitones))) }) })

	mt_pos_semitones : I64 -> I64
	mt_pos_semitones = |n| (if (n >= 12) { (2 * mt_pos_semitones((n - 12))) } else { (List.get(mt_semitone_table, I64.to_u64_wrap(n)) ?? crash("list-at out of range")) })

	mt_semitone_table : List(I64)
	mt_semitone_table = [1000, 1059, 1122, 1189, 1260, 1335, 1414, 1498, 1587, 1682, 1782, 1888]

	mt_note_name : I64 -> CceText
	mt_note_name = |midi| ({
		pc = (midi - (I64.div_trunc_by(midi, 12) * 12))
		octave = (I64.div_trunc_by(midi, 12) - 1)
		CceText.concat(mt_pitch_class(pc), CceText.show_int(octave))
	})

	mt_pitch_class : I64 -> CceText
	mt_pitch_class = |pc| (if (pc == 0) { "C" } else { (if (pc == 1) { "C#" } else { (if (pc == 2) { "D" } else { (if (pc == 3) { "D#" } else { (if (pc == 4) { "E" } else { (if (pc == 5) { "F" } else { (if (pc == 6) { "F#" } else { (if (pc == 7) { "G" } else { (if (pc == 8) { "G#" } else { (if (pc == 9) { "A" } else { (if (pc == 10) { "A#" } else { "B" }) }) }) }) }) }) }) }) }) }) })

	scale_major : I64 -> List(I64)
	scale_major = |root| mt_build_scale(root, [0, 2, 4, 5, 7, 9, 11])

	scale_minor : I64 -> List(I64)
	scale_minor = |root| mt_build_scale(root, [0, 2, 3, 5, 7, 8, 10])

	scale_pentatonic : I64 -> List(I64)
	scale_pentatonic = |root| mt_build_scale(root, [0, 2, 4, 7, 9])

	scale_blues : I64 -> List(I64)
	scale_blues = |root| mt_build_scale(root, [0, 3, 5, 6, 7, 10])

	scale_chromatic : I64 -> List(I64)
	scale_chromatic = |root| mt_build_scale(root, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])

	scale_dorian : I64 -> List(I64)
	scale_dorian = |root| mt_build_scale(root, [0, 2, 3, 5, 7, 9, 10])

	scale_mixolydian : I64 -> List(I64)
	scale_mixolydian = |root| mt_build_scale(root, [0, 2, 4, 5, 7, 9, 10])

	mt_build_scale : I64, List(I64) -> List(I64)
	mt_build_scale = |root, intervals| mt_scale_loop(root, intervals, 0, U64.to_i64_wrap(List.len(intervals)), [])

	mt_scale_loop : I64, List(I64), I64, I64, List(I64) -> List(I64)
	mt_scale_loop = |root, intervals, i, n, acc| (if (i >= n) { acc } else { mt_scale_loop(root, intervals, (i + 1), n, List.append(acc, (root + (List.get(intervals, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	chord_major : I64 -> List(I64)
	chord_major = |root| [root, (root + 4), (root + 7)]

	chord_minor : I64 -> List(I64)
	chord_minor = |root| [root, (root + 3), (root + 7)]

	chord_dim : I64 -> List(I64)
	chord_dim = |root| [root, (root + 3), (root + 6)]

	chord_aug : I64 -> List(I64)
	chord_aug = |root| [root, (root + 4), (root + 8)]

	chord_dom7 : I64 -> List(I64)
	chord_dom7 = |root| [root, (root + 4), (root + 7), (root + 10)]

	chord_maj7 : I64 -> List(I64)
	chord_maj7 = |root| [root, (root + 4), (root + 7), (root + 11)]

	chord_min7 : I64 -> List(I64)
	chord_min7 = |root| [root, (root + 3), (root + 7), (root + 10)]

	chord_sus2 : I64 -> List(I64)
	chord_sus2 = |root| [root, (root + 2), (root + 7)]

	chord_sus4 : I64 -> List(I64)
	chord_sus4 = |root| [root, (root + 5), (root + 7)]

	mt_interval_name : I64 -> CceText
	mt_interval_name = |semitones| (if (semitones == 0) { "unison" } else { (if (semitones == 1) { "m2" } else { (if (semitones == 2) { "M2" } else { (if (semitones == 3) { "m3" } else { (if (semitones == 4) { "M3" } else { (if (semitones == 5) { "P4" } else { (if (semitones == 6) { "tritone" } else { (if (semitones == 7) { "P5" } else { (if (semitones == 8) { "m6" } else { (if (semitones == 9) { "M6" } else { (if (semitones == 10) { "m7" } else { (if (semitones == 11) { "M7" } else { (if (semitones == 12) { "octave" } else { CceText.concat(CceText.show_int(semitones), "st") }) }) }) }) }) }) }) }) }) }) }) }) })

	mt_bpm_to_ms : I64 -> I64
	mt_bpm_to_ms = |bpm| I64.div_trunc_by(60000, bpm)

	mt_note_duration : I64, I64 -> I64
	mt_note_duration = |bpm, note_value| I64.div_trunc_by((mt_bpm_to_ms(bpm) * 4), note_value)

	mt_samples_for_ms : I64, I64 -> I64
	mt_samples_for_ms = |ms, sample_rate| I64.div_trunc_by((ms * sample_rate), 1000)

	format_chord : List(I64) -> CceText
	format_chord = |notes| mt_format_notes(notes, 0, U64.to_i64_wrap(List.len(notes)), "")

	mt_format_notes : List(I64), I64, I64, CceText -> CceText
	mt_format_notes = |notes, i, n, acc| (if (i >= n) { acc } else { ({
		sep = (if (i == 0) { "" } else { "-" })
		mt_format_notes(notes, (i + 1), n, CceText.concat(CceText.concat(acc, sep), mt_note_name((List.get(notes, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))
	}) })
}
