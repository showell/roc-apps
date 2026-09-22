# ops@int-add-wrapping
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@int-add-wrapping.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     funnel-add want -9223372036854775808: -9223372036854775808
#     funnel-sub want 9223372036854775807: 9223372036854775807
#     param-add  want -9223372036854775808: -9223372036854775808
#     param-sub  want 9223372036854775807: 9223372036854775807
#     imm-add    want -9223372036854775808: -9223372036854775808
#     imm-sub    want 9223372036854775807: 9223372036854775807
#     in-band    want 9000000000000000000: 9000000000000000000
#     in-band    want -9000000000000000000: -9000000000000000000
#     small      want 42: 42
#     small      want 42: 42

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text
import cdx.Wrap64

# IntAddWrapping -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

top : I64
top = 9223372036854775807

bottom : I64
bottom = ((0 - 9223372036854775807) - 1)

add_param : I64, I64 -> I64
add_param = |a, b| I64.plus_wrap(a, b)

sub_param : I64, I64 -> I64
sub_param = |a, b| I64.minus_wrap(a, b)

add_imm_param : I64 -> I64
add_imm_param = |a| I64.plus_wrap(a, 1)

sub_imm_param : I64 -> I64
sub_imm_param = |a| I64.minus_wrap(a, 1)

add_plain : I64, I64 -> I64
add_plain = |a, b| (a + b)

sub_plain : I64, I64 -> I64
sub_plain = |a, b| (a - b)

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([28, 25, 18, 18, 13, 23, 73, 15, 22, 22, 2, 27, 15, 18, 14, 2, 73, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 11, 69, 2], Text.show_int(Wrap64.w64_add(top, 1)))))
	line!(Text.printed(List.concat([28, 25, 18, 18, 13, 23, 73, 19, 25, 32, 2, 27, 15, 18, 14, 2, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 10, 69, 2], Text.show_int(Wrap64.w64_sub(bottom, 1)))))
	line!(Text.printed(List.concat([31, 15, 21, 15, 26, 73, 15, 22, 22, 2, 2, 27, 15, 18, 14, 2, 73, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 11, 69, 2], Text.show_int(add_param(top, 1)))))
	line!(Text.printed(List.concat([31, 15, 21, 15, 26, 73, 19, 25, 32, 2, 2, 27, 15, 18, 14, 2, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 10, 69, 2], Text.show_int(sub_param(bottom, 1)))))
	line!(Text.printed(List.concat([17, 26, 26, 73, 15, 22, 22, 2, 2, 2, 2, 27, 15, 18, 14, 2, 73, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 11, 69, 2], Text.show_int(add_imm_param(top)))))
	line!(Text.printed(List.concat([17, 26, 26, 73, 19, 25, 32, 2, 2, 2, 2, 27, 15, 18, 14, 2, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 10, 69, 2], Text.show_int(sub_imm_param(bottom)))))
	line!(Text.printed(List.concat([17, 18, 73, 32, 15, 18, 22, 2, 2, 2, 2, 27, 15, 18, 14, 2, 12, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 69, 2], Text.show_int(add_plain(4500000000000000000, 4500000000000000000)))))
	line!(Text.printed(List.concat([17, 18, 73, 32, 15, 18, 22, 2, 2, 2, 2, 27, 15, 18, 14, 2, 73, 12, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 69, 2], Text.show_int(sub_plain((0 - 4500000000000000000), 4500000000000000000)))))
	line!(Text.printed(List.concat([19, 26, 15, 23, 23, 2, 2, 2, 2, 2, 2, 27, 15, 18, 14, 2, 7, 5, 69, 2], Text.show_int(add_plain(40, 2)))))
	line!(Text.printed(List.concat([19, 26, 15, 23, 23, 2, 2, 2, 2, 2, 2, 27, 15, 18, 14, 2, 7, 5, 69, 2], Text.show_int(sub_plain(50, 8)))))
	Ok({})
}
