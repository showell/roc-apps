# GroundSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Geom
import Grade
import Ground
import ListUtils
import Paint

pts_a : List(Geom.RiderPt)
pts_a = [{ right: 0.0, forward: 0.0 }, { right: 3.0, forward: 10.0 }, { right: (-5.0), forward: 40.0 }, { right: 12.5, forward: 100.0 }]

height_got : List(F64)
height_got = ListUtils.list_map(lam_0, Ground.ground_verts(pts_a, 0))

height_want : List(F64)
height_want = [0.0, (-0.000545), (-0.008125), (-0.05078125)]

carry_got : List(F64)
carry_got = (
	{
		vs = Ground.ground_verts(pts_a, 0)
		[(List.get(vs, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).right, (List.get(vs, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).forward, (List.get(vs, I64.to_u64_wrap(3)) ?? crash ("list-at out of range")).right, (List.get(vs, I64.to_u64_wrap(3)) ?? crash ("list-at out of range")).forward]
	}
)

carry_want : List(F64)
carry_want = [3.0, 10.0, 12.5, 100.0]

quad : List(Geom.RiderPt)
quad = [{ right: (-5.0), forward: 10.0 }, { right: 5.0, forward: 10.0 }, { right: 5.0, forward: 20.0 }, { right: (-5.0), forward: 20.0 }]

behind : List(Geom.RiderPt)
behind = [{ right: (-5.0), forward: (-10.0) }, { right: 5.0, forward: (-10.0) }, { right: 5.0, forward: (-20.0) }, { right: (-5.0), forward: (-20.0) }]

two_points : List(Geom.RiderPt)
two_points = [{ right: (-5.0), forward: 10.0 }, { right: 5.0, forward: 10.0 }]

# wide builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
wide : I64 -> List(Geom.RiderPt)
wide = |n| wide_acc(n, [])

wide_acc : I64, List(Geom.RiderPt) -> List(Geom.RiderPt)
wide_acc = |n, acc| (
	if (n <= 0) {
		acc
	} else {
		wide_acc((n - 1), List.append(acc, { right: I64.to_f64(n), forward: (10.0 + I64.to_f64(n)) }))
	}
)

drawn : List(Geom.RiderPt) -> List(Paint.DrawCmd)
drawn = |ps| Ground.emit_ground_color(ps, 3112588, 685.5110432362151, 960.0)

count_got : List(I64)
count_got = [drawn(quad).len().to_i64_wrap(), drawn(wide(8)).len().to_i64_wrap(), drawn(wide(9)).len().to_i64_wrap(), drawn(behind).len().to_i64_wrap(), drawn(two_points).len().to_i64_wrap()]

count_want : List(I64)
count_want = [1, 1, 0, 0, 0]

cmd_got : List(I64)
cmd_got = (
	{
		c = (List.get(drawn(quad), I64.to_u64_wrap(0)) ?? crash ("list-at out of range"))
		[c.tag, c.color, c.color2, c.pts.len().to_i64_wrap(), c.geom.len().to_i64_wrap()]
	}
)

cmd_want : List(I64)
cmd_want = [0, 3112588, 0, 8, 0]

lam_0 : Geom.Vec3 -> F64
lam_0 = |v| v.height

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "gr-height",
			got: height_got,
			want: height_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "gr-carry ",
			got: carry_got,
			want: carry_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "gr-count ",
			got: count_got,
			want: count_want,
		}),
		Grade.ints({
			name: "gr-cmd   ",
			got: cmd_got,
			want: cmd_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
