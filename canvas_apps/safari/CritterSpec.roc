# CritterSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Camera
import Critter
import EmojiStills
import Grade
import Stills

facing_got : List(F64)
facing_got = [Critter.facing(True), Critter.facing(False)]

facing_want : List(F64)
facing_want = [(-1.0), 1.0]

feet : Camera.ScreenPt
feet = { x: 100.0, y: 200.0 }

point_got : List(F64)
point_got = (
	{
		a = Critter.map_p(feet, 1.0, 50.0, 0.5, 0.4)
		b = Critter.map_p(feet, (0.0 - 1.0), 50.0, 0.5, 0.4)
		c = Critter.map_p(feet, 1.0, 50.0, 0.0, 0.0)
		[a.x, a.y, b.x, b.y, c.x, c.y]
	}
)

point_want : List(F64)
point_want = [125.0, 180.0, 75.0, 180.0, 100.0, 200.0]

vector_got : List(F64)
vector_got = (
	{
		a = Critter.map_v(1.0, 50.0, 0.5, 0.4)
		b = Critter.map_v((0.0 - 1.0), 50.0, 0.5, 0.4)
		c = Critter.map_v(1.0, 50.0, 0.0, 0.0)
		[a.x, a.y, b.x, b.y, c.x, c.y]
	}
)

vector_want : List(F64)
vector_want = [25.0, (-20.0), (-25.0), (-20.0), 0.0, 0.0]

anchor_got : List(F64)
anchor_got = (
	{
		p = Critter.map_p(feet, 1.0, 50.0, 0.5, 0.4)
		v = Critter.map_v(1.0, 50.0, 0.5, 0.4)
		[(p.x - v.x), (p.y - v.y)]
	}
)

anchor_want : List(F64)
anchor_want = [100.0, 200.0]

mapped_got : List(F64)
mapped_got = (
	{
		ps = Critter.mapped_pts(feet, 1.0, 50.0, [{ x: 0.0, y: 0.0 }, { x: 0.5, y: 0.4 }, { x: 1.0, y: 1.0 }])
		[I64.to_f64(ps.len().to_i64_wrap()), (List.get(ps, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).x, (List.get(ps, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).y, (List.get(ps, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).x, (List.get(ps, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).y, (List.get(ps, I64.to_u64_wrap(2)) ?? crash ("list-at out of range")).x, (List.get(ps, I64.to_u64_wrap(2)) ?? crash ("list-at out of range")).y]
	}
)

mapped_want : List(F64)
mapped_want = [3.0, 100.0, 200.0, 125.0, 180.0, 150.0, 150.0]

# many builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
many : I64 -> List(Stills.StillPt)
many = |n| many_acc(n, [])

many_acc : I64, List(Stills.StillPt) -> List(Stills.StillPt)
many_acc = |n, acc| (
	if (n <= 0) {
		acc
	} else {
		many_acc((n - 1), List.append(acc, { x: 0.0, y: 0.0 }))
	}
)

flat_poly : I64 -> Stills.StillPoly
flat_poly = |n| { color: 7, grad: [], pts: many(n) }

guard_got : List(I64)
guard_got = [Critter.max_critter_pts, Critter.critter_poly(feet, 1.0, 50.0, flat_poly(3)).len().to_i64_wrap(), Critter.critter_poly(feet, 1.0, 50.0, flat_poly(512)).len().to_i64_wrap(), Critter.critter_poly(feet, 1.0, 50.0, flat_poly(513)).len().to_i64_wrap(), Critter.critter_poly(feet, 1.0, 50.0, flat_poly(2)).len().to_i64_wrap()]

guard_want : List(I64)
guard_want = [512, 1, 1, 0, 0]

solid_got : List(I64)
solid_got = (
	{
		c = (List.get(Critter.critter_poly(feet, 1.0, 50.0, flat_poly(3)), I64.to_u64_wrap(0)) ?? crash ("list-at out of range"))
		[c.tag, c.color, c.pts.len().to_i64_wrap()]
	}
)

solid_want : List(I64)
solid_want = [0, 7, 6]

drawn : F64, F64 -> I64
drawn = |forward, height| Critter.critter_draw(0.0, forward, height, 128024, False, 500.0, 960.0).len().to_i64_wrap()

size_got : List(I64)
size_got = [drawn(1000.0, 2.0), drawn(2000.0, 2.0), drawn(1000.0, 1.9), drawn(100.0, 2.0)]

size_want : List(I64)
size_want = [6, 0, 0, 6]

unknown_got : List(I64)
unknown_got = [EmojiStills.emoji_polys_for(1).len().to_i64_wrap(), Critter.critter_draw(0.0, 100.0, 2.0, 1, False, 500.0, 960.0).len().to_i64_wrap(), EmojiStills.emoji_polys_for(128024).len().to_i64_wrap()]

unknown_want : List(I64)
unknown_want = [0, 0, 6]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "cr-facing",
			got: facing_got,
			want: facing_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "cr-point ",
			got: point_got,
			want: point_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "cr-vector",
			got: vector_got,
			want: vector_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "cr-anchor",
			got: anchor_got,
			want: anchor_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "cr-mapped",
			got: mapped_got,
			want: mapped_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "cr-guard ",
			got: guard_got,
			want: guard_want,
		}),
		Grade.ints({
			name: "cr-solid ",
			got: solid_got,
			want: solid_want,
		}),
		Grade.ints({
			name: "cr-size  ",
			got: size_got,
			want: size_want,
		}),
		Grade.ints({
			name: "cr-unknwn",
			got: unknown_got,
			want: unknown_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
