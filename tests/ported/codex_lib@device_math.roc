# lib@device-math
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@device-math.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     sqrt 0.0      ok
#     sqrt 0.25     ok
#     sqrt 1.0      ok
#     sqrt 2.0      ok
#     sqrt 4.0      ok
#     sqrt 16.0     ok
#     sqrt 100.0    ok
#     sqrt 1000.0   ok
#     sqrt 10000.0  ok
#     sqrt 1000000. ok
#     sqrt 1e-6     ok
#     sqrt 1e12     ok
#     sqrt neg      ok
#     sin 0.0       ok
#     sin 0.5       ok
#     sin halfpi    ok
#     sin 2.0       ok
#     sin 3.0       ok
#     sin pi        ok
#     sin 4.0       ok
#     sin threehalf ok
#     sin 6.0       ok
#     sin -1.0      ok
#     sin -3.0      ok
#     sin 100.0     ok
#     cos 0.0       ok
#     cos 1.0       ok
#     cos 2.0       ok
#     cos pi        ok
#     cos 4.0       ok
#     cos -2.0      ok
#     cos 100.0     ok
#     cos 0.0 exact ok
#     sin 0.0 exact ok
#     cos pi/4      ok
#     sin pi/4      ok
#     cos 3.0       ok
#     cos 6.0       ok
#     pyth 0.3      ok
#     pyth 1.7      ok
#     pyth 3.0      ok
#     pyth -2.4     ok
#     abs -3.5      ok
#     abs 3.5       ok
#     min 2.0 3.0   ok
#     max 2.0 3.0   ok
#     abs 0.0       ok
#     abs -0.5      ok
#     min 3.0 2.0   ok
#     min 2.0 2.0   ok
#     min -3.0 2.0  ok
#     min 2.0 -3.0  ok
#     max 3.0 2.0   ok
#     max 2.0 2.0   ok
#     max -3.0 2.0  ok
#     max 2.0 -3.0  ok

app [main!] { cdx: "./codex/main.roc" }

import cdx.DeviceMath
import cdx.Prelude
import cdx.Text

# DeviceMathAccuracy -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

t_abs : F64 -> F64
t_abs = |x| (if (x < 0.0) { (0.0 - x) } else { x })

t_max : F64, F64 -> F64
t_max = |a, b| (if (a > b) { a } else { b })

near : F64, F64, F64 -> List(U8)
near = |got, want, tol| (if (t_abs((got - want)) <= (tol * t_max(1.0, t_abs(want)))) { [16, 34] } else { List.concat(List.concat(List.concat([58, 41, 48, 2, 29, 16, 14, 2], Text.of_str(Prelude.real_to_str(got))), [2, 27, 15, 18, 14, 2]), Text.of_str(Prelude.real_to_str(want))) })

exact : F64, F64 -> List(U8)
exact = |got, want| (if (F64.to_bits(got) == F64.to_bits(want)) { [16, 34] } else { List.concat(List.concat(List.concat([58, 41, 48, 2, 29, 16, 14, 2], Text.of_str(Prelude.real_to_str(got))), [2, 27, 15, 18, 14, 2]), Text.of_str(Prelude.real_to_str(want))) })

sq_tol : F64
sq_tol = F64.from_bits(4472406533629990549)

tr_tol : F64
tr_tol = F64.from_bits(4427486594234968593)

