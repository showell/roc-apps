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

import cdx.CceText
import cdx.Usb
import cdx.UsbAudio

# UsbTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_setup_packet : CceText
test_setup_packet = ({
	pkt = Usb.usb_setup_get_descriptor(Usb.usb_desc_device, 0, 18)
	bytes = Usb.usb_encode_setup(pkt)
	CceText.concat(CceText.concat(CceText.concat("setup: len=", CceText.show_int(U64.to_i64_wrap(List.len(bytes)))), " req="), CceText.show_int(pkt.sp_request))
})

test_endpoint : CceText
test_endpoint = ({
	bytes = [7, 5, 129, 1, 192, 0, 1]
	ep = Usb.usb_parse_endpoint(bytes, 0)
	CceText.concat("ep: ", Usb.format_usb_endpoint(ep))
})

test_audio_format : CceText
test_audio_format = ({
	cd = UsbAudio.audio_format_cd
	CceText.concat("cd: ", UsbAudio.format_audio_format(cd))
})

test_audio_frame : CceText
test_audio_frame = ({
	left = [500, (0 - 500)]
	right = [300, (0 - 300)]
	frame = UsbAudio.usb_audio_frame(left, right, UsbAudio.audio_format_cd)
	CceText.concat("frame: bytes=", CceText.show_int(U64.to_i64_wrap(List.len(frame))))
})

test_latency : CceText
test_latency = ({
	fmt = UsbAudio.audio_format_48k
	CceText.concat(CceText.concat(CceText.concat("latency-256=", CceText.show_int(UsbAudio.usb_audio_latency_ms(fmt, 256))), "ms bps="), CceText.show_int(UsbAudio.usb_audio_bytes_per_second(fmt)))
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(test_setup_packet))
	line!(CceText.printed(test_endpoint))
	line!(CceText.printed(test_audio_format))
	line!(CceText.printed(test_audio_frame))
	line!(CceText.printed(test_latency))
	Ok({})
}
