# GroundSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Geom
import Grade
import Ground
import ListUtils
import Paint
import Tuple

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

pts_a : List(Geom.RiderPt)
pts_a = [{ right: 0.0, forward: 0.0 }, { right: 3.0, forward: 10.0 }, { right: (-5.0), forward: 40.0 }, { right: 12.5, forward: 100.0 }]

height_got : List(F64)
height_got = ListUtils.list_map(lam_0, Ground.ground_verts(pts_a, 0))

height_want : List(F64)
height_want = [0.0, (-0.000545), (-0.008125), (-0.05078125)]

carry_got : List(F64)
carry_got = ({
	vs = Ground.ground_verts(pts_a, 0)
	[(List.get(vs, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).right, (List.get(vs, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).forward, (List.get(vs, I64.to_u64_wrap(3)) ?? crash("list-at out of range")).right, (List.get(vs, I64.to_u64_wrap(3)) ?? crash("list-at out of range")).forward]
})

carry_want : List(F64)
carry_want = [3.0, 10.0, 12.5, 100.0]

quad : List(Geom.RiderPt)
quad = [{ right: (-5.0), forward: 10.0 }, { right: 5.0, forward: 10.0 }, { right: 5.0, forward: 20.0 }, { right: (-5.0), forward: 20.0 }]

behind : List(Geom.RiderPt)
behind = [{ right: (-5.0), forward: (-10.0) }, { right: 5.0, forward: (-10.0) }, { right: 5.0, forward: (-20.0) }, { right: (-5.0), forward: (-20.0) }]

two_points : List(Geom.RiderPt)
two_points = [{ right: (-5.0), forward: 10.0 }, { right: 5.0, forward: 10.0 }]

wide : I64 -> List(Geom.RiderPt)
wide = |n| (if (n <= 0) { [] } else { List.concat([{ right: I64.to_f64(n), forward: (10.0 + I64.to_f64(n)) }], wide((n - 1))) })

drawn : List(Geom.RiderPt) -> List(Paint.DrawCmd)
drawn = |ps| Ground.emit_ground_color(ps, 3112588, 685.5110432362151, 960.0)

count_got : List(I64)
count_got = [U64.to_i64_wrap(List.len(drawn(quad))), U64.to_i64_wrap(List.len(drawn(wide(8)))), U64.to_i64_wrap(List.len(drawn(wide(9)))), U64.to_i64_wrap(List.len(drawn(behind))), U64.to_i64_wrap(List.len(drawn(two_points)))]

count_want : List(I64)
count_want = [1, 1, 0, 0, 0]

cmd_got : List(I64)
cmd_got = ({
	c = (List.get(drawn(quad), I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
	[c.tag, c.color, c.color2, U64.to_i64_wrap(List.len(c.pts)), U64.to_i64_wrap(List.len(c.geom))]
})

cmd_want : List(I64)
cmd_want = [0, 3112588, 0, 8, 0]

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

lam_0 : Geom.Vec3 -> F64
lam_0 = |v| v.height

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("gr-height", height_got, height_want, 0.0))
	line!(Grade.grade_reals("gr-carry ", carry_got, carry_want, 0.0))
	line!(Grade.grade_ints("gr-count ", count_got, count_want))
	line!(Grade.grade_ints("gr-cmd   ", cmd_got, cmd_want))
	Ok({})
}
