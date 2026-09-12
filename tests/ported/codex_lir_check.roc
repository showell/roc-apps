# lir-check
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lir-check.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     7
#     13
#     16
#     15
#     1
#     14
#     2
#     10
#     200
#     8
#     5
#     42
#     0
#     1
#     0
#     1
#     0
#     1
#     1
#     1
#     0
#     1
#     0
#     1
#     0
#     120
#     240
#     6
#     6

app [main!] { cdx: "./codex/main.roc" }

import cdx.MathLib

# LirCheck -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Sw : [SwA(I64), SwB]

sl_add : I64, I64 -> I64
sl_add = |x, y| (x + y)

sl_mix : I64 -> I64
sl_mix = |x| ({
	a = (x * 2)
	(a + 3)
})

sl_nest : I64, I64 -> I64
sl_nest = |x, y| ((x + y) * (x - y))

sl_wide : I64, I64, I64, I64, I64 -> I64
sl_wide = |a, b, c, d, e| ((((a + b) + c) + d) + e)

if_min : I64 -> I64
if_min = |n| (if (n > 0) { 1 } else { 0 })

if_operand : I64 -> I64
if_operand = |n| ((if (n > 0) { 10 } else { 20 }) + n)

if_nest : I64 -> I64
if_nest = |n| (if (n > 0) { (if (n > 5) { 2 } else { 1 }) } else { 0 })

sw_min : I64 -> I64
sw_min = |n| (match n {
	0 => 10
	_ => 20
})

sw_three : I64 -> I64
sw_three = |n| (match n {
	0 => 100
	1 => 200
	_ => 300
})

sw_var : I64 -> I64
sw_var = |n| (match n {
	0 => 0
	x => (x + 1)
})

sw_or : I64 -> I64
sw_or = |n| (match n {
	0 => 5
	1 => 5
	_ => 9
})

sw_ctor : Sw -> I64
sw_ctor = |s| (match s {
	SwA(x) => x
	SwB => 0
})

nl_call : I64 -> I64
nl_call = |n| sl_add(n, n)

pmv_clash : I64, I64, I64, I64, I64 -> I64
pmv_clash = |a, b, c, d, e| (if (d == a) { ({
	raw = I64.div_trunc_by(((b - c) * 60), e)
	(if (raw < 0) { (raw + 360) } else { raw })
}) } else { (if (d == b) { (I64.div_trunc_by(((c - a) * 60), e) + 120) } else { (I64.div_trunc_by(((a - b) * 60), e) + 240) }) })

coal_result : I64, I64 -> I64
coal_result = |a, b| ({
	s = (a + 1)
	_y = (if (b > 0) { s } else { I64.div_trunc_by(100, b) })
	s
})

if_even : I64 -> I64
if_even = |n| (if (MathLib.math_mod(n, 2) == 0) { 1 } else { 0 })

if_odd : I64 -> I64
if_odd = |n| (if (MathLib.math_mod(n, 2) != 0) { 1 } else { 0 })

if_mod4 : I64 -> I64
if_mod4 = |n| (if (MathLib.math_mod(n, 4) == 0) { 1 } else { 0 })

if_mod3 : I64 -> I64
if_mod3 = |n| (if (MathLib.math_mod(n, 3) == 0) { 1 } else { 0 })

if_mod_one : I64 -> I64
if_mod_one = |n| (if (MathLib.math_mod(n, 2) == 1) { 1 } else { 0 })

eq_sw : Sw, Sw -> Bool
eq_sw = |ex, ey| (match ex {
	SwA(exf0) => (match ey {
		SwA(eyf0) => (exf0 == eyf0)
		_ => False
	})
	SwB => (match ey {
		SwB => True
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(I64.to_str(sl_add(3, 4)))
	line!(I64.to_str(sl_mix(5)))
	line!(I64.to_str(sl_nest(5, 3)))
	line!(I64.to_str(sl_wide(1, 2, 3, 4, 5)))
	line!(I64.to_str(if_min(4)))
	line!(I64.to_str(if_operand(4)))
	line!(I64.to_str(if_nest(8)))
	line!(I64.to_str(sw_min(0)))
	line!(I64.to_str(sw_three(1)))
	line!(I64.to_str(sw_var(7)))
	line!(I64.to_str(sw_or(1)))
	line!(I64.to_str(sw_ctor(SwA(42))))
	line!(I64.to_str(sw_ctor(SwB)))
	line!(I64.to_str(if_even(4)))
	line!(I64.to_str(if_even(7)))
	line!(I64.to_str(if_even((-4))))
	line!(I64.to_str(if_even((-5))))
	line!(I64.to_str(if_odd(7)))
	line!(I64.to_str(if_odd((-5))))
	line!(I64.to_str(if_mod4(8)))
	line!(I64.to_str(if_mod4(6)))
	line!(I64.to_str(if_mod3(6)))
	line!(I64.to_str(if_mod3(7)))
	line!(I64.to_str(if_mod_one(7)))
	line!(I64.to_str(pmv_clash(255, 0, 0, 255, 255)))
	line!(I64.to_str(pmv_clash(0, 255, 0, 255, 255)))
	line!(I64.to_str(pmv_clash(0, 0, 255, 255, 255)))
	line!(I64.to_str(coal_result(5, (-2))))
	line!(I64.to_str(coal_result(5, 3)))
	Ok({})
}
