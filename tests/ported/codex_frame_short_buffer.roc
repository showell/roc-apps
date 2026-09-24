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

import cdx.CceText
import cdx.MessageFraming

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
			line!(CceText.printed(CceText.concat("whole-len=", CceText.show_int(CceText.len(w.value)))))
			line!(CceText.printed(CceText.concat("whole-next=", CceText.show_int(w.next_offset))))
			line!(CceText.printed(CceText.concat("short-len=", CceText.show_int(CceText.len(MessageFraming.frame_decode_text(short, 0).value)))))
			line!(CceText.printed(CceText.concat("huge-len=", CceText.show_int(CceText.len(MessageFraming.frame_decode_text(huge, 0).value)))))
			line!(CceText.printed(CceText.concat("runt-len=", CceText.show_int(CceText.len(MessageFraming.frame_decode_text(runt, 0).value)))))
			line!(CceText.printed(CceText.concat("empty-len=", CceText.show_int(CceText.len(MessageFraming.frame_decode_text(empty_bs, 0).value)))))
			line!(CceText.printed(CceText.concat("whole-bytes=", CceText.show_int(U64.to_i64_wrap(List.len(MessageFraming.frame_decode_bytes(whole, 0).value))))))
			line!(CceText.printed(CceText.concat("short-bytes=", CceText.show_int(U64.to_i64_wrap(List.len(MessageFraming.frame_decode_bytes(short, 0).value))))))
			line!(CceText.printed(CceText.concat("huge-bytes=", CceText.show_int(U64.to_i64_wrap(List.len(MessageFraming.frame_decode_bytes(huge, 0).value))))))
			line!(CceText.printed(CceText.concat("tag-of-runt=", CceText.show_int(MessageFraming.frame_decode_tag(runt)))))
			line!(CceText.printed(CceText.concat("len-of-runt=", CceText.show_int(MessageFraming.frame_decode_length(runt)))))
			line!(CceText.printed(CceText.concat("body-of-short=", CceText.show_int(U64.to_i64_wrap(List.len(MessageFraming.frame_decode_body(short)))))))
			line!(CceText.printed(CceText.concat("whole-valid=", (if w.valid { "True" } else { "False" }))))
			line!(CceText.printed(CceText.concat("declared-empty-len=", CceText.show_int(CceText.len(MessageFraming.frame_decode_text(declared_empty, 0).value)))))
			line!(CceText.printed(CceText.concat("declared-empty-valid=", (if MessageFraming.frame_decode_text(declared_empty, 0).valid { "True" } else { "False" }))))
			line!(CceText.printed(CceText.concat("short-valid=", (if MessageFraming.frame_decode_text(short, 0).valid { "True" } else { "False" }))))
			line!(CceText.printed(CceText.concat("huge-valid=", (if MessageFraming.frame_decode_text(huge, 0).valid { "True" } else { "False" }))))
			line!(CceText.printed(CceText.concat("runt-valid=", (if MessageFraming.frame_decode_text(runt, 0).valid { "True" } else { "False" }))))
			line!(CceText.printed(CceText.concat("empty-valid=", (if MessageFraming.frame_decode_text(empty_bs, 0).valid { "True" } else { "False" }))))
			line!(CceText.printed(CceText.concat("bytes-whole-valid=", (if MessageFraming.frame_decode_bytes(whole, 0).valid { "True" } else { "False" }))))
			line!(CceText.printed(CceText.concat("bytes-short-valid=", (if MessageFraming.frame_decode_bytes(short, 0).valid { "True" } else { "False" }))))
			line!(CceText.printed("survived"))
		})
	})
	Ok({})
}
