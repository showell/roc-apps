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

import cdx.CceText

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
	line!(CceText.printed(CceText.concat("literal  want -9223372036854775808: ", CceText.show_int(bottom))))
	line!(CceText.printed(CceText.concat("literal  want -9223372036854775808: ", CceText.show_int((-9223372036854775808)))))
	line!(CceText.printed(CceText.concat("literal  want 9223372036854775807: ", CceText.show_int(plain_sub(top, 0)))))
	line!(CceText.printed(CceText.concat("bare-add want -9223372036854775808: ", CceText.show_int(bump(top, 1)))))
	line!(CceText.printed(CceText.concat("bare-sub want 9223372036854775807: ", CceText.show_int(drop(bottom)))))
	line!(CceText.printed(CceText.concat("bare-mul want -2446744073709551616: ", CceText.show_int(scale(4000000000, 4000000000)))))
	line!(CceText.printed(CceText.concat("small    want 42: ", CceText.show_int(bump(40, 2)))))
	Ok({})
}
