# lib@text-overflow
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@text-overflow.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     fits exactly, no overflow: every mode must agree
#       clip len=10 avail=60 adv=6 gw=5 -> start=0 count=10 dots=0
#       ellipsis len=10 avail=60 adv=6 gw=5 -> start=0 count=10 dots=0
#       scroll len=10 avail=60 adv=6 gw=5 -> start=0 count=10 dots=0
#     
#     shorter than the box: every mode must agree
#       clip len=4 avail=60 adv=6 gw=5 -> start=0 count=4 dots=0
#       ellipsis len=4 avail=60 adv=6 gw=5 -> start=0 count=4 dots=0
#       scroll len=4 avail=60 adv=6 gw=5 -> start=0 count=4 dots=0
#     
#     overflowing, adv=6 (GPU walk), 20 chars in 60px
#       clip len=20 avail=60 adv=6 gw=5 -> start=0 count=10 dots=0
#       ellipsis len=20 avail=60 adv=6 gw=5 -> start=0 count=7 dots=3
#       scroll len=20 avail=60 adv=6 gw=5 -> start=10 count=10 dots=0
#     
#     overflowing, adv=9 (GopBuf walk), 20 chars in 63px
#       clip len=20 avail=63 adv=9 gw=8 -> start=0 count=7 dots=0
#       ellipsis len=20 avail=63 adv=9 gw=8 -> start=0 count=4 dots=3
#       scroll len=20 avail=63 adv=9 gw=8 -> start=13 count=7 dots=0
#     
#     overflowing, adv=10 (SystemFont walk), 20 chars in 100px
#       clip len=20 avail=100 adv=10 gw=8 -> start=0 count=10 dots=0
#       ellipsis len=20 avail=100 adv=10 gw=8 -> start=0 count=7 dots=3
#       scroll len=20 avail=100 adv=10 gw=8 -> start=10 count=10 dots=0
#     
#     a box too narrow for an ellipsis falls back to clip
#       clip len=20 avail=18 adv=6 gw=5 -> start=0 count=3 dots=0
#       ellipsis len=20 avail=18 adv=6 gw=5 -> start=0 count=3 dots=0
#       scroll len=20 avail=18 adv=6 gw=5 -> start=17 count=3 dots=0
#       clip len=20 avail=24 adv=6 gw=5 -> start=0 count=4 dots=0
#       ellipsis len=20 avail=24 adv=6 gw=5 -> start=0 count=1 dots=3
#       scroll len=20 avail=24 adv=6 gw=5 -> start=16 count=4 dots=0
#     
#     degenerate boxes draw nothing
#       clip len=20 avail=0 adv=6 gw=5 -> start=0 count=0 dots=0
#       ellipsis len=20 avail=0 adv=6 gw=5 -> start=0 count=0 dots=0
#       scroll len=20 avail=0 adv=6 gw=5 -> start=20 count=0 dots=0
#       clip len=20 avail=-40 adv=6 gw=5 -> start=0 count=0 dots=0
#       ellipsis len=20 avail=-40 adv=6 gw=5 -> start=0 count=0 dots=0
#       scroll len=20 avail=-40 adv=6 gw=5 -> start=20 count=0 dots=0
#       clip len=20 avail=60 adv=0 gw=5 -> start=0 count=0 dots=0
#       ellipsis len=20 avail=60 adv=0 gw=5 -> start=0 count=0 dots=0
#       scroll len=20 avail=60 adv=0 gw=5 -> start=20 count=0 dots=0
#     
#     default mode: clip

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text
import cdx.TextOverflow

# TextOverflowTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

plan : TextOverflow.TextOverflow, I64, I64, I64, I64 -> List(U8)
plan = |m, len, avail, adv, gw| List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([2, 2], TextOverflow.text_overflow_name(m)), [2, 23, 13, 18, 77]), Text.show_int(len)), [2, 15, 33, 15, 17, 23, 77]), Text.show_int(avail)), [2, 15, 22, 33, 77]), Text.show_int(adv)), [2, 29, 27, 77]), Text.show_int(gw)), [2, 73, 80, 2, 19, 14, 15, 21, 14, 77]), Text.show_int(TextOverflow.text_overflow_start(m, len, avail, adv, gw))), [2, 24, 16, 25, 18, 14, 77]), Text.show_int(TextOverflow.text_overflow_count(m, len, avail, adv, gw))), [2, 22, 16, 14, 19, 77]), Text.show_int(TextOverflow.text_overflow_dots(m, len, avail, adv, gw)))

