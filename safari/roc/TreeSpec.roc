# TreeSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Camera
import Grade
import Paint
import Text
import Tree

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

table_got : List(F64)
table_got = List.concat(List.concat(Tree.tier_top, Tree.tier_bot), Tree.tier_wide)

table_want : List(F64)
table_want = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 0.35, 0.44, 0.53, 0.63, 0.72, 0.81, 0.91, 1.0]

size_got : List(I64)
size_got = [U64.to_i64_wrap(List.len(Tree.tier_top)), U64.to_i64_wrap(List.len(Tree.tier_bot)), U64.to_i64_wrap(List.len(Tree.tier_wide)), Tree.ring_n, Tree.trunk_color]

size_want : List(I64)
size_want = [8, 8, 8, 16, 5914146]

frac_got : List(F64)
frac_got = [Tree.visible_trunk, Tree.crown_h, Tree.crown_w, Tree.min_cone_forward]

frac_want : List(F64)
frac_want = [0.44, 0.648, 0.288, 0.4]

m : Tree.Metrics
m = Tree.metrics(0.0, 2.0, 4.0, 500.0, 960.0)

metric_got : List(F64)
metric_got = [m.bx, m.by, m.ht, m.foliage, m.apex_y, m.w]

metric_want : List(F64)
metric_want = [480.0, 600.0, 1000.0, 648.0, (-488.0), 288.0]

trunk : List(Paint.DrawCmd)
trunk = Tree.draw_trunk(m, False)

trunk_got : List(F64)
trunk_got = (List.get(trunk, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).pts

trunk_want : List(F64)
trunk_want = [440.0, 110.0, 520.0, 110.0, 520.0, 600.0, 440.0, 600.0]

trunk_tag_got : List(I64)
trunk_tag_got = ({
	r = Tree.draw_trunk(m, True)
	[(List.get(trunk, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).tag, (List.get(r, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).tag, (List.get(trunk, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).color, (List.get(r, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).color, U64.to_i64_wrap(List.len((List.get(r, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).pts))]
})

trunk_tag_want : List(I64)
trunk_tag_want = [0, 1, 5914146, 5914146, 8]

trunk_strength_got : List(F64)
trunk_strength_got = [(List.get(trunk, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).strength, (List.get(Tree.draw_trunk(m, True), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).strength]

trunk_strength_want : List(F64)
trunk_strength_want = [0.0, 1.0]

tri_got : List(F64)
tri_got = List.concat((List.get(Tree.tier_triangle(m, 0, 7), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).pts, (List.get(Tree.tier_triangle(m, 7, 7), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).pts)

tri_want : List(F64)
tri_want = [480.0, (-488.0), 580.8, (-293.6), 379.2, (-293.6), 480.0, (-34.4), 768.0, 160.0, 192.0, 160.0]

p : F64, F64 -> Camera.ScreenPt
p = |x, y| { x: x, y: y }

xy : List(Camera.ScreenPt) -> List(F64)
xy = |ps| Paint.flatten_screen(ps, 0)

square : List(Camera.ScreenPt)
square = [p(0.0, 0.0), p(4.0, 0.0), p(4.0, 4.0), p(0.0, 4.0), p(2.0, 2.0), p(2.0, 0.0)]

square_got : List(F64)
square_got = xy(Tree.convex_hull_pts(square))

square_want : List(F64)
square_want = [0.0, 0.0, 4.0, 0.0, 4.0, 4.0, 0.0, 4.0]

tri3_got : List(F64)
tri3_got = xy(Tree.convex_hull_pts([p(0.0, 0.0), p(4.0, 0.0), p(2.0, 3.0)]))

tri3_want : List(F64)
tri3_want = [0.0, 0.0, 4.0, 0.0, 2.0, 3.0]

line_got : List(F64)
line_got = xy(Tree.convex_hull_pts([p(0.0, 0.0), p(1.0, 1.0), p(2.0, 2.0), p(3.0, 3.0)]))

line_want : List(F64)
line_want = [0.0, 0.0, 3.0, 3.0]

short_got : List(F64)
short_got = List.concat(List.concat(xy(Tree.convex_hull_pts([p(1.0, 2.0), p(0.0, 0.0)])), xy(Tree.convex_hull_pts([p(9.0, 9.0)]))), xy(Tree.convex_hull_pts([])))

short_want : List(F64)
short_want = [1.0, 2.0, 0.0, 0.0, 9.0, 9.0]

dup_got : List(F64)
dup_got = xy(Tree.convex_hull_pts([p(0.0, 0.0), p(0.0, 0.0), p(4.0, 0.0), p(4.0, 4.0)]))

dup_want : List(F64)
dup_want = [0.0, 0.0, 4.0, 0.0, 4.0, 4.0]

count_got : List(I64)
count_got = [U64.to_i64_wrap(List.len(Tree.convex_hull_pts(square))), U64.to_i64_wrap(List.len(Tree.convex_hull_pts([p(0.0, 0.0), p(4.0, 0.0), p(2.0, 3.0)]))), U64.to_i64_wrap(List.len(Tree.convex_hull_pts([p(0.0, 0.0), p(1.0, 1.0), p(2.0, 2.0), p(3.0, 3.0)]))), U64.to_i64_wrap(List.len(Tree.convex_hull_pts([p(1.0, 2.0), p(0.0, 0.0)]))), U64.to_i64_wrap(List.len(Tree.convex_hull_pts([p(0.0, 0.0), p(0.0, 0.0), p(4.0, 0.0), p(4.0, 4.0)])))]

count_want : List(I64)
count_want = [4, 3, 2, 2, 3]

sorted_got : List(F64)
sorted_got = xy(Tree.sort_pts(square, 0, []))

sorted_want : List(F64)
sorted_want = [0.0, 0.0, 0.0, 4.0, 2.0, 0.0, 2.0, 2.0, 4.0, 0.0, 4.0, 4.0]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_reals([14, 21, 73, 14, 15, 32, 23, 13, 2], table_got, table_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([14, 21, 73, 19, 17, 38, 13, 2, 2], size_got, size_want)))
	line!(Text.printed(Grade.grade_reals([14, 21, 73, 28, 21, 15, 24, 2, 2], frac_got, frac_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([14, 21, 73, 26, 13, 14, 21, 17, 24], metric_got, metric_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([14, 21, 73, 14, 21, 25, 18, 34, 2], trunk_got, trunk_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([14, 21, 73, 14, 14, 15, 29, 2, 2], trunk_tag_got, trunk_tag_want)))
	line!(Text.printed(Grade.grade_reals([14, 21, 73, 14, 19, 14, 21, 2, 2], trunk_strength_got, trunk_strength_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([14, 21, 73, 14, 21, 17, 2, 2, 2], tri_got, tri_want, F64.from_bits(4472406533629990549))))
	line!(Text.printed(Grade.grade_reals([14, 21, 73, 19, 37, 25, 15, 21, 13], square_got, square_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([14, 21, 73, 14, 21, 17, 6, 2, 2], tri3_got, tri3_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([14, 21, 73, 23, 17, 18, 13, 2, 2], line_got, line_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([14, 21, 73, 19, 20, 16, 21, 14, 2], short_got, short_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([14, 21, 73, 22, 25, 31, 2, 2, 2], dup_got, dup_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([14, 21, 73, 24, 16, 25, 18, 14, 2], count_got, count_want)))
	line!(Text.printed(Grade.grade_reals([14, 21, 73, 19, 16, 21, 14, 13, 22], sorted_got, sorted_want, 0.0)))
	Ok({})
}
