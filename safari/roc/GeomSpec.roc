# GeomSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Geom
import Grade
import Tuple

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

gd_right : List(F64)
gd_right = [0.0, 3.0, (-5.0), 12.5]

gd_forward : List(F64)
gd_forward = [0.0, 10.0, 40.0, 100.0]

gd_want : List(F64)
gd_want = [0.0, 0.000545, 0.008125, 0.05078125]

gd_walk : I64 -> List(F64)
gd_walk = |i| (if (i >= U64.to_i64_wrap(List.len(gd_right))) { [] } else { List.concat([Geom.ground_drop((List.get(gd_right, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), (List.get(gd_forward, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))], gd_walk((i + 1))) })

tr_a : List(F64)
tr_a = [0.0, 12.0, 40.0, 7.5]

tr_x : List(F64)
tr_x = [0.0, 3.0, (-2.0), 6.25]

tr_yaw : List(F64)
tr_yaw = [0.0, 0.35, (-0.6), 1.2]

tr_want : List(F64)
tr_want = [(-3.5), (-5.0), (-2.869971008611849), 6.404160086203927, 15.223140686823006, 31.992280125511435, (-1.333613890107213), 3.4690018726015563]

tr_walk : I64 -> List(F64)
tr_walk = |i| (if (i >= U64.to_i64_wrap(List.len(tr_a))) { [] } else { ({
	p = Geom.to_rider((List.get(tr_a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), (List.get(tr_x, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), 5.0, 0.5, (List.get(tr_yaw, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), 3.0)
	List.concat([p.right, p.forward], tr_walk((i + 1)))
}) })

lm_want : List(F64)
lm_want = [0.0, 4.0]

lm_got : List(F64)
lm_got = ({
	q = Geom.line_meet({ right: 0.0, forward: 0.0 }, { right: 0.0, forward: 1.0 }, { right: (-2.0), forward: 4.0 }, { right: 3.0, forward: 4.0 })
	[q.right, q.forward]
})

poly : List(Geom.Vec3)
poly = [{ right: (-1.0), forward: 2.0, height: 0.0 }, { right: 1.0, forward: 2.0, height: 0.5 }, { right: 1.0, forward: (-1.0), height: 1.0 }, { right: (-1.0), forward: (-1.0), height: 1.5 }]

cn_want : List(F64)
cn_want = [(-1.0), 2.0, 0.0, 1.0, 2.0, 0.5, 1.0, 0.4, 0.7666666666666666, (-1.0), 0.4, 0.8]

cn_walk : List(Geom.Vec3), I64 -> List(F64)
cn_walk = |vs, i| (if (i >= U64.to_i64_wrap(List.len(vs))) { [] } else { ({
	v = (List.get(vs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	List.concat([v.right, v.forward, v.height], cn_walk(vs, (i + 1)))
}) })

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
	line!(Grade.grade_reals("g-drop ", gd_walk(0), gd_want, 0.0))
	line!(Grade.grade_reals("g-rider", tr_walk(0), tr_want, F64.from_bits(4517329193108106637)))
	line!(Grade.grade_reals("g-meet ", lm_got, lm_want, 0.0))
	line!(Grade.grade_reals("g-clip ", cn_walk(Geom.clip_near(poly, 0.4), 0), cn_want, 0.0))
	Ok({})
}
