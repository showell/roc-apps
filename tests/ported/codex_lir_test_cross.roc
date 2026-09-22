# lir-test-cross
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lir-test-cross.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     1
#     0
#     1
#     0
#     1
#     0
#     100
#     200
#     1
#     0
#     1
#     0
#     1
#     0
#     1

app [main!] { cdx: "./codex/main.roc" }

import cdx.MathLib
import cdx.Text

# LirTestCross -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

lt_even : I64 -> I64
lt_even = |n| (if (MathLib.math_mod(n, 2) == 0) { 1 } else { 0 })

lt_odd : I64 -> I64
lt_odd = |n| (if (MathLib.math_mod(n, 2) != 0) { 1 } else { 0 })

lt_mod4 : I64 -> I64
lt_mod4 = |n| (if (MathLib.math_mod(n, 4) == 0) { 1 } else { 0 })

lt_mod8 : I64 -> I64
lt_mod8 = |n| (if (MathLib.math_mod(n, 8) == 0) { 100 } else { 200 })

lt_mod3 : I64 -> I64
lt_mod3 = |n| (if (MathLib.math_mod(n, 3) == 0) { 1 } else { 0 })

lt_modone : I64 -> I64
lt_modone = |n| (if (MathLib.math_mod(n, 2) == 1) { 1 } else { 0 })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.show_int(lt_even(4))))
	line!(Text.printed(Text.show_int(lt_even(7))))
	line!(Text.printed(Text.show_int(lt_odd(7))))
	line!(Text.printed(Text.show_int(lt_odd(4))))
	line!(Text.printed(Text.show_int(lt_mod4(8))))
	line!(Text.printed(Text.show_int(lt_mod4(6))))
	line!(Text.printed(Text.show_int(lt_mod8(16))))
	line!(Text.printed(Text.show_int(lt_mod8(12))))
	line!(Text.printed(Text.show_int(lt_mod3(6))))
	line!(Text.printed(Text.show_int(lt_mod3(7))))
	line!(Text.printed(Text.show_int(lt_modone(7))))
	line!(Text.printed(Text.show_int(lt_modone(4))))
	line!(Text.printed(Text.show_int(lt_even((-4)))))
	line!(Text.printed(Text.show_int(lt_even((-5)))))
	line!(Text.printed(Text.show_int(lt_odd((-5)))))
	Ok({})
}
