# GuardRailSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Geom
import Grade
import GuardRail

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

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
shape_got = [U64.to_i64_wrap(List.len(rails)), U64.to_i64_wrap(List.len(GuardRail.bars(straight, 0))), U64.to_i64_wrap(List.len(GuardRail.posts(straight, 0))), U64.to_i64_wrap(List.len((List.get(rails, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).v)), U64.to_i64_wrap(List.len((List.get(rails, I64.to_u64_wrap(4)) ?? crash("list-at out of range")).v))]

shape_want : List(I64)
shape_want = [5, 2, 3, 4, 4]

colour_got : List(I64)
colour_got = [(List.get(rails, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).color, (List.get(rails, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).color, (List.get(rails, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).color, (List.get(rails, I64.to_u64_wrap(3)) ?? crash("list-at out of range")).color, (List.get(rails, I64.to_u64_wrap(4)) ?? crash("list-at out of range")).color]

colour_want : List(I64)
colour_want = [12765135, 12765135, 10133672, 10133672, 10133672]

fwd_got : List(F64)
fwd_got = [(List.get(rails, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).fwd, (List.get(rails, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).fwd, (List.get(rails, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).fwd, (List.get(rails, I64.to_u64_wrap(3)) ?? crash("list-at out of range")).fwd, (List.get(rails, I64.to_u64_wrap(4)) ?? crash("list-at out of range")).fwd]

fwd_want : List(F64)
fwd_want = [15.0, 25.0, 10.0, 20.0, 30.0]

bar_got : List(F64)
bar_got = ({
	v = (List.get(rails, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).v
	[(List.get(v, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(3)) ?? crash("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).height, (List.get(v, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).height, (List.get(v, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).height, (List.get(v, I64.to_u64_wrap(3)) ?? crash("list-at out of range")).height]
})

bar_want : List(F64)
bar_want = [10.0, 20.0, 20.0, 10.0, 0.45, 0.45, 0.55, 0.55]

post_got : List(F64)
post_got = ({
	v = (List.get(rails, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).v
	[(List.get(v, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(3)) ?? crash("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).height, (List.get(v, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).height, (List.get(v, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).right, (List.get(v, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).right]
})

post_want : List(F64)
post_want = [9.99, 10.01, 10.01, 9.99, 0.0, 0.55, 0.0, 0.0]

diagonal : List(Geom.RiderPt)
diagonal = [pt(0.0, 10.0), pt(30.0, 50.0)]

diag_got : List(F64)
diag_got = ({
	v = (List.get(GuardRail.posts(diagonal, 0), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).v
	[(List.get(v, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).right, (List.get(v, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).right, (List.get(v, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).forward]
})

diag_want : List(F64)
diag_want = [(-0.006), 0.006, 9.992, 10.008]

doubled : List(Geom.RiderPt)
doubled = [pt(0.0, 10.0), pt(0.0, 10.0)]

doubled_got : List(F64)
doubled_got = ({
	v = (List.get(GuardRail.posts(doubled, 0), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).v
	[I64.to_f64(U64.to_i64_wrap(List.len(GuardRail.rail_emit(doubled)))), (List.get(v, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).right, (List.get(v, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).right, (List.get(v, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).forward, (List.get(v, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).height]
})

doubled_want : List(F64)
doubled_want = [3.0, 0.0, 0.0, 10.0, 10.0, 0.55]

short_got : List(I64)
short_got = [U64.to_i64_wrap(List.len(GuardRail.rail_emit([]))), U64.to_i64_wrap(List.len(GuardRail.rail_emit([pt(0.0, 10.0)]))), U64.to_i64_wrap(List.len(GuardRail.rail_emit(doubled))), U64.to_i64_wrap(List.len(GuardRail.bars([pt(0.0, 10.0)], 0)))]

short_want : List(I64)
short_want = [0, 0, 3, 0]

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("gu-dims  ", dims_got, dims_want, 0.0))
	line!(Grade.grade_ints("gu-fixed ", fixed_got, fixed_want))
	line!(Grade.grade_ints("gu-shape ", shape_got, shape_want))
	line!(Grade.grade_ints("gu-colour", colour_got, colour_want))
	line!(Grade.grade_reals("gu-fwd   ", fwd_got, fwd_want, 0.0))
	line!(Grade.grade_reals("gu-bar   ", bar_got, bar_want, 0.0))
	line!(Grade.grade_reals("gu-post  ", post_got, post_want, 0.0))
	line!(Grade.grade_reals("gu-diag  ", diag_got, diag_want, 0.0))
	line!(Grade.grade_reals("gu-double", doubled_got, doubled_want, 0.0))
	line!(Grade.grade_ints("gu-short ", short_got, short_want))
	Ok({})
}
