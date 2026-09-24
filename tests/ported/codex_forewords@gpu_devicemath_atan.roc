# forewords@gpu-devicemath-atan
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@gpu-devicemath-atan.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     atan 0.0 = 0  ok
#     atan 0.0001 = 100000  ok
#     atan 0.1 = 99668652  ok
#     atan 0.25 = 244978663  ok
#     atan 0.5 = 463647609  ok
#     atan 0.7071067811865476 = 615479709  ok
#     atan 0.9 = 732815102  ok
#     atan 0.99 = 780373080  ok
#     atan 1.0 = 785398163  ok
#     atan 1.0000001 = 785398213  ok
#     atan 1.1 = 832981267  ok
#     atan 1.5 = 982793723  ok
#     atan 2.0 = 1107148718  ok
#     atan 3.0 = 1249045772  ok
#     atan 10.0 = 1471127674  ok
#     atan 1000000.0 = 1570795327  ok
#     atan -0.5 = -463647609  ok
#     atan -1.0 = -785398163  ok
#     atan -1.5 = -982793723  ok
#     atan -3.0 = -1249045772  ok
#     atan2 1.0, 1.0 = 785398163  ok
#     atan2 1.0, -1.0 = 2356194490  ok
#     atan2 -1.0, 1.0 = -785398163  ok
#     atan2 -1.0, -1.0 = -2356194490  ok
#     atan2 2.0, 0.5 = 1325817664  ok
#     atan2 2.0, -0.5 = 1815774990  ok
#     atan2 -2.0, 0.5 = -1325817664  ok
#     atan2 -2.0, -0.5 = -1815774990  ok
#     atan2 1.0, 0.0 = 1570796327  ok
#     atan2 -1.0, 0.0 = -1570796327  ok
#     atan2 0.0, -1.0 = 3141592654  ok
#     atan2 0.0, 0.0 = 0  ok
#     atan2 3.0, 4.0 = 643501109  ok
#     atan2 -4.0, 3.0 = -927295218  ok
#     round trip through real-sin and real-cos, within 50 nano: 8 of 8

app [main!] { cdx: "./codex/main.roc" }

import cdx.DeviceMath
import cdx.Text

# FwdDeviceMathAtanTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

nano : F64 -> I64
nano = |v| F64.to_i64_wrap(((v * 1000000000.0) + (if (v < 0.0) { (0.0 - 0.5) } else { 0.5 })))

agree : I64, I64 -> Text
agree = |got, want| (if (got == want) { "ok" } else { Text.concat("MISMATCH want ", Text.show_int(want)) })

a : Text, F64, I64 -> Text
a = |name, t, want| ({
	got = nano(DeviceMath.real_atan(t))
	Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("atan ", name), " = "), Text.show_int(got)), "  "), agree(got, want))
})

a2 : Text, F64, F64, I64 -> Text
a2 = |name, y, x, want| ({
	got = nano(DeviceMath.real_atan2(y, x))
	Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("atan2 ", name), " = "), Text.show_int(got)), "  "), agree(got, want))
})

rt_abs : I64 -> I64
rt_abs = |e| (if (e < 0) { (0 - e) } else { e })

rt_ok : F64 -> I64
rt_ok = |t| ({
	ang = DeviceMath.real_atan(t)
	back = (DeviceMath.real_sin(ang) / DeviceMath.real_cos(ang))
	(if (rt_abs(nano((back - t))) <= 50) { 1 } else { 0 })
})

rt_report : Text
rt_report = ({
	n = (((((((rt_ok(0.1) + rt_ok(0.25)) + rt_ok(0.5)) + rt_ok(1.0)) + rt_ok(1.5)) + rt_ok(3.0)) + rt_ok((0.0 - 0.5))) + rt_ok((0.0 - 1.5)))
	Text.concat(Text.concat("round trip through real-sin and real-cos, within 50 nano: ", Text.show_int(n)), " of 8")
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(a("0.0", 0.0, 0)))
	line!(Text.printed(a("0.0001", 0.0001, 100000)))
	line!(Text.printed(a("0.1", 0.1, 99668652)))
	line!(Text.printed(a("0.25", 0.25, 244978663)))
	line!(Text.printed(a("0.5", 0.5, 463647609)))
	line!(Text.printed(a("0.7071067811865476", 0.7071067811865476, 615479709)))
	line!(Text.printed(a("0.9", 0.9, 732815102)))
	line!(Text.printed(a("0.99", 0.99, 780373080)))
	line!(Text.printed(a("1.0", 1.0, 785398163)))
	line!(Text.printed(a("1.0000001", 1.0000001, 785398213)))
	line!(Text.printed(a("1.1", 1.1, 832981267)))
	line!(Text.printed(a("1.5", 1.5, 982793723)))
	line!(Text.printed(a("2.0", 2.0, 1107148718)))
	line!(Text.printed(a("3.0", 3.0, 1249045772)))
	line!(Text.printed(a("10.0", 10.0, 1471127674)))
	line!(Text.printed(a("1000000.0", 1000000.0, 1570795327)))
	line!(Text.printed(a("-0.5", (-0.5), (-463647609))))
	line!(Text.printed(a("-1.0", (-1.0), (-785398163))))
	line!(Text.printed(a("-1.5", (-1.5), (-982793723))))
	line!(Text.printed(a("-3.0", (-3.0), (-1249045772))))
	line!(Text.printed(a2("1.0, 1.0", 1.0, 1.0, 785398163)))
	line!(Text.printed(a2("1.0, -1.0", 1.0, (-1.0), 2356194490)))
	line!(Text.printed(a2("-1.0, 1.0", (-1.0), 1.0, (-785398163))))
	line!(Text.printed(a2("-1.0, -1.0", (-1.0), (-1.0), (-2356194490))))
	line!(Text.printed(a2("2.0, 0.5", 2.0, 0.5, 1325817664)))
	line!(Text.printed(a2("2.0, -0.5", 2.0, (-0.5), 1815774990)))
	line!(Text.printed(a2("-2.0, 0.5", (-2.0), 0.5, (-1325817664))))
	line!(Text.printed(a2("-2.0, -0.5", (-2.0), (-0.5), (-1815774990))))
	line!(Text.printed(a2("1.0, 0.0", 1.0, 0.0, 1570796327)))
	line!(Text.printed(a2("-1.0, 0.0", (-1.0), 0.0, (-1570796327))))
	line!(Text.printed(a2("0.0, -1.0", 0.0, (-1.0), 3141592654)))
	line!(Text.printed(a2("0.0, 0.0", 0.0, 0.0, 0)))
	line!(Text.printed(a2("3.0, 4.0", 3.0, 4.0, 643501109)))
	line!(Text.printed(a2("-4.0, 3.0", (-4.0), 3.0, (-927295218))))
	line!(Text.printed(rt_report))
	Ok({})
}
