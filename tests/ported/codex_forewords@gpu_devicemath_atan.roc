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

agree : I64, I64 -> List(U8)
agree = |got, want| (if (got == want) { [16, 34] } else { List.concat([52, 43, 45, 52, 41, 40, 50, 46, 2, 27, 15, 18, 14, 2], Text.show_int(want)) })

a : List(U8), F64, I64 -> List(U8)
a = |name, t, want| ({
	got = nano(DeviceMath.real_atan(t))
	List.concat(List.concat(List.concat(List.concat(List.concat([15, 14, 15, 18, 2], name), [2, 77, 2]), Text.show_int(got)), [2, 2]), agree(got, want))
})

a2 : List(U8), F64, F64, I64 -> List(U8)
a2 = |name, y, x, want| ({
	got = nano(DeviceMath.real_atan2(y, x))
	List.concat(List.concat(List.concat(List.concat(List.concat([15, 14, 15, 18, 5, 2], name), [2, 77, 2]), Text.show_int(got)), [2, 2]), agree(got, want))
})

rt_abs : I64 -> I64
rt_abs = |e| (if (e < 0) { (0 - e) } else { e })

rt_ok : F64 -> I64
rt_ok = |t| ({
	ang = DeviceMath.real_atan(t)
	back = (DeviceMath.real_sin(ang) / DeviceMath.real_cos(ang))
	(if (rt_abs(nano((back - t))) <= 50) { 1 } else { 0 })
})

rt_report : List(U8)
rt_report = ({
	n = (((((((rt_ok(0.1) + rt_ok(0.25)) + rt_ok(0.5)) + rt_ok(1.0)) + rt_ok(1.5)) + rt_ok(3.0)) + rt_ok((0.0 - 0.5))) + rt_ok((0.0 - 1.5)))
	List.concat(List.concat([21, 16, 25, 18, 22, 2, 14, 21, 17, 31, 2, 14, 20, 21, 16, 25, 29, 20, 2, 21, 13, 15, 23, 73, 19, 17, 18, 2, 15, 18, 22, 2, 21, 13, 15, 23, 73, 24, 16, 19, 66, 2, 27, 17, 14, 20, 17, 18, 2, 8, 3, 2, 18, 15, 18, 16, 69, 2], Text.show_int(n)), [2, 16, 28, 2, 11])
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(a([3, 65, 3], 0.0, 0)))
	line!(Text.printed(a([3, 65, 3, 3, 3, 4], 0.0001, 100000)))
	line!(Text.printed(a([3, 65, 4], 0.1, 99668652)))
	line!(Text.printed(a([3, 65, 5, 8], 0.25, 244978663)))
	line!(Text.printed(a([3, 65, 8], 0.5, 463647609)))
	line!(Text.printed(a([3, 65, 10, 3, 10, 4, 3, 9, 10, 11, 4, 4, 11, 9, 8, 7, 10, 9], 0.7071067811865476, 615479709)))
	line!(Text.printed(a([3, 65, 12], 0.9, 732815102)))
	line!(Text.printed(a([3, 65, 12, 12], 0.99, 780373080)))
	line!(Text.printed(a([4, 65, 3], 1.0, 785398163)))
	line!(Text.printed(a([4, 65, 3, 3, 3, 3, 3, 3, 4], 1.0000001, 785398213)))
	line!(Text.printed(a([4, 65, 4], 1.1, 832981267)))
	line!(Text.printed(a([4, 65, 8], 1.5, 982793723)))
	line!(Text.printed(a([5, 65, 3], 2.0, 1107148718)))
	line!(Text.printed(a([6, 65, 3], 3.0, 1249045772)))
	line!(Text.printed(a([4, 3, 65, 3], 10.0, 1471127674)))
	line!(Text.printed(a([4, 3, 3, 3, 3, 3, 3, 65, 3], 1000000.0, 1570795327)))
	line!(Text.printed(a([73, 3, 65, 8], (-0.5), (-463647609))))
	line!(Text.printed(a([73, 4, 65, 3], (-1.0), (-785398163))))
	line!(Text.printed(a([73, 4, 65, 8], (-1.5), (-982793723))))
	line!(Text.printed(a([73, 6, 65, 3], (-3.0), (-1249045772))))
	line!(Text.printed(a2([4, 65, 3, 66, 2, 4, 65, 3], 1.0, 1.0, 785398163)))
	line!(Text.printed(a2([4, 65, 3, 66, 2, 73, 4, 65, 3], 1.0, (-1.0), 2356194490)))
	line!(Text.printed(a2([73, 4, 65, 3, 66, 2, 4, 65, 3], (-1.0), 1.0, (-785398163))))
	line!(Text.printed(a2([73, 4, 65, 3, 66, 2, 73, 4, 65, 3], (-1.0), (-1.0), (-2356194490))))
	line!(Text.printed(a2([5, 65, 3, 66, 2, 3, 65, 8], 2.0, 0.5, 1325817664)))
	line!(Text.printed(a2([5, 65, 3, 66, 2, 73, 3, 65, 8], 2.0, (-0.5), 1815774990)))
	line!(Text.printed(a2([73, 5, 65, 3, 66, 2, 3, 65, 8], (-2.0), 0.5, (-1325817664))))
	line!(Text.printed(a2([73, 5, 65, 3, 66, 2, 73, 3, 65, 8], (-2.0), (-0.5), (-1815774990))))
	line!(Text.printed(a2([4, 65, 3, 66, 2, 3, 65, 3], 1.0, 0.0, 1570796327)))
	line!(Text.printed(a2([73, 4, 65, 3, 66, 2, 3, 65, 3], (-1.0), 0.0, (-1570796327))))
	line!(Text.printed(a2([3, 65, 3, 66, 2, 73, 4, 65, 3], 0.0, (-1.0), 3141592654)))
	line!(Text.printed(a2([3, 65, 3, 66, 2, 3, 65, 3], 0.0, 0.0, 0)))
	line!(Text.printed(a2([6, 65, 3, 66, 2, 7, 65, 3], 3.0, 4.0, 643501109)))
	line!(Text.printed(a2([73, 7, 65, 3, 66, 2, 6, 65, 3], (-4.0), 3.0, (-927295218))))
	line!(Text.printed(rt_report))
	Ok({})
}