all_modes : I64, I64, I64, I64 -> List(U8)
all_modes = |len, avail, adv, gw| List.concat(List.concat(List.concat(List.concat(plan(OverflowClip, len, avail, adv, gw), [1]), plan(OverflowEllipsis, len, avail, adv, gw)), [1]), plan(OverflowScroll, len, avail, adv, gw))

# --- Entry ---

main! = |_args| {
	line!(Text.printed([28, 17, 14, 19, 2, 13, 36, 15, 24, 14, 23, 30, 66, 2, 18, 16, 2, 16, 33, 13, 21, 28, 23, 16, 27, 69, 2, 13, 33, 13, 21, 30, 2, 26, 16, 22, 13, 2, 26, 25, 19, 14, 2, 15, 29, 21, 13, 13]))
	line!(Text.printed(all_modes(10, 60, 6, 5)))
	line!(Text.printed([]))
	line!(Text.printed([19, 20, 16, 21, 14, 13, 21, 2, 14, 20, 15, 18, 2, 14, 20, 13, 2, 32, 16, 36, 69, 2, 13, 33, 13, 21, 30, 2, 26, 16, 22, 13, 2, 26, 25, 19, 14, 2, 15, 29, 21, 13, 13]))
	line!(Text.printed(all_modes(4, 60, 6, 5)))
	line!(Text.printed([]))
	line!(Text.printed([16, 33, 13, 21, 28, 23, 16, 27, 17, 18, 29, 66, 2, 15, 22, 33, 77, 9, 2, 74, 55, 57, 51, 2, 27, 15, 23, 34, 75, 66, 2, 5, 3, 2, 24, 20, 15, 21, 19, 2, 17, 18, 2, 9, 3, 31, 36]))
	line!(Text.printed(all_modes(20, 60, 6, 5)))
	line!(Text.printed([]))
	line!(Text.printed([16, 33, 13, 21, 28, 23, 16, 27, 17, 18, 29, 66, 2, 15, 22, 33, 77, 12, 2, 74, 55, 16, 31, 58, 25, 28, 2, 27, 15, 23, 34, 75, 66, 2, 5, 3, 2, 24, 20, 15, 21, 19, 2, 17, 18, 2, 9, 6, 31, 36]))
	line!(Text.printed(all_modes(20, 63, 9, 8)))
	line!(Text.printed([]))
	line!(Text.printed([16, 33, 13, 21, 28, 23, 16, 27, 17, 18, 29, 66, 2, 15, 22, 33, 77, 4, 3, 2, 74, 45, 30, 19, 14, 13, 26, 54, 16, 18, 14, 2, 27, 15, 23, 34, 75, 66, 2, 5, 3, 2, 24, 20, 15, 21, 19, 2, 17, 18, 2, 4, 3, 3, 31, 36]))
	line!(Text.printed(all_modes(20, 100, 10, 8)))
	line!(Text.printed([]))
	line!(Text.printed([15, 2, 32, 16, 36, 2, 14, 16, 16, 2, 18, 15, 21, 21, 16, 27, 2, 28, 16, 21, 2, 15, 18, 2, 13, 23, 23, 17, 31, 19, 17, 19, 2, 28, 15, 23, 23, 19, 2, 32, 15, 24, 34, 2, 14, 16, 2, 24, 23, 17, 31]))
	line!(Text.printed(all_modes(20, 18, 6, 5)))
	line!(Text.printed(all_modes(20, 24, 6, 5)))
	line!(Text.printed([]))
	line!(Text.printed([22, 13, 29, 13, 18, 13, 21, 15, 14, 13, 2, 32, 16, 36, 13, 19, 2, 22, 21, 15, 27, 2, 18, 16, 14, 20, 17, 18, 29]))
	line!(Text.printed(all_modes(20, 0, 6, 5)))
	line!(Text.printed(all_modes(20, (0 - 40), 6, 5)))
	line!(Text.printed(all_modes(20, 60, 0, 5)))
	line!(Text.printed([]))
	line!(Text.printed(List.concat([22, 13, 28, 15, 25, 23, 14, 2, 26, 16, 22, 13, 69, 2], TextOverflow.text_overflow_name(TextOverflow.text_overflow_default))))
	Ok({})
}
