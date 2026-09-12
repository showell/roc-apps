# TreesSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import ListUtils
import Scenery
import Trees

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

colour_got : List(I64)
colour_got = [Trees.conifer_green, Trees.conifer_gold, Trees.conifer_red, Trees.max_trees]

colour_want : List(I64)
colour_want = [1858082, 13605400, 11680298, 96]

dim_got : List(F64)
dim_got = [Trees.small_height, Trees.big_scale, Trees.tree_spacing, Trees.tree_road_offset, Trees.tree_start_inset, Trees.tree_end_inset]

dim_want : List(F64)
dim_want = [4.5, 1.3, 30.0, 1.5, 6.0, 85.0]

accent_got : List(I64)
accent_got = [Trees.accent_color(AllGreen), Trees.accent_color(YellowGreen), Trees.accent_color(RedGreen)]

accent_want : List(I64)
accent_want = [1858082, 13605400, 11680298]

hx_got : List(F64)
hx_got = [Trees.tree_height_for(1858082, True), Trees.tree_height_for(1858082, False), Trees.tree_height_for(11680298, True), Trees.tree_height_for(11680298, False), Trees.tree_height_for(13605400, True), Trees.tree_height_for(13605400, False), Trees.tree_x_for(1858082), Trees.tree_x_for(11680298), Trees.tree_x_for(13605400)]

hx_want : List(F64)
hx_want = [5.8500000000000005, 4.5, 11.700000000000001, 9.0, 17.55, 13.5, 3.5, 3.5, 8.0]

filled : List(Scenery.Tree)
filled = Trees.fill_trees(YellowGreen, 300.0, Trees.tree_start_inset, 0, 0)

along_got : List(F64)
along_got = ListUtils.list_map(lam_0, filled)

along_want : List(F64)
along_want = [6.0, 6.0, 36.0, 36.0, 66.0, 66.0, 96.0, 96.0, 126.0, 126.0, 156.0, 156.0, 186.0, 186.0]

across_got : List(F64)
across_got = ListUtils.list_map(lam_1, filled)

across_want : List(F64)
across_want = [(-3.5), 3.5, (-8.0), 8.0, (-3.5), 3.5, (-8.0), 8.0, (-3.5), 3.5, (-8.0), 8.0, (-3.5), 3.5]

colours_got : List(I64)
colours_got = ListUtils.list_map(lam_2, filled)

colours_want : List(I64)
colours_want = [1858082, 1858082, 13605400, 13605400, 1858082, 1858082, 13605400, 13605400, 1858082, 1858082, 13605400, 13605400, 1858082, 1858082]

heights_got : List(F64)
heights_got = ListUtils.list_map(lam_3, filled)

heights_want : List(F64)
heights_want = [5.8500000000000005, 5.8500000000000005, 13.5, 13.5, 5.8500000000000005, 5.8500000000000005, 13.5, 13.5, 5.8500000000000005, 5.8500000000000005, 13.5, 13.5, 5.8500000000000005, 5.8500000000000005]

stops_got : List(I64)
stops_got = [U64.to_i64_wrap(List.len(filled)), U64.to_i64_wrap(List.len(Trees.fill_trees(AllGreen, 100.0, Trees.tree_start_inset, 0, 0))), U64.to_i64_wrap(List.len(Trees.fill_trees(AllGreen, 5000.0, Trees.tree_start_inset, 0, 0))), U64.to_i64_wrap(List.len(Trees.fill_trees(AllGreen, 50.0, Trees.tree_start_inset, 0, 0)))]

stops_want : List(I64)
stops_want = [14, 2, 96, 0]

lam_0 : Scenery.Tree -> F64
lam_0 = |t| t.along

lam_1 : Scenery.Tree -> F64
lam_1 = |t| t.across

lam_2 : Scenery.Tree -> I64
lam_2 = |t| t.color

lam_3 : Scenery.Tree -> F64
lam_3 = |t| t.height

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_ints("tr-colour", colour_got, colour_want))
	line!(Grade.grade_reals("tr-dim   ", dim_got, dim_want, 0.0))
	line!(Grade.grade_ints("tr-accent", accent_got, accent_want))
	line!(Grade.grade_reals("tr-hx    ", hx_got, hx_want, 0.0))
	line!(Grade.grade_reals("tr-along ", along_got, along_want, 0.0))
	line!(Grade.grade_reals("tr-across", across_got, across_want, 0.0))
	line!(Grade.grade_ints("tr-colours", colours_got, colours_want))
	line!(Grade.grade_reals("tr-height", heights_got, heights_want, 0.0))
	line!(Grade.grade_ints("tr-stops ", stops_got, stops_want))
	Ok({})
}
