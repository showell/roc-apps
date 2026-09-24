# UsbAudio -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Maybe
import Text
import Usb

UsbAudio :: [].{
	UsbAudioDevice : { uad_slot : I64, uad_stream_ep : I64, uad_sample_rate : I64, uad_channels : I64, uad_bit_depth : I64, uad_max_packet : I64, uad_found : Bool }
	AudioFormat : { afmt_sample_rate : I64, afmt_channels : I64, afmt_bit_depth : I64, afmt_bytes_per_sample : I64 }
	UsbAudioBuffer : { uab_frames : List(List(I64)), uab_frame_size : I64, uab_frames_per_ms : I64, uab_total_frames : I64 }

	uac_desc_header : I64
	uac_desc_header = 1

	uac_desc_input_terminal : I64
	uac_desc_input_terminal = 2

	uac_desc_output_terminal : I64
	uac_desc_output_terminal = 3

	uac_desc_feature_unit : I64
	uac_desc_feature_unit = 6

	uac_desc_format_type : I64
	uac_desc_format_type = 2

	uac_cs_interface : I64
	uac_cs_interface = 36

	uac_cs_endpoint : I64
	uac_cs_endpoint = 37

	uac_terminal_usb_streaming : I64
	uac_terminal_usb_streaming = 257

	uac_terminal_speaker : I64
	uac_terminal_speaker = 769

	uac_terminal_headphones : I64
	uac_terminal_headphones = 770

	uac_terminal_microphone : I64
	uac_terminal_microphone = 513

	usb_audio_not_found : UsbAudio.UsbAudioDevice
	usb_audio_not_found = { uad_slot: 0, uad_stream_ep: 0, uad_sample_rate: 0, uad_channels: 0, uad_bit_depth: 0, uad_max_packet: 0, uad_found: False }

	usb_audio_detect : Usb.UsbInterface, List(I64), I64 -> Maybe.Maybe(UsbAudio.UsbAudioDevice)
	usb_audio_detect = |iface, _config_desc, slot| (if (iface.if_class == Usb.usb_class_audio) { (if (iface.if_subclass == Usb.usb_subclass_audio_streaming) { Just({ uad_slot: slot, uad_stream_ep: 0, uad_sample_rate: 44100, uad_channels: 2, uad_bit_depth: 16, uad_max_packet: 192, uad_found: True }) } else { None }) } else { None })

	audio_format_cd : UsbAudio.AudioFormat
	audio_format_cd = { afmt_sample_rate: 44100, afmt_channels: 2, afmt_bit_depth: 16, afmt_bytes_per_sample: 4 }

	audio_format_48k : UsbAudio.AudioFormat
	audio_format_48k = { afmt_sample_rate: 48000, afmt_channels: 2, afmt_bit_depth: 16, afmt_bytes_per_sample: 4 }

	audio_format_hires : UsbAudio.AudioFormat
	audio_format_hires = { afmt_sample_rate: 96000, afmt_channels: 2, afmt_bit_depth: 24, afmt_bytes_per_sample: 6 }

	usb_audio_frame : List(I64), List(I64), UsbAudio.AudioFormat -> List(I64)
	usb_audio_frame = |left, right, fmt| usb_interleave(left, right, fmt, 0, uaf_min(U64.to_i64_wrap(List.len(left)), U64.to_i64_wrap(List.len(right))), [])

	usb_interleave : List(I64), List(I64), UsbAudio.AudioFormat, I64, I64, List(I64) -> List(I64)
	usb_interleave = |left, right, fmt, i, n, acc| (if (i >= n) { acc } else { ({
		l_pcm = uaf_to_pcm((List.get(left, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), fmt.afmt_bit_depth)
		r_pcm = uaf_to_pcm((List.get(right, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), fmt.afmt_bit_depth)
		l_bytes = uaf_pcm_bytes(l_pcm, fmt.afmt_bit_depth)
		r_bytes = uaf_pcm_bytes(r_pcm, fmt.afmt_bit_depth)
		usb_interleave(left, right, fmt, (i + 1), n, List.concat(List.concat(acc, l_bytes), r_bytes))
	}) })

	uaf_to_pcm : I64, I64 -> I64
	uaf_to_pcm = |fixed, bits| (if (bits == 16) { ({
		scaled = I64.div_trunc_by((fixed * 32767), 1000)
		(if (scaled > 32767) { 32767 } else { (if (scaled < (0 - 32768)) { (0 - 32768) } else { scaled }) })
	}) } else { (if (bits == 24) { ({
		scaled = I64.div_trunc_by((fixed * 8388607), 1000)
		(if (scaled > 8388607) { 8388607 } else { (if (scaled < (0 - 8388608)) { (0 - 8388608) } else { scaled }) })
	}) } else { fixed }) })

	uaf_pcm_bytes : I64, I64 -> List(I64)
	uaf_pcm_bytes = |pcm, bits| ({
		unsigned = (if (pcm < 0) { ((if (bits == 16) { 65536 } else { 16777216 }) + pcm) } else { pcm })
		(if (bits == 16) { [I64.bitwise_and(unsigned, 255), I64.bitwise_and(I64.shr_zf_wrap(unsigned, I64.to_u8_wrap(8)), 255)] } else { [I64.bitwise_and(unsigned, 255), I64.bitwise_and(I64.shr_zf_wrap(unsigned, I64.to_u8_wrap(8)), 255), I64.bitwise_and(I64.shr_zf_wrap(unsigned, I64.to_u8_wrap(16)), 255)] })
	})

	usb_audio_buffer : UsbAudio.AudioFormat, I64 -> UsbAudio.UsbAudioBuffer
	usb_audio_buffer = |fmt, duration_ms| ({
		samples_per_ms = I64.div_trunc_by(fmt.afmt_sample_rate, 1000)
		frame_size = (samples_per_ms * fmt.afmt_bytes_per_sample)
		{ uab_frames: [], uab_frame_size: frame_size, uab_frames_per_ms: samples_per_ms, uab_total_frames: duration_ms }
	})

	usb_audio_set_volume : I64 -> List(I64)
	usb_audio_set_volume = |volume_pct| ({
		db_val = (if (volume_pct >= 100) { 0 } else { (if (volume_pct <= 0) { (0 - 32768) } else { ((volume_pct - 100) * 256) }) })
		Usb.usb_le16_encode(db_val)
	})

	usb_audio_bytes_per_second : UsbAudio.AudioFormat -> I64
	usb_audio_bytes_per_second = |fmt| (fmt.afmt_sample_rate * fmt.afmt_bytes_per_sample)

	usb_audio_latency_ms : UsbAudio.AudioFormat, I64 -> I64
	usb_audio_latency_ms = |fmt, buffer_frames| I64.div_trunc_by((buffer_frames * 1000), fmt.afmt_sample_rate)

	uaf_min : I64, I64 -> I64
	uaf_min = |a, b| (if (a < b) { a } else { b })

	format_usb_audio : UsbAudio.UsbAudioDevice -> Text
	format_usb_audio = |dev| (if dev.uad_found { Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("USB Audio: ", Text.show_int(dev.uad_sample_rate)), "Hz "), Text.show_int(dev.uad_channels)), "ch "), Text.show_int(dev.uad_bit_depth)), "bit EP"), Text.show_int(dev.uad_stream_ep)) } else { "USB Audio: not found" })

	format_audio_format : UsbAudio.AudioFormat -> Text
	format_audio_format = |fmt| Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.show_int(fmt.afmt_sample_rate), "Hz "), Text.show_int(fmt.afmt_channels)), "ch "), Text.show_int(fmt.afmt_bit_depth)), "bit ("), Text.show_int(usb_audio_bytes_per_second(fmt))), " B/s)")
}
