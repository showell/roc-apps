# ops@int-rem
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@int-rem.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     7 rem 3 = 1
#     -7 rem 3 = -1
#     7 rem -3 = 1
#     -7 rem -3 = -1
#     7 mod 3 = 1
#     -7 mod 3 = 2
#     7 mod -3 = 1
#     -7 mod -3 = 2
#     -1 rem 8 = -1
#     -8 rem 8 = 0
#     -9 rem 8 = -1
#     -1 mod 8 = 7
#     0 rem 5 = 0
#     computed -7 rem 3 = -1
#     computed 7 rem -3 = 1
#     identity -7 3 = yes
#     identity 7 -3 = yes
#     identity -7 -3 = yes
#     identity -1 8 = yes
#     identity 13 4 = yes
#     identities held = 5

app [main!] { cdx: "./codex/main.roc" }

import cdx.Prelude
import cdx.Text

# IntRem -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

rem : I64, I64 -> I64
rem = |a, b| I64.rem_by(a, b)

eucl : I64, I64 -> I64
eucl = |a, b| Prelude.int_mod(a, b)

rem_computed : I64, I64 -> I64
rem_computed = |a, b| I64.rem_by((a + 0), (b + 0))

ident_ok : I64, I64 -> Bool
ident_ok = |a, b| (a == ((I64.div_trunc_by(a, b) * b) + I64.rem_by(a, b)))

ident_count : I64, I64, I64 -> I64
ident_count = |acc, a, b| (if ident_ok(a, b) { (acc + 1) } else { acc })

yn : Bool -> List(U8)
yn = |b| (if b { [30, 13, 19] } else { [18, 16] })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([10, 2, 21, 13, 26, 2, 6, 2, 77, 2], Text.show_int(rem(7, 3)))))
	line!(Text.printed(List.concat([73, 10, 2, 21, 13, 26, 2, 6, 2, 77, 2], Text.show_int(rem((0 - 7), 3)))))
	line!(Text.printed(List.concat([10, 2, 21, 13, 26, 2, 73, 6, 2, 77, 2], Text.show_int(rem(7, (0 - 3))))))
	line!(Text.printed(List.concat([73, 10, 2, 21, 13, 26, 2, 73, 6, 2, 77, 2], Text.show_int(rem((0 - 7), (0 - 3))))))
	line!(Text.printed(List.concat([10, 2, 26, 16, 22, 2, 6, 2, 77, 2], Text.show_int(eucl(7, 3)))))
	line!(Text.printed(List.concat([73, 10, 2, 26, 16, 22, 2, 6, 2, 77, 2], Text.show_int(eucl((0 - 7), 3)))))
	line!(Text.printed(List.concat([10, 2, 26, 16, 22, 2, 73, 6, 2, 77, 2], Text.show_int(eucl(7, (0 - 3))))))
	line!(Text.printed(List.concat([73, 10, 2, 26, 16, 22, 2, 73, 6, 2, 77, 2], Text.show_int(eucl((0 - 7), (0 - 3))))))
	line!(Text.printed(List.concat([73, 4, 2, 21, 13, 26, 2, 11, 2, 77, 2], Text.show_int(rem((0 - 1), 8)))))
	line!(Text.printed(List.concat([73, 11, 2, 21, 13, 26, 2, 11, 2, 77, 2], Text.show_int(rem((0 - 8), 8)))))
	line!(Text.printed(List.concat([73, 12, 2, 21, 13, 26, 2, 11, 2, 77, 2], Text.show_int(rem((0 - 9), 8)))))
	line!(Text.printed(List.concat([73, 4, 2, 26, 16, 22, 2, 11, 2, 77, 2], Text.show_int(eucl((0 - 1), 8)))))
	line!(Text.printed(List.concat([3, 2, 21, 13, 26, 2, 8, 2, 77, 2], Text.show_int(rem(0, 5)))))
	line!(Text.printed(List.concat([24, 16, 26, 31, 25, 14, 13, 22, 2, 73, 10, 2, 21, 13, 26, 2, 6, 2, 77, 2], Text.show_int(rem_computed((0 - 7), 3)))))
	line!(Text.printed(List.concat([24, 16, 26, 31, 25, 14, 13, 22, 2, 10, 2, 21, 13, 26, 2, 73, 6, 2, 77, 2], Text.show_int(rem_computed(7, (0 - 3))))))
	line!(Text.printed(List.concat([17, 22, 13, 18, 14, 17, 14, 30, 2, 73, 10, 2, 6, 2, 77, 2], yn(ident_ok((0 - 7), 3)))))
	line!(Text.printed(List.concat([17, 22, 13, 18, 14, 17, 14, 30, 2, 10, 2, 73, 6, 2, 77, 2], yn(ident_ok(7, (0 - 3))))))
	line!(Text.printed(List.concat([17, 22, 13, 18, 14, 17, 14, 30, 2, 73, 10, 2, 73, 6, 2, 77, 2], yn(ident_ok((0 - 7), (0 - 3))))))
	line!(Text.printed(List.concat([17, 22, 13, 18, 14, 17, 14, 30, 2, 73, 4, 2, 11, 2, 77, 2], yn(ident_ok((0 - 1), 8)))))
	line!(Text.printed(List.concat([17, 22, 13, 18, 14, 17, 14, 30, 2, 4, 6, 2, 7, 2, 77, 2], yn(ident_ok(13, 4)))))
	line!(Text.printed(List.concat([17, 22, 13, 18, 14, 17, 14, 17, 13, 19, 2, 20, 13, 23, 22, 2, 77, 2], Text.show_int(ident_count(ident_count(ident_count(ident_count(ident_count(0, (0 - 7), 3), 7, (0 - 3)), (0 - 7), (0 - 3)), (0 - 1), 8), 13, 4)))))
	Ok({})
}
