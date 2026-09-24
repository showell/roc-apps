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
import cdx.Text

# UiSoundTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_sound_effect : Text
test_sound_effect = Sound.format_sound(Sound.snd_click)

test_sound_beep : Text
test_sound_beep = Sound.format_sound(Sound.snd_beep)

test_waveform : Text
test_waveform = ({
	s = Sound.sound_effect("custom", WavTriangle, 330, 100, 500)
	Sound.waveform_name(s.snd_wave)
})

test_queue : Text
test_queue = ({
	sq = Sound.sound_queue_new(4)
	sq2 = Sound.sq_enqueue(Sound.sq_enqueue(sq, Sound.snd_click), Sound.snd_beep)
	empty = Sound.sq_is_empty(sq)
	notempty = Sound.sq_is_empty(sq2)
	Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("empty=", snd_bool(empty)), " count="), Text.show_int(sq2.sq_count)), " notempty="), snd_bool(notempty))
})

test_queue_drain : Text
test_queue_drain = ({
	sq = Sound.sq_enqueue(Sound.sound_queue_new(4), Sound.snd_click)
	sq2 = Sound.sq_drain(sq)
	Text.concat("drained=", snd_bool(Sound.sq_is_empty(sq2)))
})

test_queue_overflow : Text
test_queue_overflow = ({
	sq = Sound.sound_queue_new(2)
	sq2 = Sound.sq_enqueue(Sound.sq_enqueue(Sound.sq_enqueue(sq, Sound.snd_click), Sound.snd_beep), Sound.snd_error)
	Text.concat("count=", Text.show_int(sq2.sq_count))
})

test_peek : Text
test_peek = ({
	sq = Sound.sq_enqueue(Sound.sound_queue_new(4), Sound.snd_warning)
	top = Sound.sq_peek(sq)
	(match top {
		Just(s) => Text.concat("peek=", s.snd_name)
		None => "empty"
	})
})

test_sound_seq : Text
test_sound_seq = ({
	steps = [Sound.sound_step(Sound.snd_click, 0), Sound.sound_step(Sound.snd_beep, 100)]
	seq = Sound.sound_seq(steps)
	sq = Sound.sound_queue_new(4)
	r1 = Sound.sound_seq_tick(seq, 0, sq)
	r2 = Sound.sound_seq_tick(r1.ssr_seq, 100, r1.ssr_queue)
	Text.concat(Text.concat(Text.concat("q-count=", Text.show_int(r2.ssr_queue.sq_count)), " done="), snd_bool(r2.ssr_seq.sseq_done))
})

snd_bool : Bool -> Text
snd_bool = |b| (if b { "true" } else { "false" })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(test_sound_effect))
	line!(Text.printed(test_sound_beep))
	line!(Text.printed(test_waveform))
	line!(Text.printed(test_queue))
	line!(Text.printed(test_queue_drain))
	line!(Text.printed(test_queue_overflow))
	line!(Text.printed(test_peek))
	line!(Text.printed(test_sound_seq))
	Ok({})
}
