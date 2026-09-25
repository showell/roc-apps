# pit-rate
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/pit-rate.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     the input clock is 1193182 hz
#     the count is 11932
#     164 ms is 17 ticks
#     54 ms is 6 ticks
#     219 ms is 22 ticks
#     a day is 8639869 ticks

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# PitRate -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

ms_ticks : I64 -> I64
ms_ticks = |ms| I64.div_trunc_by((((ms * 1193182) + (11932 * 1000)) - 1), (11932 * 1000))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed((if (1193182 == 1193182) { "the input clock is 1193182 hz" } else { CceText.concat("INPUT CLOCK ", CceText.show_int(1193182)) })))
	line!(CceText.printed((if (11932 == 11932) { "the count is 11932" } else { CceText.concat("COUNT ", CceText.show_int(11932)) })))
	line!(CceText.printed(CceText.concat(CceText.concat("164 ms is ", CceText.show_int(ms_ticks(164))), " ticks")))
	line!(CceText.printed(CceText.concat(CceText.concat("54 ms is ", CceText.show_int(ms_ticks(54))), " ticks")))
	line!(CceText.printed(CceText.concat(CceText.concat("219 ms is ", CceText.show_int(ms_ticks(219))), " ticks")))
	line!(CceText.printed(CceText.concat(CceText.concat("a day is ", CceText.show_int(I64.div_trunc_by((86400 * 1193182), 11932))), " ticks")))
	Ok({})
}
