# Bezier -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import MathLib

Bezier :: [].{
	BezVec := { vx : I64, vy : I64, vz : I64 }.{
		is_eq : Bezier.BezVec, Bezier.BezVec -> Bool
		is_eq = |a, b| a.vx == b.vx and a.vy == b.vy and a.vz == b.vz
	}

	bez_lerp : Bezier.BezVec, Bezier.BezVec, I64 -> Bezier.BezVec
	bez_lerp = |p, q, t| Bezier.BezVec.{ vx: (p.vx + I64.div_trunc_by(((q.vx - p.vx) * t), 1000)), vy: (p.vy + I64.div_trunc_by(((q.vy - p.vy) * t), 1000)), vz: (p.vz + I64.div_trunc_by(((q.vz - p.vz) * t), 1000)) }

	bezier2_eval : Bezier.BezVec, Bezier.BezVec, Bezier.BezVec, I64 -> Bezier.BezVec
	bezier2_eval = |p0, p1, p2, t| bez_lerp(bez_lerp(p0, p1, t), bez_lerp(p1, p2, t), t)

	bezier3_eval : Bezier.BezVec, Bezier.BezVec, Bezier.BezVec, Bezier.BezVec, I64 -> Bezier.BezVec
	bezier3_eval = |p0, p1, p2, p3, t| ({
		ab = bez_lerp(p0, p1, t)
		bc = bez_lerp(p1, p2, t)
		cd = bez_lerp(p2, p3, t)
		bez_lerp(bez_lerp(ab, bc, t), bez_lerp(bc, cd, t), t)
	})

	bezier3_sample : Bezier.BezVec, Bezier.BezVec, Bezier.BezVec, Bezier.BezVec, I64 -> List(Bezier.BezVec)
	bezier3_sample = |p0, p1, p2, p3, steps| bezier3_sample_loop(p0, p1, p2, p3, 0, steps, [])

	bezier3_sample_loop : Bezier.BezVec, Bezier.BezVec, Bezier.BezVec, Bezier.BezVec, I64, I64, List(Bezier.BezVec) -> List(Bezier.BezVec)
	bezier3_sample_loop = |p0, p1, p2, p3, i, steps, acc| (if (i > steps) { acc } else { ({
		t : I64
		t = I64.div_trunc_by((i * 1000), steps)
		bezier3_sample_loop(p0, p1, p2, p3, (i + 1), steps, List.append(acc, bezier3_eval(p0, p1, p2, p3, t)))
	}) })

	bezier3_arc_length : Bezier.BezVec, Bezier.BezVec, Bezier.BezVec, Bezier.BezVec, I64 -> I64
	bezier3_arc_length = |p0, p1, p2, p3, segments| bezier3_arc_loop(p0, p1, p2, p3, 0, segments, 0, bezier3_eval(p0, p1, p2, p3, 0))

	bezier3_arc_loop : Bezier.BezVec, Bezier.BezVec, Bezier.BezVec, Bezier.BezVec, I64, I64, I64, Bezier.BezVec -> I64
	bezier3_arc_loop = |p0, p1, p2, p3, i, segments, total, prev| (if (i >= segments) { total } else { ({
		t : I64
		t = I64.div_trunc_by(((i + 1) * 1000), segments)
		curr = bezier3_eval(p0, p1, p2, p3, t)
		dx : I64
		dx = (curr.vx - prev.vx)
		dy : I64
		dy = (curr.vy - prev.vy)
		dist : I64
		dist = MathLib.math_isqrt(((dx * dx) + (dy * dy)))
		bezier3_arc_loop(p0, p1, p2, p3, (i + 1), segments, (total + dist), curr)
	}) })

	format_bezier_point : Bezier.BezVec -> CceText
	format_bezier_point = |v| CceText.concat(CceText.concat(CceText.concat(CceText.concat("(", CceText.show_int(v.vx)), ","), CceText.show_int(v.vy)), ")")
}
