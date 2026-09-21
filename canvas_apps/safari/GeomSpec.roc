# GeomSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Geom
import Grade
import Text

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

gd_right : List(F64)
gd_right = [0.0, 3.0, (-5.0), 12.5]

gd_forward : List(F64)
gd_forward = [0.0, 10.0, 40.0, 100.0]

gd_want : List(F64)
gd_want = [0.0, 0.000545, 0.008125, 0.05078125]

# gd_walk builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
gd_walk : I64 -> List(F64)
gd_walk = |i| gd_walk_acc(i, [])

gd_walk_acc : I64, List(F64) -> List(F64)
gd_walk_acc = |i, acc| (if (i >= U64.to_i64_wrap(List.len(gd_right))) { acc } else { gd_walk_acc((i + 1), List.append(acc, Geom.ground_drop((List.get(gd_right, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), (List.get(gd_forward, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

tr_a : List(F64)
tr_a = [0.0, 12.0, 40.0, 7.5]

tr_x : List(F64)
tr_x = [0.0, 3.0, (-2.0), 6.25]

tr_yaw : List(F64)
tr_yaw = [0.0, 0.35, (-0.6), 1.2]

tr_want : List(F64)
tr_want = [(-3.5), (-5.0), (-2.869971008611849), 6.404160086203927, 15.223140686823006, 31.992280125511435, (-1.333613890107213), 3.4690018726015563]

# tr_walk builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
tr_walk : I64 -> List(F64)
tr_walk = |i| tr_walk_acc(i, [])

tr_walk_acc : I64, List(F64) -> List(F64)
tr_walk_acc = |i, acc| (if (i >= U64.to_i64_wrap(List.len(tr_a))) { acc } else { ({
	p = Geom.to_rider((List.get(tr_a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), (List.get(tr_x, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), 5.0, 0.5, (List.get(tr_yaw, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), 3.0)
	tr_walk_acc((i + 1), List.append(List.append(acc, p.right), p.forward))
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

# cn_walk builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
cn_walk : List(Geom.Vec3), I64 -> List(F64)
cn_walk = |vs, i| cn_walk_acc(vs, i, [])

cn_walk_acc : List(Geom.Vec3), I64, List(F64) -> List(F64)
cn_walk_acc = |vs, i, acc| (if (i >= U64.to_i64_wrap(List.len(vs))) { acc } else { ({
	v = (List.get(vs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	cn_walk_acc(vs, (i + 1), List.append(List.append(List.append(acc, v.right), v.forward), v.height))
}) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_reals([29, 73, 22, 21, 16, 31, 2], gd_walk(0), gd_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([29, 73, 21, 17, 22, 13, 21], tr_walk(0), tr_want, F64.from_bits(4517329193108106637))))
	line!(Text.printed(Grade.grade_reals([29, 73, 26, 13, 13, 14, 2], lm_got, lm_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([29, 73, 24, 23, 17, 31, 2], cn_walk(Geom.clip_near(poly, 0.4), 0), cn_want, 0.0)))
	Ok({})
}
