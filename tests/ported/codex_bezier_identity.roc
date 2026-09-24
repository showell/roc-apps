# bezier-identity
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/bezier-identity.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     cubic-t0=100,200,300
#     cubic-t1000=1000,1100,1200
#     cubic-mid=550,650,750
#     quad-t0=100,200,300
#     quad-t1000=700,800,900
#     quad-mid=400,500,600
#     degen-cubic-250=100,200,300
#     degen-cubic-500=100,200,300
#     degen-cubic-750=100,200,300
#     degen-quad-500=100,200,300
#     math-isqrt=0 12 1000

app [main!] { cdx: "./codex/main.roc" }

import cdx.Bezier
import cdx.CceText
import cdx.MathLib

# BezierIdentity -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

pa : Bezier.BezVec
pa = Bezier.BezVec.{ vx: 100, vy: 200, vz: 300 }

pb : Bezier.BezVec
pb = Bezier.BezVec.{ vx: 400, vy: 500, vz: 600 }

pc : Bezier.BezVec
pc = Bezier.BezVec.{ vx: 700, vy: 800, vz: 900 }

pd : Bezier.BezVec
pd = Bezier.BezVec.{ vx: 1000, vy: 1100, vz: 1200 }

fmt : Bezier.BezVec -> CceText
fmt = |p| CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.show_int(p.vx), ","), CceText.show_int(p.vy)), ","), CceText.show_int(p.vz))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("cubic-t0=", fmt(Bezier.bezier3_eval(pa, pb, pc, pd, 0)))))
	line!(CceText.printed(CceText.concat("cubic-t1000=", fmt(Bezier.bezier3_eval(pa, pb, pc, pd, 1000)))))
	line!(CceText.printed(CceText.concat("cubic-mid=", fmt(Bezier.bezier3_eval(pa, pb, pc, pd, 500)))))
	line!(CceText.printed(CceText.concat("quad-t0=", fmt(Bezier.bezier2_eval(pa, pb, pc, 0)))))
	line!(CceText.printed(CceText.concat("quad-t1000=", fmt(Bezier.bezier2_eval(pa, pb, pc, 1000)))))
	line!(CceText.printed(CceText.concat("quad-mid=", fmt(Bezier.bezier2_eval(pa, pb, pc, 500)))))
	line!(CceText.printed(CceText.concat("degen-cubic-250=", fmt(Bezier.bezier3_eval(pa, pa, pa, pa, 250)))))
	line!(CceText.printed(CceText.concat("degen-cubic-500=", fmt(Bezier.bezier3_eval(pa, pa, pa, pa, 500)))))
	line!(CceText.printed(CceText.concat("degen-cubic-750=", fmt(Bezier.bezier3_eval(pa, pa, pa, pa, 750)))))
	line!(CceText.printed(CceText.concat("degen-quad-500=", fmt(Bezier.bezier2_eval(pa, pa, pa, 500)))))
	line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("math-isqrt=", CceText.show_int(MathLib.math_isqrt(0))), " "), CceText.show_int(MathLib.math_isqrt(144))), " "), CceText.show_int(MathLib.math_isqrt(1000000)))))
	Ok({})
}
