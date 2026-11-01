# GuardRailSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Geom
import Grade
import GuardRail

dims_got : List(F64)
dims_got = [GuardRail.rail_height, GuardRail.rail_thickness, GuardRail.rail_post_width, GuardRail.bar_top, GuardRail.bar_bot, GuardRail.half_post]

dims_want : List(F64)
dims_want = [0.5, 0.1, 0.02, 0.55, 0.45, 0.01]

fixed_got : List(I64)
fixed_got = [GuardRail.rail_metal, GuardRail.rail_post_metal, GuardRail.rail_runout, GuardRail.max_rail_polys]

fixed_want : List(I64)
fixed_want = [12765135, 10133672, 10, 3072]

pt : F64, F64 -> Geom.RiderPt
pt = |r, f| { right: r, forward: f }

straight : List(Geom.RiderPt)
straight = [pt(0.0, 10.0), pt(0.0, 20.0), pt(0.0, 30.0)]

rails : List(GuardRail.RailPoly)
rails = GuardRail.rail_emit(straight)

shape_got : List(I64)
shape_got = [rails.len().to_i64_wrap(), GuardRail.bars(straight, 0).len().to_i64_wrap(), GuardRail.posts(straight, 0).len().to_i64_wrap(), (List.get(rails, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).v.len().to_i64_wrap(), (List.get(rails, I64.to_u64_wrap(4)) ?? crash ("list-at out of range")).v.len().to_i64_wrap()]

shape_want : List(I64)
shape_want = [5, 2, 3, 4, 4]

colour_got : List(I64)
colour_got = [(List.get(rails, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).color, (List.get(rails, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).color, (List.get(rails, I64.to_u64_wrap(2)) ?? crash ("list-at out of range")).color, (List.get(rails, I64.to_u64_wrap(3)) ?? crash ("list-at out of range")).color, (List.get(rails, I64.to_u64_wrap(4)) ?? crash ("list-at out of range")).color]

colour_want : List(I64)
colour_want = [12765135, 12765135, 10133672, 10133672, 10133672]

fwd_got : List(F64)
fwd_got = [(List.get(rails, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).fwd, (List.get(rails, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).fwd, (List.get(rails, I64.to_u64_wrap(2)) ?? crash ("list-at out of range")).fwd, (List.get(rails, I64.to_u64_wrap(3)) ?? crash ("list-at out of range")).fwd, (List.get(rails, I64.to_u64_wrap(4)) ?? crash ("list-at out of range")).fwd]

fwd_want : List(F64)
fwd_want = [15.0, 25.0, 10.0, 20.0, 30.0]

bar_got : List(F64)
bar_got = (
	{
		v = (List.get(rails, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).v
		[(List.get(v, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(2)) ?? crash ("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(3)) ?? crash ("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).height, (List.get(v, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).height, (List.get(v, I64.to_u64_wrap(2)) ?? crash ("list-at out of range")).height, (List.get(v, I64.to_u64_wrap(3)) ?? crash ("list-at out of range")).height]
	}
)

bar_want : List(F64)
bar_want = [10.0, 20.0, 20.0, 10.0, 0.45, 0.45, 0.55, 0.55]

post_got : List(F64)
post_got = (
	{
		v = (List.get(rails, I64.to_u64_wrap(2)) ?? crash ("list-at out of range")).v
		[(List.get(v, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(2)) ?? crash ("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(3)) ?? crash ("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).height, (List.get(v, I64.to_u64_wrap(2)) ?? crash ("list-at out of range")).height, (List.get(v, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).right, (List.get(v, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).right]
	}
)

post_want : List(F64)
post_want = [9.99, 10.01, 10.01, 9.99, 0.0, 0.55, 0.0, 0.0]

diagonal : List(Geom.RiderPt)
diagonal = [pt(0.0, 10.0), pt(30.0, 50.0)]

diag_got : List(F64)
diag_got = (
	{
		v = (List.get(GuardRail.posts(diagonal, 0), I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).v
		[(List.get(v, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).right, (List.get(v, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).right, (List.get(v, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).forward]
	}
)

diag_want : List(F64)
diag_want = [(-0.006), 0.006, 9.992, 10.008]

doubled : List(Geom.RiderPt)
doubled = [pt(0.0, 10.0), pt(0.0, 10.0)]

doubled_got : List(F64)
doubled_got = (
	{
		v = (List.get(GuardRail.posts(doubled, 0), I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).v
		[I64.to_f64(GuardRail.rail_emit(doubled).len().to_i64_wrap()), (List.get(v, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).right, (List.get(v, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).right, (List.get(v, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(2)) ?? crash ("list-at out of range")).height]
	}
)

doubled_want : List(F64)
doubled_want = [3.0, 0.0, 0.0, 10.0, 10.0, 0.55]

short_got : List(I64)
short_got = [GuardRail.rail_emit([]).len().to_i64_wrap(), GuardRail.rail_emit([pt(0.0, 10.0)]).len().to_i64_wrap(), GuardRail.rail_emit(doubled).len().to_i64_wrap(), GuardRail.bars([pt(0.0, 10.0)], 0).len().to_i64_wrap()]

short_want : List(I64)
short_want = [0, 0, 3, 0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "gu-dims  ",
			got: dims_got,
			want: dims_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "gu-fixed ",
			got: fixed_got,
			want: fixed_want,
		}),
		Grade.ints({
			name: "gu-shape ",
			got: shape_got,
			want: shape_want,
		}),
		Grade.ints({
			name: "gu-colour",
			got: colour_got,
			want: colour_want,
		}),
		Grade.reals({
			name: "gu-fwd   ",
			got: fwd_got,
			want: fwd_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "gu-bar   ",
			got: bar_got,
			want: bar_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "gu-post  ",
			got: post_got,
			want: post_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "gu-diag  ",
			got: diag_got,
			want: diag_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "gu-double",
			got: doubled_got,
			want: doubled_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "gu-short ",
			got: short_got,
			want: short_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
