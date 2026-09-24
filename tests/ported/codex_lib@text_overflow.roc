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

import cdx.CceText
import cdx.TextOverflow

# TextOverflowTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

plan : TextOverflow.TextOverflow, I64, I64, I64, I64 -> CceText
plan = |m, len, avail, adv, gw| CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("  ", TextOverflow.text_overflow_name(m)), " len="), CceText.show_int(len)), " avail="), CceText.show_int(avail)), " adv="), CceText.show_int(adv)), " gw="), CceText.show_int(gw)), " -> start="), CceText.show_int(TextOverflow.text_overflow_start(m, len, avail, adv, gw))), " count="), CceText.show_int(TextOverflow.text_overflow_count(m, len, avail, adv, gw))), " dots="), CceText.show_int(TextOverflow.text_overflow_dots(m, len, avail, adv, gw)))

all_modes : I64, I64, I64, I64 -> CceText
all_modes = |len, avail, adv, gw| CceText.concat(CceText.concat(CceText.concat(CceText.concat(plan(OverflowClip, len, avail, adv, gw), "\n"), plan(OverflowEllipsis, len, avail, adv, gw)), "\n"), plan(OverflowScroll, len, avail, adv, gw))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed("fits exactly, no overflow: every mode must agree"))
	line!(CceText.printed(all_modes(10, 60, 6, 5)))
	line!(CceText.printed(""))
	line!(CceText.printed("shorter than the box: every mode must agree"))
	line!(CceText.printed(all_modes(4, 60, 6, 5)))
	line!(CceText.printed(""))
	line!(CceText.printed("overflowing, adv=6 (GPU walk), 20 chars in 60px"))
	line!(CceText.printed(all_modes(20, 60, 6, 5)))
	line!(CceText.printed(""))
	line!(CceText.printed("overflowing, adv=9 (GopBuf walk), 20 chars in 63px"))
	line!(CceText.printed(all_modes(20, 63, 9, 8)))
	line!(CceText.printed(""))
	line!(CceText.printed("overflowing, adv=10 (SystemFont walk), 20 chars in 100px"))
	line!(CceText.printed(all_modes(20, 100, 10, 8)))
	line!(CceText.printed(""))
	line!(CceText.printed("a box too narrow for an ellipsis falls back to clip"))
	line!(CceText.printed(all_modes(20, 18, 6, 5)))
	line!(CceText.printed(all_modes(20, 24, 6, 5)))
	line!(CceText.printed(""))
	line!(CceText.printed("degenerate boxes draw nothing"))
	line!(CceText.printed(all_modes(20, 0, 6, 5)))
	line!(CceText.printed(all_modes(20, (0 - 40), 6, 5)))
	line!(CceText.printed(all_modes(20, 60, 0, 5)))
	line!(CceText.printed(""))
	line!(CceText.printed(CceText.concat("default mode: ", TextOverflow.text_overflow_name(TextOverflow.text_overflow_default))))
	Ok({})
}
