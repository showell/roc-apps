# ui-sound-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ui-sound-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     click square 800hz 50ms vol=500
#     beep sine 440hz 200ms vol=700
#     triangle
#     empty=true count=2 notempty=false
#     drained=true
#     count=2
#     peek=warning
#     q-count=2 done=false

app [main!] { cdx: "./codex/main.roc" }

import cdx.Sound

# UiSoundTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_sound_effect : Str
test_sound_effect = Sound.format_sound(Sound.snd_click)

test_sound_beep : Str
test_sound_beep = Sound.format_sound(Sound.snd_beep)

test_waveform : Str
test_waveform = ({
	s = Sound.sound_effect("custom", WavTriangle, 330, 100, 500)
	Sound.waveform_name(s.snd_wave)
})

test_queue : Str
test_queue = ({
	sq = Sound.sound_queue_new(4)
	sq2 = Sound.sq_enqueue(Sound.sq_enqueue(sq, Sound.snd_click), Sound.snd_beep)
	empty = Sound.sq_is_empty(sq)
	notempty = Sound.sq_is_empty(sq2)
	Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("empty=", snd_bool(empty)), " count="), I64.to_str(sq2.sq_count)), " notempty="), snd_bool(notempty))
})

test_queue_drain : Str
test_queue_drain = ({
	sq = Sound.sq_enqueue(Sound.sound_queue_new(4), Sound.snd_click)
	sq2 = Sound.sq_drain(sq)
	Str.concat("drained=", snd_bool(Sound.sq_is_empty(sq2)))
})

test_queue_overflow : Str
test_queue_overflow = ({
	sq = Sound.sound_queue_new(2)
	sq2 = Sound.sq_enqueue(Sound.sq_enqueue(Sound.sq_enqueue(sq, Sound.snd_click), Sound.snd_beep), Sound.snd_error)
	Str.concat("count=", I64.to_str(sq2.sq_count))
})

test_peek : Str
test_peek = ({
	sq = Sound.sq_enqueue(Sound.sound_queue_new(4), Sound.snd_warning)
	top = Sound.sq_peek(sq)
	(match top {
		Just(s) => Str.concat("peek=", s.snd_name)
		None => "empty"
	})
})

test_sound_seq : Str
test_sound_seq = ({
	steps = [Sound.sound_step(Sound.snd_click, 0), Sound.sound_step(Sound.snd_beep, 100)]
	seq = Sound.sound_seq(steps)
	sq = Sound.sound_queue_new(4)
	r1 = Sound.sound_seq_tick(seq, 0, sq)
	r2 = Sound.sound_seq_tick(r1.ssr_seq, 100, r1.ssr_queue)
	Str.concat(Str.concat(Str.concat("q-count=", I64.to_str(r2.ssr_queue.sq_count)), " done="), snd_bool(r2.ssr_seq.sseq_done))
})

snd_bool : Bool -> Str
snd_bool = |b| (if b { "true" } else { "false" })

# --- Entry ---

main! = |_args| {
	line!(test_sound_effect)
	line!(test_sound_beep)
	line!(test_waveform)
	line!(test_queue)
	line!(test_queue_drain)
	line!(test_queue_overflow)
	line!(test_peek)
	line!(test_sound_seq)
	Ok({})
}
