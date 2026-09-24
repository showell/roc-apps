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

import cdx.CceText
import cdx.DeviceMath
import cdx.Prelude

# DeviceMathAccuracy -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

t_abs : F64 -> F64
t_abs = |x| (if (x < 0.0) { (0.0 - x) } else { x })

t_max : F64, F64 -> F64
t_max = |a, b| (if (a > b) { a } else { b })

near : F64, F64, F64 -> CceText
near = |got, want, tol| (if (t_abs((got - want)) <= (tol * t_max(1.0, t_abs(want)))) { "ok" } else { CceText.concat(CceText.concat(CceText.concat("BAD got ", CceText.of_str(Prelude.real_to_str(got))), " want "), CceText.of_str(Prelude.real_to_str(want))) })

exact : F64, F64 -> CceText
exact = |got, want| (if (F64.to_bits(got) == F64.to_bits(want)) { "ok" } else { CceText.concat(CceText.concat(CceText.concat("BAD got ", CceText.of_str(Prelude.real_to_str(got))), " want "), CceText.of_str(Prelude.real_to_str(want))) })

sq_tol : F64
sq_tol = F64.from_bits(4472406533629990549)

tr_tol : F64
tr_tol = F64.from_bits(4427486594234968593)

pythagoras : F64 -> CceText
pythagoras = |x| ({
	s = DeviceMath.real_sin(x)
	c = DeviceMath.real_cos(x)
	near(((s * s) + (c * c)), 1.0, tr_tol)
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("sqrt 0.0      ", near(DeviceMath.real_sqrt(0.0), 0.0, sq_tol))))
	line!(CceText.printed(CceText.concat("sqrt 0.25     ", near(DeviceMath.real_sqrt(0.25), 0.5, sq_tol))))
	line!(CceText.printed(CceText.concat("sqrt 1.0      ", near(DeviceMath.real_sqrt(1.0), 1.0, sq_tol))))
	line!(CceText.printed(CceText.concat("sqrt 2.0      ", near(DeviceMath.real_sqrt(2.0), 1.414213562373095, sq_tol))))
	line!(CceText.printed(CceText.concat("sqrt 4.0      ", near(DeviceMath.real_sqrt(4.0), 2.0, sq_tol))))
	line!(CceText.printed(CceText.concat("sqrt 16.0     ", near(DeviceMath.real_sqrt(16.0), 4.0, sq_tol))))
	line!(CceText.printed(CceText.concat("sqrt 100.0    ", near(DeviceMath.real_sqrt(100.0), 10.0, sq_tol))))
	line!(CceText.printed(CceText.concat("sqrt 1000.0   ", near(DeviceMath.real_sqrt(1000.0), 31.62277660168379, sq_tol))))
	line!(CceText.printed(CceText.concat("sqrt 10000.0  ", near(DeviceMath.real_sqrt(10000.0), 100.0, sq_tol))))
	line!(CceText.printed(CceText.concat("sqrt 1000000. ", near(DeviceMath.real_sqrt(1000000.0), 1000.0, sq_tol))))
	line!(CceText.printed(CceText.concat("sqrt 1e-6     ", near(DeviceMath.real_sqrt(F64.from_bits(4517329193108106637)), 0.001, sq_tol))))
	line!(CceText.printed(CceText.concat("sqrt 1e12     ", near(DeviceMath.real_sqrt(1000000000000.0), 1000000.0, sq_tol))))
	line!(CceText.printed(CceText.concat("sqrt neg      ", near(DeviceMath.real_sqrt((0.0 - 4.0)), 0.0, sq_tol))))
	line!(CceText.printed(CceText.concat("sin 0.0       ", near(DeviceMath.real_sin(0.0), 0.0, tr_tol))))
	line!(CceText.printed(CceText.concat("sin 0.5       ", near(DeviceMath.real_sin(0.5), 0.479425538604203, tr_tol))))
	line!(CceText.printed(CceText.concat("sin halfpi    ", near(DeviceMath.real_sin(1.570796326794897), 1.0, tr_tol))))
	line!(CceText.printed(CceText.concat("sin 2.0       ", near(DeviceMath.real_sin(2.0), 0.909297426825682, tr_tol))))
	line!(CceText.printed(CceText.concat("sin 3.0       ", near(DeviceMath.real_sin(3.0), 0.141120008059867, tr_tol))))
	line!(CceText.printed(CceText.concat("sin pi        ", near(DeviceMath.real_sin(3.141592653589793), 0.0, tr_tol))))
	line!(CceText.printed(CceText.concat("sin 4.0       ", near(DeviceMath.real_sin(4.0), (0.0 - 0.756802495307928), tr_tol))))
	line!(CceText.printed(CceText.concat("sin threehalf ", near(DeviceMath.real_sin(4.71238898038469), (0.0 - 1.0), tr_tol))))
	line!(CceText.printed(CceText.concat("sin 6.0       ", near(DeviceMath.real_sin(6.0), (0.0 - 0.279415498198926), tr_tol))))
	line!(CceText.printed(CceText.concat("sin -1.0      ", near(DeviceMath.real_sin((0.0 - 1.0)), (0.0 - 0.841470984807897), tr_tol))))
	line!(CceText.printed(CceText.concat("sin -3.0      ", near(DeviceMath.real_sin((0.0 - 3.0)), (0.0 - 0.141120008059867), tr_tol))))
	line!(CceText.printed(CceText.concat("sin 100.0     ", near(DeviceMath.real_sin(100.0), (0.0 - 0.506365641109759), tr_tol))))
	line!(CceText.printed(CceText.concat("cos 0.0       ", near(DeviceMath.real_cos(0.0), 1.0, tr_tol))))
	line!(CceText.printed(CceText.concat("cos 1.0       ", near(DeviceMath.real_cos(1.0), 0.54030230586814, tr_tol))))
	line!(CceText.printed(CceText.concat("cos 2.0       ", near(DeviceMath.real_cos(2.0), (0.0 - 0.416146836547142), tr_tol))))
	line!(CceText.printed(CceText.concat("cos pi        ", near(DeviceMath.real_cos(3.141592653589793), (0.0 - 1.0), tr_tol))))
	line!(CceText.printed(CceText.concat("cos 4.0       ", near(DeviceMath.real_cos(4.0), (0.0 - 0.653643620863612), tr_tol))))
	line!(CceText.printed(CceText.concat("cos -2.0      ", near(DeviceMath.real_cos((0.0 - 2.0)), (0.0 - 0.416146836547142), tr_tol))))
	line!(CceText.printed(CceText.concat("cos 100.0     ", near(DeviceMath.real_cos(100.0), 0.862318872287684, tr_tol))))
	line!(CceText.printed(CceText.concat("cos 0.0 exact ", exact(DeviceMath.real_cos(0.0), 1.0))))
	line!(CceText.printed(CceText.concat("sin 0.0 exact ", exact(DeviceMath.real_sin(0.0), 0.0))))
	line!(CceText.printed(CceText.concat("cos pi/4      ", near(DeviceMath.real_cos(0.785398163397448), 0.707106781186548, tr_tol))))
	line!(CceText.printed(CceText.concat("sin pi/4      ", near(DeviceMath.real_sin(0.785398163397448), 0.707106781186548, tr_tol))))
	line!(CceText.printed(CceText.concat("cos 3.0       ", near(DeviceMath.real_cos(3.0), (0.0 - 0.989992496600445), tr_tol))))
	line!(CceText.printed(CceText.concat("cos 6.0       ", near(DeviceMath.real_cos(6.0), 0.960170286650366, tr_tol))))
	line!(CceText.printed(CceText.concat("pyth 0.3      ", pythagoras(0.3))))
	line!(CceText.printed(CceText.concat("pyth 1.7      ", pythagoras(1.7))))
	line!(CceText.printed(CceText.concat("pyth 3.0      ", pythagoras(3.0))))
	line!(CceText.printed(CceText.concat("pyth -2.4     ", pythagoras((0.0 - 2.4)))))
	line!(CceText.printed(CceText.concat("abs -3.5      ", near(DeviceMath.real_abs((0.0 - 3.5)), 3.5, sq_tol))))
	line!(CceText.printed(CceText.concat("abs 3.5       ", near(DeviceMath.real_abs(3.5), 3.5, sq_tol))))
	line!(CceText.printed(CceText.concat("min 2.0 3.0   ", near(DeviceMath.real_min(2.0, 3.0), 2.0, sq_tol))))
	line!(CceText.printed(CceText.concat("max 2.0 3.0   ", near(DeviceMath.real_max(2.0, 3.0), 3.0, sq_tol))))
	line!(CceText.printed(CceText.concat("abs 0.0       ", exact(DeviceMath.real_abs(0.0), 0.0))))
	line!(CceText.printed(CceText.concat("abs -0.5      ", exact(DeviceMath.real_abs((0.0 - 0.5)), 0.5))))
	line!(CceText.printed(CceText.concat("min 3.0 2.0   ", exact(DeviceMath.real_min(3.0, 2.0), 2.0))))
	line!(CceText.printed(CceText.concat("min 2.0 2.0   ", exact(DeviceMath.real_min(2.0, 2.0), 2.0))))
	line!(CceText.printed(CceText.concat("min -3.0 2.0  ", exact(DeviceMath.real_min((0.0 - 3.0), 2.0), (0.0 - 3.0)))))
	line!(CceText.printed(CceText.concat("min 2.0 -3.0  ", exact(DeviceMath.real_min(2.0, (0.0 - 3.0)), (0.0 - 3.0)))))
	line!(CceText.printed(CceText.concat("max 3.0 2.0   ", exact(DeviceMath.real_max(3.0, 2.0), 3.0))))
	line!(CceText.printed(CceText.concat("max 2.0 2.0   ", exact(DeviceMath.real_max(2.0, 2.0), 2.0))))
	line!(CceText.printed(CceText.concat("max -3.0 2.0  ", exact(DeviceMath.real_max((0.0 - 3.0), 2.0), 2.0))))
	line!(CceText.printed(CceText.concat("max 2.0 -3.0  ", exact(DeviceMath.real_max(2.0, (0.0 - 3.0)), 2.0))))
	Ok({})
}
