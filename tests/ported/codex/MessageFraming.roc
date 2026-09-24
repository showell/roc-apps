# MessageFraming -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceChar
import CceText
import Sha256

MessageFraming :: [].{
	FrameTextResult := { value : CceText, next_offset : I64, valid : Bool }.{
		is_eq : MessageFraming.FrameTextResult, MessageFraming.FrameTextResult -> Bool
		is_eq = |a, b| a.value == b.value and a.next_offset == b.next_offset and a.valid == b.valid
	}
	FrameBytesResult := { value : List(I64), next_offset : I64, valid : Bool }.{
		is_eq : MessageFraming.FrameBytesResult, MessageFraming.FrameBytesResult -> Bool
		is_eq = |a, b| a.value == b.value and a.next_offset == b.next_offset and a.valid == b.valid
	}

	frame_encode : I64, List(I64) -> List(I64)
	frame_encode = |type_tag, body| ({
		total = (1 + U64.to_i64_wrap(List.len(body)))
		List.concat(List.concat(frame_le32(total), [type_tag]), body)
	})

	frame_byte_at : List(I64), I64 -> I64
	frame_byte_at = |bs, i| (if (i < 0) { 0 } else { (if (i >= U64.to_i64_wrap(List.len(bs))) { 0 } else { (List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) }) })

	frame_next_offset : List(I64), I64 -> I64
	frame_next_offset = |bs, v| (if (v < 0) { 0 } else { (if (v > U64.to_i64_wrap(List.len(bs))) { U64.to_i64_wrap(List.len(bs)) } else { v }) })

	frame_fits : List(I64), I64, I64 -> Bool
	frame_fits = |bs, offset, len| (if (offset < 0) { False } else { (if (offset > (U64.to_i64_wrap(List.len(bs)) - 4)) { False } else { (len <= ((U64.to_i64_wrap(List.len(bs)) - 4) - offset)) }) })

	frame_decode_length : List(I64) -> I64
	frame_decode_length = |bs| (((frame_byte_at(bs, 0) + I64.shl_wrap(frame_byte_at(bs, 1), I64.to_u8_wrap(8))) + I64.shl_wrap(frame_byte_at(bs, 2), I64.to_u8_wrap(16))) + I64.shl_wrap(frame_byte_at(bs, 3), I64.to_u8_wrap(24)))

	frame_decode_tag : List(I64) -> I64
	frame_decode_tag = |bs| frame_byte_at(bs, 4)

	frame_decode_body : List(I64) -> List(I64)
	frame_decode_body = |bs| ({
		len = frame_decode_length(bs)
		frame_slice(bs, 5, (4 + len))
	})

	frame_le32 : I64 -> List(I64)
	frame_le32 = |v| [I64.bitwise_and(v, 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(16)), 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(24)), 255)]

	frame_le64 : I64 -> List(I64)
	frame_le64 = |v| List.concat(frame_le32(v), frame_le32(I64.shr_zf_wrap(v, I64.to_u8_wrap(32))))

	frame_encode_text : CceText -> List(I64)
	frame_encode_text = |s| ({
		bytes = frame_text_bytes(s, 0, CceText.len(s), [])
		List.concat(frame_le32(U64.to_i64_wrap(List.len(bytes))), bytes)
	})

	frame_text_bytes : CceText, I64, I64, List(I64) -> List(I64)
	frame_text_bytes = |s, i, len, acc| (if (i == len) { acc } else { frame_text_bytes(s, (i + 1), len, List.append(acc, CceChar.code(CceText.char_at(s, i)))) })

	frame_decode_text : List(I64), I64 -> MessageFraming.FrameTextResult
	frame_decode_text = |bs, offset| ({
		len = frame_read_le32(bs, offset)
		text = frame_bytes_to_text(bs, (offset + 4), len, "")
		MessageFraming.FrameTextResult.{ value: text, next_offset: frame_next_offset(bs, ((offset + 4) + len)), valid: frame_fits(bs, offset, len) }
	})

	frame_bytes_to_text : List(I64), I64, I64, CceText -> CceText
	frame_bytes_to_text = |bs, i, remaining, acc| (if (remaining <= 0) { acc } else { (if (i >= U64.to_i64_wrap(List.len(bs))) { acc } else { frame_bytes_to_text(bs, (i + 1), (remaining - 1), CceText.concat(acc, CceText.char_to_text(CceChar.of_code((List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))) }) })

	frame_read_le32 : List(I64), I64 -> I64
	frame_read_le32 = |bs, off| (((frame_byte_at(bs, off) + I64.shl_wrap(frame_byte_at(bs, (off + 1)), I64.to_u8_wrap(8))) + I64.shl_wrap(frame_byte_at(bs, (off + 2)), I64.to_u8_wrap(16))) + I64.shl_wrap(frame_byte_at(bs, (off + 3)), I64.to_u8_wrap(24)))

	frame_read_le64 : List(I64), I64 -> I64
	frame_read_le64 = |bs, off| (frame_read_le32(bs, off) + I64.shl_wrap(frame_read_le32(bs, (off + 4)), I64.to_u8_wrap(32)))

	frame_encode_bytes : List(I64) -> List(I64)
	frame_encode_bytes = |bs| List.concat(frame_le32(U64.to_i64_wrap(List.len(bs))), bs)

	frame_decode_bytes : List(I64), I64 -> MessageFraming.FrameBytesResult
	frame_decode_bytes = |bs, offset| ({
		len = frame_read_le32(bs, offset)
		MessageFraming.FrameBytesResult.{ value: frame_slice(bs, (offset + 4), ((offset + 4) + len)), next_offset: frame_next_offset(bs, ((offset + 4) + len)), valid: frame_fits(bs, offset, len) }
	})

	tag_propose : I64
	tag_propose = 1

	tag_grant : I64
	tag_grant = 2

	tag_deny : I64
	tag_deny = 3

	tag_explain : I64
	tag_explain = 4

	tag_narrate : I64
	tag_narrate = 5

	tag_interrupt : I64
	tag_interrupt = 6

	tag_handoff : I64
	tag_handoff = 7

	tag_hello : I64
	tag_hello = 8

	tag_challenge : I64
	tag_challenge = 9

	tag_prove : I64
	tag_prove = 10

	tag_accept : I64
	tag_accept = 11

	tag_annotate : I64
	tag_annotate = 12

	tag_verdict : I64
	tag_verdict = 13

	tag_reject : I64
	tag_reject = 14

	tag_sync_offer : I64
	tag_sync_offer = 15

	tag_sync_reply : I64
	tag_sync_reply = 16

	tag_work_request : I64
	tag_work_request = 17

	tag_work_reply : I64
	tag_work_reply = 18

	tag_locate_request : I64
	tag_locate_request = 19

	tag_locate_reply : I64
	tag_locate_reply = 20

	tag_announce_request : I64
	tag_announce_request = 21

	tag_announce_reply : I64
	tag_announce_reply = 22

	frame_content_hash : List(I64) -> List(I64)
	frame_content_hash = |body| Sha256.sha256(body)

	frame_slice : List(I64), I64, I64 -> List(I64)
	frame_slice = |xs, start, stop| frame_slice_loop(xs, start, stop, [])

	frame_slice_loop : List(I64), I64, I64, List(I64) -> List(I64)
	frame_slice_loop = |xs, i, stop, acc| (if (i >= stop) { acc } else { (if (i >= U64.to_i64_wrap(List.len(xs))) { acc } else { frame_slice_loop(xs, (i + 1), stop, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) }) })
}
