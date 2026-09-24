# rv-big-literal
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/rv-big-literal.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     at-boundary want 9223372034707292159 got 9223372034707292159
#     past-boundary want 9223372034707292160 got 9223372034707292160
#     max want 9223372036854775807 got 9223372036854775807
#     max-1 want 9223372036854775806 got 9223372036854775806
#     min want -9223372036854775808 got -9223372036854775808
#     allf want -1 got -1
#     just-over-32 want 2147483648 got 2147483648
#     top-of-32 want 2147483647 got 2147483647
#     bottom-of-32 want -2147483648 got -2147483648
#     under-32 want -2147483649 got -2147483649

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# RvBigLiteral -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("at-boundary want 9223372034707292159 got ", CceText.show_int(9223372034707292159))))
	line!(CceText.printed(CceText.concat("past-boundary want 9223372034707292160 got ", CceText.show_int(9223372034707292160))))
	line!(CceText.printed(CceText.concat("max want 9223372036854775807 got ", CceText.show_int(9223372036854775807))))
	line!(CceText.printed(CceText.concat("max-1 want 9223372036854775806 got ", CceText.show_int(9223372036854775806))))
	line!(CceText.printed(CceText.concat("min want -9223372036854775808 got ", CceText.show_int((-9223372036854775808)))))
	line!(CceText.printed(CceText.concat("allf want -1 got ", CceText.show_int((-1)))))
	line!(CceText.printed(CceText.concat("just-over-32 want 2147483648 got ", CceText.show_int(2147483648))))
	line!(CceText.printed(CceText.concat("top-of-32 want 2147483647 got ", CceText.show_int(2147483647))))
	line!(CceText.printed(CceText.concat("bottom-of-32 want -2147483648 got ", CceText.show_int((0 - 2147483648)))))
	line!(CceText.printed(CceText.concat("under-32 want -2147483649 got ", CceText.show_int((0 - 2147483649)))))
	Ok({})
}
