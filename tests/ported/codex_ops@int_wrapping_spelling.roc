# ops@int-wrapping-spelling
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@int-wrapping-spelling.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     literal  want -9223372036854775808: -9223372036854775808
#     literal  want -9223372036854775808: -9223372036854775808
#     literal  want 9223372036854775807: 9223372036854775807
#     bare-add want -9223372036854775808: -9223372036854775808
#     bare-sub want 9223372036854775807: 9223372036854775807
#     bare-mul want -2446744073709551616: -2446744073709551616
#     small    want 42: 42

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# IntWrappingSpelling -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

top : I64
top = 9223372036854775807

bottom : I64
bottom = (-9223372036854775808)

bump : I64, I64 -> I64
bump = |a, b| I64.plus_wrap(a, b)

drop : I64 -> I64
drop = |a| I64.minus_wrap(a, 1)

scale : I64, I64 -> I64
scale = |a, b| I64.times_wrap(a, b)

plain_sub : I64, I64 -> I64
plain_sub = |a, b| (a - b)

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([23, 17, 14, 13, 21, 15, 23, 2, 2, 27, 15, 18, 14, 2, 73, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 11, 69, 2], Text.show_int(bottom))))
	line!(Text.printed(List.concat([23, 17, 14, 13, 21, 15, 23, 2, 2, 27, 15, 18, 14, 2, 73, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 11, 69, 2], Text.show_int((-9223372036854775808)))))
	line!(Text.printed(List.concat([23, 17, 14, 13, 21, 15, 23, 2, 2, 27, 15, 18, 14, 2, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 10, 69, 2], Text.show_int(plain_sub(top, 0)))))
	line!(Text.printed(List.concat([32, 15, 21, 13, 73, 15, 22, 22, 2, 27, 15, 18, 14, 2, 73, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 11, 69, 2], Text.show_int(bump(top, 1)))))
	line!(Text.printed(List.concat([32, 15, 21, 13, 73, 19, 25, 32, 2, 27, 15, 18, 14, 2, 12, 5, 5, 6, 6, 10, 5, 3, 6, 9, 11, 8, 7, 10, 10, 8, 11, 3, 10, 69, 2], Text.show_int(drop(bottom)))))
	line!(Text.printed(List.concat([32, 15, 21, 13, 73, 26, 25, 23, 2, 27, 15, 18, 14, 2, 73, 5, 7, 7, 9, 10, 7, 7, 3, 10, 6, 10, 3, 12, 8, 8, 4, 9, 4, 9, 69, 2], Text.show_int(scale(4000000000, 4000000000)))))
	line!(Text.printed(List.concat([19, 26, 15, 23, 23, 2, 2, 2, 2, 27, 15, 18, 14, 2, 7, 5, 69, 2], Text.show_int(bump(40, 2)))))
	Ok({})
}
