# lib@format-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@format-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#         hi
#     hi....
#     ---hi---
#     ababab
#     a, b, c
#     1,234,567
#     42
#     -9,876,543
#        7
#     ff
#     1000
#     000f
#     true
#     no

app [main!] { cdx: "./codex/main.roc" }

import cdx.Format
import cdx.Text

# FormatTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Format.fmt_pad_left("hi", 6, " ")))
	line!(Text.printed(Format.fmt_pad_right("hi", 6, ".")))
	line!(Text.printed(Format.fmt_center("hi", 8, "-")))
	line!(Text.printed(Format.fmt_repeat("ab", 3)))
	line!(Text.printed(Format.fmt_join(["a", "b", "c"], ", ")))
	line!(Text.printed(Format.fmt_commas(1234567)))
	line!(Text.printed(Format.fmt_commas(42)))
	line!(Text.printed(Format.fmt_commas((0 - 9876543))))
	line!(Text.printed(Format.fmt_fixed_width(7, 4)))
	line!(Text.printed(Format.fmt_hex(255)))
	line!(Text.printed(Format.fmt_hex(4096)))
	line!(Text.printed(Format.fmt_hex_pad(15, 4)))
	line!(Text.printed(Format.fmt_bool(True)))
	line!(Text.printed(Format.fmt_yes_no(False)))
	Ok({})
}