pythagoras : F64 -> List(U8)
pythagoras = |x| ({
	s = DeviceMath.real_sin(x)
	c = DeviceMath.real_cos(x)
	near(((s * s) + (c * c)), 1.0, tr_tol)
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([19, 37, 21, 14, 2, 3, 65, 3, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_sqrt(0.0), 0.0, sq_tol))))
	line!(Text.printed(List.concat([19, 37, 21, 14, 2, 3, 65, 5, 8, 2, 2, 2, 2, 2], near(DeviceMath.real_sqrt(0.25), 0.5, sq_tol))))
	line!(Text.printed(List.concat([19, 37, 21, 14, 2, 4, 65, 3, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_sqrt(1.0), 1.0, sq_tol))))
	line!(Text.printed(List.concat([19, 37, 21, 14, 2, 5, 65, 3, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_sqrt(2.0), 1.414213562373095, sq_tol))))
	line!(Text.printed(List.concat([19, 37, 21, 14, 2, 7, 65, 3, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_sqrt(4.0), 2.0, sq_tol))))
	line!(Text.printed(List.concat([19, 37, 21, 14, 2, 4, 9, 65, 3, 2, 2, 2, 2, 2], near(DeviceMath.real_sqrt(16.0), 4.0, sq_tol))))
	line!(Text.printed(List.concat([19, 37, 21, 14, 2, 4, 3, 3, 65, 3, 2, 2, 2, 2], near(DeviceMath.real_sqrt(100.0), 10.0, sq_tol))))
	line!(Text.printed(List.concat([19, 37, 21, 14, 2, 4, 3, 3, 3, 65, 3, 2, 2, 2], near(DeviceMath.real_sqrt(1000.0), 31.62277660168379, sq_tol))))
	line!(Text.printed(List.concat([19, 37, 21, 14, 2, 4, 3, 3, 3, 3, 65, 3, 2, 2], near(DeviceMath.real_sqrt(10000.0), 100.0, sq_tol))))
	line!(Text.printed(List.concat([19, 37, 21, 14, 2, 4, 3, 3, 3, 3, 3, 3, 65, 2], near(DeviceMath.real_sqrt(1000000.0), 1000.0, sq_tol))))
	line!(Text.printed(List.concat([19, 37, 21, 14, 2, 4, 13, 73, 9, 2, 2, 2, 2, 2], near(DeviceMath.real_sqrt(F64.from_bits(4517329193108106637)), 0.001, sq_tol))))
	line!(Text.printed(List.concat([19, 37, 21, 14, 2, 4, 13, 4, 5, 2, 2, 2, 2, 2], near(DeviceMath.real_sqrt(1000000000000.0), 1000000.0, sq_tol))))
	line!(Text.printed(List.concat([19, 37, 21, 14, 2, 18, 13, 29, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_sqrt((0.0 - 4.0)), 0.0, sq_tol))))
	line!(Text.printed(List.concat([19, 17, 18, 2, 3, 65, 3, 2, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_sin(0.0), 0.0, tr_tol))))
	line!(Text.printed(List.concat([19, 17, 18, 2, 3, 65, 8, 2, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_sin(0.5), 0.479425538604203, tr_tol))))
	line!(Text.printed(List.concat([19, 17, 18, 2, 20, 15, 23, 28, 31, 17, 2, 2, 2, 2], near(DeviceMath.real_sin(1.570796326794897), 1.0, tr_tol))))
	line!(Text.printed(List.concat([19, 17, 18, 2, 5, 65, 3, 2, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_sin(2.0), 0.909297426825682, tr_tol))))
	line!(Text.printed(List.concat([19, 17, 18, 2, 6, 65, 3, 2, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_sin(3.0), 0.141120008059867, tr_tol))))
	line!(Text.printed(List.concat([19, 17, 18, 2, 31, 17, 2, 2, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_sin(3.141592653589793), 0.0, tr_tol))))
	line!(Text.printed(List.concat([19, 17, 18, 2, 7, 65, 3, 2, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_sin(4.0), (0.0 - 0.756802495307928), tr_tol))))
	line!(Text.printed(List.concat([19, 17, 18, 2, 14, 20, 21, 13, 13, 20, 15, 23, 28, 2], near(DeviceMath.real_sin(4.71238898038469), (0.0 - 1.0), tr_tol))))
	line!(Text.printed(List.concat([19, 17, 18, 2, 9, 65, 3, 2, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_sin(6.0), (0.0 - 0.279415498198926), tr_tol))))
	line!(Text.printed(List.concat([19, 17, 18, 2, 73, 4, 65, 3, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_sin((0.0 - 1.0)), (0.0 - 0.841470984807897), tr_tol))))
	line!(Text.printed(List.concat([19, 17, 18, 2, 73, 6, 65, 3, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_sin((0.0 - 3.0)), (0.0 - 0.141120008059867), tr_tol))))
	line!(Text.printed(List.concat([19, 17, 18, 2, 4, 3, 3, 65, 3, 2, 2, 2, 2, 2], near(DeviceMath.real_sin(100.0), (0.0 - 0.506365641109759), tr_tol))))
	line!(Text.printed(List.concat([24, 16, 19, 2, 3, 65, 3, 2, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_cos(0.0), 1.0, tr_tol))))
	line!(Text.printed(List.concat([24, 16, 19, 2, 4, 65, 3, 2, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_cos(1.0), 0.54030230586814, tr_tol))))
	line!(Text.printed(List.concat([24, 16, 19, 2, 5, 65, 3, 2, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_cos(2.0), (0.0 - 0.416146836547142), tr_tol))))
	line!(Text.printed(List.concat([24, 16, 19, 2, 31, 17, 2, 2, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_cos(3.141592653589793), (0.0 - 1.0), tr_tol))))
	line!(Text.printed(List.concat([24, 16, 19, 2, 7, 65, 3, 2, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_cos(4.0), (0.0 - 0.653643620863612), tr_tol))))
	line!(Text.printed(List.concat([24, 16, 19, 2, 73, 5, 65, 3, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_cos((0.0 - 2.0)), (0.0 - 0.416146836547142), tr_tol))))
	line!(Text.printed(List.concat([24, 16, 19, 2, 4, 3, 3, 65, 3, 2, 2, 2, 2, 2], near(DeviceMath.real_cos(100.0), 0.862318872287684, tr_tol))))
	line!(Text.printed(List.concat([24, 16, 19, 2, 3, 65, 3, 2, 13, 36, 15, 24, 14, 2], exact(DeviceMath.real_cos(0.0), 1.0))))
	line!(Text.printed(List.concat([19, 17, 18, 2, 3, 65, 3, 2, 13, 36, 15, 24, 14, 2], exact(DeviceMath.real_sin(0.0), 0.0))))
	line!(Text.printed(List.concat([24, 16, 19, 2, 31, 17, 81, 7, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_cos(0.785398163397448), 0.707106781186548, tr_tol))))
	line!(Text.printed(List.concat([19, 17, 18, 2, 31, 17, 81, 7, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_sin(0.785398163397448), 0.707106781186548, tr_tol))))
	line!(Text.printed(List.concat([24, 16, 19, 2, 6, 65, 3, 2, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_cos(3.0), (0.0 - 0.989992496600445), tr_tol))))
	line!(Text.printed(List.concat([24, 16, 19, 2, 9, 65, 3, 2, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_cos(6.0), 0.960170286650366, tr_tol))))
	line!(Text.printed(List.concat([31, 30, 14, 20, 2, 3, 65, 6, 2, 2, 2, 2, 2, 2], pythagoras(0.3))))
	line!(Text.printed(List.concat([31, 30, 14, 20, 2, 4, 65, 10, 2, 2, 2, 2, 2, 2], pythagoras(1.7))))
	line!(Text.printed(List.concat([31, 30, 14, 20, 2, 6, 65, 3, 2, 2, 2, 2, 2, 2], pythagoras(3.0))))
	line!(Text.printed(List.concat([31, 30, 14, 20, 2, 73, 5, 65, 7, 2, 2, 2, 2, 2], pythagoras((0.0 - 2.4)))))
	line!(Text.printed(List.concat([15, 32, 19, 2, 73, 6, 65, 8, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_abs((0.0 - 3.5)), 3.5, sq_tol))))
	line!(Text.printed(List.concat([15, 32, 19, 2, 6, 65, 8, 2, 2, 2, 2, 2, 2, 2], near(DeviceMath.real_abs(3.5), 3.5, sq_tol))))
	line!(Text.printed(List.concat([26, 17, 18, 2, 5, 65, 3, 2, 6, 65, 3, 2, 2, 2], near(DeviceMath.real_min(2.0, 3.0), 2.0, sq_tol))))
	line!(Text.printed(List.concat([26, 15, 36, 2, 5, 65, 3, 2, 6, 65, 3, 2, 2, 2], near(DeviceMath.real_max(2.0, 3.0), 3.0, sq_tol))))
	line!(Text.printed(List.concat([15, 32, 19, 2, 3, 65, 3, 2, 2, 2, 2, 2, 2, 2], exact(DeviceMath.real_abs(0.0), 0.0))))
	line!(Text.printed(List.concat([15, 32, 19, 2, 73, 3, 65, 8, 2, 2, 2, 2, 2, 2], exact(DeviceMath.real_abs((0.0 - 0.5)), 0.5))))
	line!(Text.printed(List.concat([26, 17, 18, 2, 6, 65, 3, 2, 5, 65, 3, 2, 2, 2], exact(DeviceMath.real_min(3.0, 2.0), 2.0))))
	line!(Text.printed(List.concat([26, 17, 18, 2, 5, 65, 3, 2, 5, 65, 3, 2, 2, 2], exact(DeviceMath.real_min(2.0, 2.0), 2.0))))
	line!(Text.printed(List.concat([26, 17, 18, 2, 73, 6, 65, 3, 2, 5, 65, 3, 2, 2], exact(DeviceMath.real_min((0.0 - 3.0), 2.0), (0.0 - 3.0)))))
	line!(Text.printed(List.concat([26, 17, 18, 2, 5, 65, 3, 2, 73, 6, 65, 3, 2, 2], exact(DeviceMath.real_min(2.0, (0.0 - 3.0)), (0.0 - 3.0)))))
	line!(Text.printed(List.concat([26, 15, 36, 2, 6, 65, 3, 2, 5, 65, 3, 2, 2, 2], exact(DeviceMath.real_max(3.0, 2.0), 3.0))))
	line!(Text.printed(List.concat([26, 15, 36, 2, 5, 65, 3, 2, 5, 65, 3, 2, 2, 2], exact(DeviceMath.real_max(2.0, 2.0), 2.0))))
	line!(Text.printed(List.concat([26, 15, 36, 2, 73, 6, 65, 3, 2, 5, 65, 3, 2, 2], exact(DeviceMath.real_max((0.0 - 3.0), 2.0), 2.0))))
	line!(Text.printed(List.concat([26, 15, 36, 2, 5, 65, 3, 2, 73, 6, 65, 3, 2, 2], exact(DeviceMath.real_max(2.0, (0.0 - 3.0)), 2.0))))
	Ok({})
}
