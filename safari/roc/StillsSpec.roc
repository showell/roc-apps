# StillsSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import Stills
import Tuple

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

pt : Stills.StillPt
pt = { x: 0.5, y: 1.5 }

grad : Stills.StillGrad
grad = { kind: 2, rgba0: 16711680, rgba1: 255, off0: 0.25, off1: 0.75, ax: 2.5, ay: 3.5, bx: 4.5, by: 5.5, cx: 6.5, cy: 7.5, ux: 8.5, uy: 9.5, vx: 10.5, vy: 11.5 }

solid : Stills.StillPoly
solid = { color: 9066271, grad: [], pts: [pt, { x: 12.5, y: 13.5 }] }

shaded : Stills.StillPoly
shaded = { color: 4989733, grad: [grad], pts: [pt] }

grad_reals_got : List(F64)
grad_reals_got = [grad.off0, grad.off1, grad.ax, grad.ay, grad.bx, grad.by, grad.cx, grad.cy, grad.ux, grad.uy, grad.vx, grad.vy]

grad_reals_want : List(F64)
grad_reals_want = [0.25, 0.75, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5, 11.5]

grad_ints_got : List(I64)
grad_ints_got = [grad.kind, grad.rgba0, grad.rgba1]

grad_ints_want : List(I64)
grad_ints_want = [2, 16711680, 255]

poly_ints_got : List(I64)
poly_ints_got = [solid.color, shaded.color, U64.to_i64_wrap(List.len(solid.grad)), U64.to_i64_wrap(List.len(shaded.grad)), U64.to_i64_wrap(List.len(solid.pts)), U64.to_i64_wrap(List.len(shaded.pts))]

poly_ints_want : List(I64)
poly_ints_want = [9066271, 4989733, 0, 1, 2, 1]

reach_got : List(F64)
reach_got = [(List.get(shaded.grad, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).ax, (List.get(shaded.pts, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).x, (List.get(solid.pts, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).y]

reach_want : List(F64)
reach_want = [2.5, 0.5, 13.5]

eq_tup2 : Tuple.Tup2(a, b), Tuple.Tup2(a, b) -> Bool
eq_tup2 = |ex, ey| (match ex {
	MkTup2(exf0, exf1) => (match ey {
		MkTup2(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

eq_tup3 : Tuple.Tup3(a, b, c), Tuple.Tup3(a, b, c) -> Bool
eq_tup3 = |ex, ey| (match ex {
	MkTup3(exf0, exf1, exf2) => (match ey {
		MkTup3(eyf0, eyf1, eyf2) => (((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2))
		_ => False
	})
})

eq_tup4 : Tuple.Tup4(a, b, c, d), Tuple.Tup4(a, b, c, d) -> Bool
eq_tup4 = |ex, ey| (match ex {
	MkTup4(exf0, exf1, exf2, exf3) => (match ey {
		MkTup4(eyf0, eyf1, eyf2, eyf3) => ((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3))
		_ => False
	})
})

eq_tup5 : Tuple.Tup5(a, b, c, d, e), Tuple.Tup5(a, b, c, d, e) -> Bool
eq_tup5 = |ex, ey| (match ex {
	MkTup5(exf0, exf1, exf2, exf3, exf4) => (match ey {
		MkTup5(eyf0, eyf1, eyf2, eyf3, eyf4) => (((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3)) and (exf4 == eyf4))
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("s-gradr", grad_reals_got, grad_reals_want, 0.0))
	line!(Grade.grade_ints("s-gradi", grad_ints_got, grad_ints_want))
	line!(Grade.grade_ints("s-poly ", poly_ints_got, poly_ints_want))
	line!(Grade.grade_reals("s-reach", reach_got, reach_want, 0.0))
	Ok({})
}
