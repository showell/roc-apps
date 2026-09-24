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

test_setup_packet : Text
test_setup_packet = ({
	pkt = Usb.usb_setup_get_descriptor(Usb.usb_desc_device, 0, 18)
	bytes = Usb.usb_encode_setup(pkt)
	Text.concat(Text.concat(Text.concat("setup: len=", Text.show_int(U64.to_i64_wrap(List.len(bytes)))), " req="), Text.show_int(pkt.sp_request))
})

test_endpoint : Text
test_endpoint = ({
	bytes = [7, 5, 129, 1, 192, 0, 1]
	ep = Usb.usb_parse_endpoint(bytes, 0)
	Text.concat("ep: ", Usb.format_usb_endpoint(ep))
})

test_audio_format : Text
test_audio_format = ({
	cd = UsbAudio.audio_format_cd
	Text.concat("cd: ", UsbAudio.format_audio_format(cd))
})

test_audio_frame : Text
test_audio_frame = ({
	left = [500, (0 - 500)]
	right = [300, (0 - 300)]
	frame = UsbAudio.usb_audio_frame(left, right, UsbAudio.audio_format_cd)
	Text.concat("frame: bytes=", Text.show_int(U64.to_i64_wrap(List.len(frame))))
})

test_latency : Text
test_latency = ({
	fmt = UsbAudio.audio_format_48k
	Text.concat(Text.concat(Text.concat("latency-256=", Text.show_int(UsbAudio.usb_audio_latency_ms(fmt, 256))), "ms bps="), Text.show_int(UsbAudio.usb_audio_bytes_per_second(fmt)))
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
