# TreePlanSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Frame
import Grade
import Text
import TreePlan
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

chain : List(I64)
chain = [0, 1, 2]

origin : Frame.Pose
origin = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

up_road : Frame.Pose
up_road = { along: 100.0, across: 0.0, yaw: 0.0, hw: 2.0 }

planted_got : List(I64)
planted_got = [U64.to_i64_wrap(List.len((List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).trees)), U64.to_i64_wrap(List.len((List.get(segs, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).trees)), U64.to_i64_wrap(List.len((List.get(segs, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).trees)), TreePlan.max_vis_trees]

planted_want : List(I64)
planted_want = [28, 16, 22, 640]

one : List(TreePlan.TreeItem)
one = TreePlan.place_tree(segs, chain, origin, 0, 500.0, 2.0, { along: 120.0, across: 3.5, color: 1858082, height: 5.85 })

one_got : List(F64)
one_got = [(List.get(one, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).right, (List.get(one, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).fwd, (List.get(one, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).height]

one_want : List(F64)
one_want = [3.5, 120.0, 5.85]

one_colour_got : List(I64)
one_colour_got = [U64.to_i64_wrap(List.len(one)), (List.get(one, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).color]

one_colour_want : List(I64)
one_colour_want = [1, 1858082]

cull_got : List(I64)
cull_got = [U64.to_i64_wrap(List.len(TreePlan.place_tree(segs, chain, origin, 0, 500.0, 2.0, { along: 0.4, across: 3.5, color: 1858082, height: 5.85 }))), U64.to_i64_wrap(List.len(TreePlan.place_tree(segs, chain, origin, 0, 500.0, 2.0, { along: 0.5, across: 3.5, color: 1858082, height: 5.85 }))), U64.to_i64_wrap(List.len(TreePlan.place_tree(segs, chain, origin, 0, 1.0, 2.0, { along: 120.0, across: 3.5, color: 1858082, height: 5.85 }))), U64.to_i64_wrap(List.len(TreePlan.place_tree(segs, chain, origin, 0, 500.0, 2.0, { along: 2000.0, across: 3.5, color: 1858082, height: 5.85 })))]

cull_want : List(I64)
cull_want = [0, 1, 0, 0]

seg0_got : List(I64)
seg0_got = [U64.to_i64_wrap(List.len(TreePlan.seg_trees(segs, chain, origin, 0, 500.0, 2.0, (List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).trees, 0))), U64.to_i64_wrap(List.len(TreePlan.seg_trees(segs, chain, up_road, 0, 500.0, 2.0, (List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).trees, 0))), U64.to_i64_wrap(List.len(TreePlan.seg_trees(segs, chain, origin, 0, 1.0, 2.0, (List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).trees, 0)))]

seg0_want : List(I64)
seg0_want = [28, 20, 0]

order_got : List(F64)
order_got = ({
	ts = TreePlan.seg_trees(segs, chain, origin, 0, 500.0, 2.0, (List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).trees, 0)
	[(List.get(ts, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).fwd, (List.get(ts, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).fwd, (List.get(ts, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).fwd, (List.get(ts, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).right, (List.get(ts, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).right]
})

order_want : List(F64)
order_want = [6.0, 6.0, 36.0, (-3.5), 3.5]

height_got : List(F64)
height_got = ({
	ts = TreePlan.seg_trees(segs, chain, origin, 0, 500.0, 2.0, (List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).trees, 0)
	[(List.get(ts, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).height, (List.get(ts, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).height]
})

height_want : List(F64)
height_want = [5.85, 4.5]

items_got : List(I64)
items_got = ({
	ts = TreePlan.seg_trees(segs, chain, origin, 0, 500.0, 2.0, (List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).trees, 0)
	its = TreePlan.tree_items(ts, 0)
	[U64.to_i64_wrap(List.len(its)), (List.get(its, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).i, (List.get(its, I64.to_u64_wrap(27)) ?? crash("list-at out of range")).i, U64.to_i64_wrap(List.len(TreePlan.tree_items([], 0)))]
})

items_want : List(I64)
items_want = [28, 0, 27, 0]

item_fwd_got : List(F64)
item_fwd_got = ({
	its = TreePlan.tree_items(TreePlan.seg_trees(segs, chain, origin, 0, 500.0, 2.0, (List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).trees, 0), 0)
	[(List.get(its, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).fwd, (List.get(its, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).fwd]
})

item_fwd_want : List(F64)
item_fwd_want = [6.0, 36.0]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_ints([14, 13, 73, 31, 23, 15, 18, 14, 2], planted_got, planted_want)))
	line!(Text.printed(Grade.grade_reals([14, 13, 73, 16, 18, 13, 2, 2, 2], one_got, one_want, 0.0001)))
	line!(Text.printed(Grade.grade_ints([14, 13, 73, 24, 16, 23, 16, 25, 21], one_colour_got, one_colour_want)))
	line!(Text.printed(Grade.grade_ints([14, 13, 73, 24, 25, 23, 23, 2, 2], cull_got, cull_want)))
	line!(Text.printed(Grade.grade_ints([14, 13, 73, 19, 13, 29, 3, 2, 2], seg0_got, seg0_want)))
	line!(Text.printed(Grade.grade_reals([14, 13, 73, 16, 21, 22, 13, 21, 2], order_got, order_want, 0.0001)))
	line!(Text.printed(Grade.grade_reals([14, 13, 73, 20, 13, 17, 29, 20, 14], height_got, height_want, F64.from_bits(4427486594234968593))))
	line!(Text.printed(Grade.grade_ints([14, 13, 73, 17, 14, 13, 26, 19, 2], items_got, items_want)))
	line!(Text.printed(Grade.grade_reals([14, 13, 73, 17, 28, 27, 22, 2, 2], item_fwd_got, item_fwd_want, 0.0001)))
	Ok({})
}
