# GeomSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Geom
import Grade

gd_right : List(F64)
gd_right = [
	0.0,
	3.0,
	(-5.0),
	12.5,
]

gd_forward : List(F64)
gd_forward = [0.0, 10.0, 40.0, 100.0]

gd_want : List(F64)
gd_want = [0.0, 0.000545, 0.008125, 0.05078125]

# gd_walk builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
gd_walk : I64 -> List(F64)
gd_walk = |i| gd_walk_onto(i, [])

gd_walk_onto : I64, List(F64) -> List(F64)
gd_walk_onto = |i, acc| (
	if i >= gd_right.len().to_i64_wrap() {
		acc
	} else {
		right = List.get(gd_right, I64.to_u64_wrap(i)) ?? crash "GeomSpec: a right for every case"
		forward = List.get(
			gd_forward,
			I64.to_u64_wrap(i),
		) ?? crash "GeomSpec: a forward for every case"
		gd_walk_onto((i + 1), acc.append(Geom.ground_drop(right, forward)))
	}
)

tr_a : List(F64)
tr_a = [0.0, 12.0, 40.0, 7.5]

tr_x : List(F64)
tr_x = [
	0.0,
	3.0,
	(-2.0),
	6.25,
]

tr_yaw : List(F64)
tr_yaw = [
	0.0,
	0.35,
	(-0.6),
	1.2,
]

tr_want : List(F64)
tr_want = [
	(-3.5),
	(-5.0),
	(-2.869971008611849),
	6.404160086203927,
	15.223140686823006,
	31.992280125511435,
	(-1.333613890107213),
	3.4690018726015563,
]

# tr_walk builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
tr_walk : I64 -> List(F64)
tr_walk = |i| tr_walk_onto(i, [])

tr_walk_onto : I64, List(F64) -> List(F64)
tr_walk_onto = |i, acc| (
	if i >= tr_a.len().to_i64_wrap() {
		acc
	} else {
		(
			{
				p = Geom.to_rider(
					{
						a: (List.get(tr_a, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")),
						x: (List.get(tr_x, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")),
					},
					{
						along: 5.0,
						across: 0.5,
						yaw: (
							List.get(
								tr_yaw,
								I64.to_u64_wrap(i),
							) ?? crash ("list-at out of range")
						),
						hw: 3.0,
					},
				)
				tr_walk_onto((i + 1), List.append(List.append(acc, p.right), p.forward))
			}
		)
	}
)

lm_want : List(F64)
lm_want = [0.0, 4.0]

lm_got : List(F64)
lm_got = (
	{
		q = Geom.line_meet({
			first_line: {
				start_point: { right: 0.0, forward: 0.0 },
				end_point: { right: 0.0, forward: 1.0 },
			},
			second_line: {
				start_point: { right: (-2.0), forward: 4.0 },
				end_point: { right: 3.0, forward: 4.0 },
			},
		})
		[q.right, q.forward]
	}
)

poly : List(Geom.Vec3)
poly = [
	{
		right: (-1.0),
		forward: 2.0,
		height: 0.0,
	},
	{
		right: 1.0,
		forward: 2.0,
		height: 0.5,
	},
	{
		right: 1.0,
		forward: (-1.0),
		height: 1.0,
	},
	{
		right: (-1.0),
		forward: (-1.0),
		height: 1.5,
	},
]

cn_want : List(F64)
cn_want = [
	(-1.0),
	2.0,
	0.0,
	1.0,
	2.0,
	0.5,
	1.0,
	0.4,
	0.7666666666666666,
	(-1.0),
	0.4,
	0.8,
]

# cn_walk builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
cn_walk : List(Geom.Vec3) -> List(F64)
cn_walk = |vs| cn_walk_onto(vs, { at_index: 0, flat_coords: [] })

cn_walk_onto : List(Geom.Vec3), { at_index : I64, flat_coords : List(F64) } -> List(F64)
cn_walk_onto = |vs, { at_index: i, flat_coords: acc }| (
	if i >= vs.len().to_i64_wrap() {
		acc
	} else {
		(
			{
				v = (List.get(vs, I64.to_u64_wrap(i)) ?? crash ("list-at out of range"))
				cn_walk_onto(
					vs,
					{
						at_index: (i + 1),
						flat_coords: acc.concat([
							v.right,
							v.forward,
							v.height,
						]),
					},
				)
			}
		)
	}
)

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "g-drop ",
			got: gd_walk(0),
			want: gd_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "g-rider",
			got: tr_walk(0),
			want: tr_want,
			tol: F64.from_bits(4517329193108106637),
		}),
		Grade.reals({
			name: "g-meet ",
			got: lm_got,
			want: lm_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "g-clip ",
			got: cn_walk(Geom.clip_near(poly)),
			want: cn_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
