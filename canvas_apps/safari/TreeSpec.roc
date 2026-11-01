# TreeSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Camera
import Grade
import Paint
import Tree

table_got : List(F64)
table_got = List.join([Tree.tier_top, Tree.tier_bot, Tree.tier_wide])

table_want : List(F64)
table_want = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 0.35, 0.44, 0.53, 0.63, 0.72, 0.81, 0.91, 1.0]

size_got : List(I64)
size_got = [Tree.tier_top.len().to_i64_wrap(), Tree.tier_bot.len().to_i64_wrap(), Tree.tier_wide.len().to_i64_wrap(), Tree.ring_n, Tree.trunk_color]

size_want : List(I64)
size_want = [8, 8, 8, 16, 5914146]

frac_got : List(F64)
frac_got = [Tree.visible_trunk, Tree.crown_h, Tree.crown_w, Tree.min_cone_forward]

frac_want : List(F64)
frac_want = [0.44, 0.648, 0.288, 0.4]

metrics : Tree.Metrics
metrics = Tree.metrics(0.0, 2.0, 4.0, 500.0, 960.0)

metric_got : List(F64)
metric_got = [metrics.bx, metrics.by, metrics.ht, metrics.foliage, metrics.apex_y, metrics.w]

metric_want : List(F64)
metric_want = [480.0, 600.0, 1000.0, 648.0, (-488.0), 288.0]

trunk : List(Paint.DrawCmd)
trunk = Tree.draw_trunk(metrics, False)

trunk_got : List(F64)
trunk_got = (List.get(trunk, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).pts

trunk_want : List(F64)
trunk_want = [440.0, 110.0, 520.0, 110.0, 520.0, 600.0, 440.0, 600.0]

trunk_tag_got : List(I64)
trunk_tag_got = (
	{
		r = Tree.draw_trunk(metrics, True)
		[(List.get(trunk, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).tag, (List.get(r, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).tag, (List.get(trunk, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).color, (List.get(r, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).color, (List.get(r, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).pts.len().to_i64_wrap()]
	}
)

trunk_tag_want : List(I64)
trunk_tag_want = [0, 1, 5914146, 5914146, 8]

trunk_strength_got : List(F64)
trunk_strength_got = [(List.get(trunk, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).strength, (List.get(Tree.draw_trunk(metrics, True), I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).strength]

trunk_strength_want : List(F64)
trunk_strength_want = [0.0, 1.0]

tri_got : List(F64)
tri_got = List.concat((List.get(Tree.tier_triangle(metrics, 0, 7), I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).pts, (List.get(Tree.tier_triangle(metrics, 7, 7), I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).pts)

tri_want : List(F64)
tri_want = [480.0, (-488.0), 580.8, (-293.6), 379.2, (-293.6), 480.0, (-34.4), 768.0, 160.0, 192.0, 160.0]

pt : F64, F64 -> Camera.ScreenPt
pt = |x, y| { x: x, y: y }

xy : List(Camera.ScreenPt) -> List(F64)
xy = |ps| Paint.flatten_screen(ps)

square : List(Camera.ScreenPt)
square = [pt(0.0, 0.0), pt(4.0, 0.0), pt(4.0, 4.0), pt(0.0, 4.0), pt(2.0, 2.0), pt(2.0, 0.0)]

square_got : List(F64)
square_got = xy(Tree.convex_hull_pts(square))

square_want : List(F64)
square_want = [0.0, 0.0, 4.0, 0.0, 4.0, 4.0, 0.0, 4.0]

tri3_got : List(F64)
tri3_got = xy(Tree.convex_hull_pts([pt(0.0, 0.0), pt(4.0, 0.0), pt(2.0, 3.0)]))

tri3_want : List(F64)
tri3_want = [0.0, 0.0, 4.0, 0.0, 2.0, 3.0]

line_got : List(F64)
line_got = xy(Tree.convex_hull_pts([pt(0.0, 0.0), pt(1.0, 1.0), pt(2.0, 2.0), pt(3.0, 3.0)]))

line_want : List(F64)
line_want = [0.0, 0.0, 3.0, 3.0]

short_got : List(F64)
short_got = List.join([xy(Tree.convex_hull_pts([pt(1.0, 2.0), pt(0.0, 0.0)])), xy(Tree.convex_hull_pts([pt(9.0, 9.0)])), xy(Tree.convex_hull_pts([]))])

short_want : List(F64)
short_want = [1.0, 2.0, 0.0, 0.0, 9.0, 9.0]

dup_got : List(F64)
dup_got = xy(Tree.convex_hull_pts([pt(0.0, 0.0), pt(0.0, 0.0), pt(4.0, 0.0), pt(4.0, 4.0)]))

dup_want : List(F64)
dup_want = [0.0, 0.0, 4.0, 0.0, 4.0, 4.0]

count_got : List(I64)
count_got = [Tree.convex_hull_pts(square).len().to_i64_wrap(), Tree.convex_hull_pts([pt(0.0, 0.0), pt(4.0, 0.0), pt(2.0, 3.0)]).len().to_i64_wrap(), Tree.convex_hull_pts([pt(0.0, 0.0), pt(1.0, 1.0), pt(2.0, 2.0), pt(3.0, 3.0)]).len().to_i64_wrap(), Tree.convex_hull_pts([pt(1.0, 2.0), pt(0.0, 0.0)]).len().to_i64_wrap(), Tree.convex_hull_pts([pt(0.0, 0.0), pt(0.0, 0.0), pt(4.0, 0.0), pt(4.0, 4.0)]).len().to_i64_wrap()]

count_want : List(I64)
count_want = [4, 3, 2, 2, 3]

sorted_got : List(F64)
sorted_got = xy(Tree.sort_pts(square, 0, []))

sorted_want : List(F64)
sorted_want = [0.0, 0.0, 0.0, 4.0, 2.0, 0.0, 2.0, 2.0, 4.0, 0.0, 4.0, 4.0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "tr-table ",
			got: table_got,
			want: table_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "tr-size  ",
			got: size_got,
			want: size_want,
		}),
		Grade.reals({
			name: "tr-frac  ",
			got: frac_got,
			want: frac_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tr-metric",
			got: metric_got,
			want: metric_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tr-trunk ",
			got: trunk_got,
			want: trunk_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "tr-ttag  ",
			got: trunk_tag_got,
			want: trunk_tag_want,
		}),
		Grade.reals({
			name: "tr-tstr  ",
			got: trunk_strength_got,
			want: trunk_strength_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tr-tri   ",
			got: tri_got,
			want: tri_want,
			tol: F64.from_bits(4472406533629990549),
		}),
		Grade.reals({
			name: "tr-square",
			got: square_got,
			want: square_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tr-tri3  ",
			got: tri3_got,
			want: tri3_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tr-line  ",
			got: line_got,
			want: line_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tr-short ",
			got: short_got,
			want: short_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tr-dup   ",
			got: dup_got,
			want: dup_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "tr-count ",
			got: count_got,
			want: count_want,
		}),
		Grade.reals({
			name: "tr-sorted",
			got: sorted_got,
			want: sorted_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
