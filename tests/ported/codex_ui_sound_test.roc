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

test_sound_effect : List(U8)
test_sound_effect = Sound.format_sound(Sound.snd_click)

test_sound_beep : List(U8)
test_sound_beep = Sound.format_sound(Sound.snd_beep)

test_waveform : List(U8)
test_waveform = ({
	s = Sound.sound_effect([24, 25, 19, 14, 16, 26], WavTriangle, 330, 100, 500)
	Sound.waveform_name(s.snd_wave)
})

test_queue : List(U8)
test_queue = ({
	sq = Sound.sound_queue_new(4)
	sq2 = Sound.sq_enqueue(Sound.sq_enqueue(sq, Sound.snd_click), Sound.snd_beep)
	empty = Sound.sq_is_empty(sq)
	notempty = Sound.sq_is_empty(sq2)
	List.concat(List.concat(List.concat(List.concat(List.concat([13, 26, 31, 14, 30, 77], snd_bool(empty)), [2, 24, 16, 25, 18, 14, 77]), Text.show_int(sq2.sq_count)), [2, 18, 16, 14, 13, 26, 31, 14, 30, 77]), snd_bool(notempty))
})

test_queue_drain : List(U8)
test_queue_drain = ({
	sq = Sound.sq_enqueue(Sound.sound_queue_new(4), Sound.snd_click)
	sq2 = Sound.sq_drain(sq)
	List.concat([22, 21, 15, 17, 18, 13, 22, 77], snd_bool(Sound.sq_is_empty(sq2)))
})

test_queue_overflow : List(U8)
test_queue_overflow = ({
	sq = Sound.sound_queue_new(2)
	sq2 = Sound.sq_enqueue(Sound.sq_enqueue(Sound.sq_enqueue(sq, Sound.snd_click), Sound.snd_beep), Sound.snd_error)
	List.concat([24, 16, 25, 18, 14, 77], Text.show_int(sq2.sq_count))
})

test_peek : List(U8)
test_peek = ({
	sq = Sound.sq_enqueue(Sound.sound_queue_new(4), Sound.snd_warning)
	top = Sound.sq_peek(sq)
	(match top {
		Just(s) => List.concat([31, 13, 13, 34, 77], s.snd_name)
		None => [13, 26, 31, 14, 30]
	})
})

test_sound_seq : List(U8)
test_sound_seq = ({
	steps = [Sound.sound_step(Sound.snd_click, 0), Sound.sound_step(Sound.snd_beep, 100)]
	seq = Sound.sound_seq(steps)
	sq = Sound.sound_queue_new(4)
	r1 = Sound.sound_seq_tick(seq, 0, sq)
	r2 = Sound.sound_seq_tick(r1.ssr_seq, 100, r1.ssr_queue)
	List.concat(List.concat(List.concat([37, 73, 24, 16, 25, 18, 14, 77], Text.show_int(r2.ssr_queue.sq_count)), [2, 22, 16, 18, 13, 77]), snd_bool(r2.ssr_seq.sseq_done))
})

snd_bool : Bool -> List(U8)
snd_bool = |b| (if b { [14, 21, 25, 13] } else { [28, 15, 23, 19, 13] })

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
