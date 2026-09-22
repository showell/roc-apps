# frame-short-buffer
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/frame-short-buffer.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     whole-len=4
#     whole-next=8
#     short-len=0
#     huge-len=0
#     runt-len=0
#     empty-len=0
#     whole-bytes=4
#     short-bytes=0
#     huge-bytes=0
#     tag-of-runt=0
#     len-of-runt=7
#     body-of-short=0
#     whole-valid=True
#     declared-empty-len=0
#     declared-empty-valid=True
#     short-valid=False
#     huge-valid=False
#     runt-valid=False
#     empty-valid=False
#     bytes-whole-valid=True
#     bytes-short-valid=False
#     survived

app [main!] { cdx: "./codex/main.roc" }

import cdx.MessageFraming
import cdx.Text

# FrameShortBuffer -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

whole : List(I64)
whole = [4, 0, 0, 0, 65, 66, 67, 68]

short : List(I64)
short = [4, 0, 0, 0]

huge : List(I64)
huge = [255, 255, 255, 255]

runt : List(I64)
runt = [7]

empty_bs : List(I64)
empty_bs = []

declared_empty : List(I64)
declared_empty = [0, 0, 0, 0]

# --- Entry ---

main! = |_args| {
	({
		w = MessageFraming.frame_decode_text(whole, 0)
		({
			line!(Text.printed(List.concat([27, 20, 16, 23, 13, 73, 23, 13, 18, 77], Text.show_int(Text.len(w.value)))))
			line!(Text.printed(List.concat([27, 20, 16, 23, 13, 73, 18, 13, 36, 14, 77], Text.show_int(w.next_offset))))
			line!(Text.printed(List.concat([19, 20, 16, 21, 14, 73, 23, 13, 18, 77], Text.show_int(Text.len(MessageFraming.frame_decode_text(short, 0).value)))))
			line!(Text.printed(List.concat([20, 25, 29, 13, 73, 23, 13, 18, 77], Text.show_int(Text.len(MessageFraming.frame_decode_text(huge, 0).value)))))
			line!(Text.printed(List.concat([21, 25, 18, 14, 73, 23, 13, 18, 77], Text.show_int(Text.len(MessageFraming.frame_decode_text(runt, 0).value)))))
			line!(Text.printed(List.concat([13, 26, 31, 14, 30, 73, 23, 13, 18, 77], Text.show_int(Text.len(MessageFraming.frame_decode_text(empty_bs, 0).value)))))
			line!(Text.printed(List.concat([27, 20, 16, 23, 13, 73, 32, 30, 14, 13, 19, 77], Text.show_int(U64.to_i64_wrap(List.len(MessageFraming.frame_decode_bytes(whole, 0).value))))))
			line!(Text.printed(List.concat([19, 20, 16, 21, 14, 73, 32, 30, 14, 13, 19, 77], Text.show_int(U64.to_i64_wrap(List.len(MessageFraming.frame_decode_bytes(short, 0).value))))))
			line!(Text.printed(List.concat([20, 25, 29, 13, 73, 32, 30, 14, 13, 19, 77], Text.show_int(U64.to_i64_wrap(List.len(MessageFraming.frame_decode_bytes(huge, 0).value))))))
			line!(Text.printed(List.concat([14, 15, 29, 73, 16, 28, 73, 21, 25, 18, 14, 77], Text.show_int(MessageFraming.frame_decode_tag(runt)))))
			line!(Text.printed(List.concat([23, 13, 18, 73, 16, 28, 73, 21, 25, 18, 14, 77], Text.show_int(MessageFraming.frame_decode_length(runt)))))
			line!(Text.printed(List.concat([32, 16, 22, 30, 73, 16, 28, 73, 19, 20, 16, 21, 14, 77], Text.show_int(U64.to_i64_wrap(List.len(MessageFraming.frame_decode_body(short)))))))
			line!(Text.printed(List.concat([27, 20, 16, 23, 13, 73, 33, 15, 23, 17, 22, 77], (if w.valid { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
			line!(Text.printed(List.concat([22, 13, 24, 23, 15, 21, 13, 22, 73, 13, 26, 31, 14, 30, 73, 23, 13, 18, 77], Text.show_int(Text.len(MessageFraming.frame_decode_text(declared_empty, 0).value)))))
			line!(Text.printed(List.concat([22, 13, 24, 23, 15, 21, 13, 22, 73, 13, 26, 31, 14, 30, 73, 33, 15, 23, 17, 22, 77], (if MessageFraming.frame_decode_text(declared_empty, 0).valid { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
			line!(Text.printed(List.concat([19, 20, 16, 21, 14, 73, 33, 15, 23, 17, 22, 77], (if MessageFraming.frame_decode_text(short, 0).valid { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
			line!(Text.printed(List.concat([20, 25, 29, 13, 73, 33, 15, 23, 17, 22, 77], (if MessageFraming.frame_decode_text(huge, 0).valid { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
			line!(Text.printed(List.concat([21, 25, 18, 14, 73, 33, 15, 23, 17, 22, 77], (if MessageFraming.frame_decode_text(runt, 0).valid { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
			line!(Text.printed(List.concat([13, 26, 31, 14, 30, 73, 33, 15, 23, 17, 22, 77], (if MessageFraming.frame_decode_text(empty_bs, 0).valid { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
			line!(Text.printed(List.concat([32, 30, 14, 13, 19, 73, 27, 20, 16, 23, 13, 73, 33, 15, 23, 17, 22, 77], (if MessageFraming.frame_decode_bytes(whole, 0).valid { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
			line!(Text.printed(List.concat([32, 30, 14, 13, 19, 73, 19, 20, 16, 21, 14, 73, 33, 15, 23, 17, 22, 77], (if MessageFraming.frame_decode_bytes(short, 0).valid { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
			line!(Text.printed([19, 25, 21, 33, 17, 33, 13, 22]))
		})
	})
	Ok({})
}
