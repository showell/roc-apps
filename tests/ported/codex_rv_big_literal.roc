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

import cdx.Text

# RvBigLiteral -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([15, 14, 73, 32, 16, 25, 18, 22, 15, 21, 30, 2, 27, 15, 18, 14, 2, 12, 5, 5, 6, 6, 10, 5, 3, 6, 7, 10, 3, 10, 5, 12, 5, 4, 8, 12, 2, 29, 16, 14, 2], Text.show_int(9223372034707292159))))
	line!(Text.printed(List.concat([31, 15, 19, 14, 73, 32, 16, 25, 18, 22, 15, 21, 30, 2, 27, 15, 18, 14, 2, 12, 5, 5, 6, 6, 10, 5, 3, 6, 7, 10, 3, 10, 5, 12, 5, 4, 9, 3, 2, 29, 16, 14, 2], Text.show_int(9223372034707292160))))
	line!(Text.printed(List.concat([26, 15, 36, 2, 27, 15, 18, 14, 2, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 10, 2, 29, 16, 14, 2], Text.show_int(9223372036854775807))))
	line!(Text.printed(List.concat([26, 15, 36, 73, 4, 2, 27, 15, 18, 14, 2, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 9, 2, 29, 16, 14, 2], Text.show_int(9223372036854775806))))
	line!(Text.printed(List.concat([26, 17, 18, 2, 27, 15, 18, 14, 2, 73, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 11, 2, 29, 16, 14, 2], Text.show_int((-9223372036854775808)))))
	line!(Text.printed(List.concat([15, 23, 23, 28, 2, 27, 15, 18, 14, 2, 73, 4, 2, 29, 16, 14, 2], Text.show_int((-1)))))
	line!(Text.printed(List.concat([35, 25, 19, 14, 73, 16, 33, 13, 21, 73, 6, 5, 2, 27, 15, 18, 14, 2, 5, 4, 7, 10, 7, 11, 6, 9, 7, 11, 2, 29, 16, 14, 2], Text.show_int(2147483648))))
	line!(Text.printed(List.concat([14, 16, 31, 73, 16, 28, 73, 6, 5, 2, 27, 15, 18, 14, 2, 5, 4, 7, 10, 7, 11, 6, 9, 7, 10, 2, 29, 16, 14, 2], Text.show_int(2147483647))))
	line!(Text.printed(List.concat([32, 16, 14, 14, 16, 26, 73, 16, 28, 73, 6, 5, 2, 27, 15, 18, 14, 2, 73, 5, 4, 7, 10, 7, 11, 6, 9, 7, 11, 2, 29, 16, 14, 2], Text.show_int((0 - 2147483648)))))
	line!(Text.printed(List.concat([25, 18, 22, 13, 21, 73, 6, 5, 2, 27, 15, 18, 14, 2, 73, 5, 4, 7, 10, 7, 11, 6, 9, 7, 12, 2, 29, 16, 14, 2], Text.show_int((0 - 2147483649)))))
	Ok({})
}
