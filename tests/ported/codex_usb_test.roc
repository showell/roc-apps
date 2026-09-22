# usb-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/usb-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     setup: len=8 req=6
#     ep: EP1 IN ISO maxpkt=192
#     cd: 44100Hz 2ch 16bit (176400 B/s)
#     frame: bytes=8
#     latency-256=5ms bps=192000

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text
import cdx.Usb
import cdx.UsbAudio

# UsbTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_setup_packet : List(U8)
test_setup_packet = ({
	pkt = Usb.usb_setup_get_descriptor(Usb.usb_desc_device, 0, 18)
	bytes = Usb.usb_encode_setup(pkt)
	List.concat(List.concat(List.concat([19, 13, 14, 25, 31, 69, 2, 23, 13, 18, 77], Text.show_int(U64.to_i64_wrap(List.len(bytes)))), [2, 21, 13, 37, 77]), Text.show_int(pkt.sp_request))
})

test_endpoint : List(U8)
test_endpoint = ({
	bytes = [7, 5, 129, 1, 192, 0, 1]
	ep = Usb.usb_parse_endpoint(bytes, 0)
	List.concat([13, 31, 69, 2], Usb.format_usb_endpoint(ep))
})

test_audio_format : List(U8)
test_audio_format = ({
	cd = UsbAudio.audio_format_cd
	List.concat([24, 22, 69, 2], UsbAudio.format_audio_format(cd))
})

test_audio_frame : List(U8)
test_audio_frame = ({
	left = [500, (0 - 500)]
	right = [300, (0 - 300)]
	frame = UsbAudio.usb_audio_frame(left, right, UsbAudio.audio_format_cd)
	List.concat([28, 21, 15, 26, 13, 69, 2, 32, 30, 14, 13, 19, 77], Text.show_int(U64.to_i64_wrap(List.len(frame))))
})

test_latency : List(U8)
test_latency = ({
	fmt = UsbAudio.audio_format_48k
	List.concat(List.concat(List.concat([23, 15, 14, 13, 18, 24, 30, 73, 5, 8, 9, 77], Text.show_int(UsbAudio.usb_audio_latency_ms(fmt, 256))), [26, 19, 2, 32, 31, 19, 77]), Text.show_int(UsbAudio.usb_audio_bytes_per_second(fmt)))
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(test_setup_packet))
	line!(Text.printed(test_endpoint))
	line!(Text.printed(test_audio_format))
	line!(Text.printed(test_audio_frame))
	line!(Text.printed(test_latency))
	Ok({})
}
