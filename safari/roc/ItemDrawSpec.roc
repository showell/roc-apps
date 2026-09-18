# ItemDrawSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Frame
import Grade
import ItemDraw
import SceneLimits
import Text
import TowerPlan
import TreePlan
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

fixed_got : List(F64)
fixed_got = [SceneLimits.crown_shade_dist, SceneLimits.detail_dist]

fixed_want : List(F64)
fixed_want = [80.0, 200.0]

tree_at : F64 -> TreePlan.TreeItem
tree_at = |fwd| { right: 0.0, fwd: fwd, height: 5.85, color: 1858082 }

spread : List(TreePlan.TreeItem)
spread = [tree_at(10.0), tree_at(20.0), tree_at(30.0), tree_at(40.0), tree_at(50.0)]

count_got : List(I64)
count_got = [ItemDraw.closer_count(spread, 10.0, 0), ItemDraw.closer_count(spread, 30.0, 0), ItemDraw.closer_count(spread, 50.0, 0), ItemDraw.closer_count(spread, 60.0, 0), ItemDraw.closer_count(spread, 5.0, 0), ItemDraw.closer_count([], 10.0, 0)]

count_want : List(I64)
count_want = [0, 2, 4, 5, 0, (6 - 6)]

tied : List(TreePlan.TreeItem)
tied = [tree_at(20.0), tree_at(20.0), tree_at(20.0), tree_at(20.0)]

tie_got : List(I64)
tie_got = [ItemDraw.closer_count(tied, 20.0, 0), ItemDraw.closer_count(tied, 20.1, 0), ItemDraw.closer_count(tied, 19.9, 0)]

tie_want : List(I64)
tie_want = [0, 4, 0]

shade_got : List(F64)
shade_got = [ItemDraw.crown_shade_of(0.0), ItemDraw.crown_shade_of(20.0), ItemDraw.crown_shade_of(40.0), ItemDraw.crown_shade_of(80.0), ItemDraw.crown_shade_of(200.0), ItemDraw.crown_shade_of((0.0 - 50.0))]

shade_want : List(F64)
shade_want = [1.0, 0.75, 0.5, 0.0, 0.0, 1.0]

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

chain : List(I64)
chain = [0, 1, 2]

origin : Frame.Pose
origin = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

a_tower : TowerPlan.TowerItem
a_tower = { map: Frame.chain_map(0), a0: 200.0, x0: 22.0, yaw: 0.0, fwd: 200.0, off: 0.0 }

base_got : List(I64)
base_got = [U64.to_i64_wrap(List.len(ItemDraw.tower_base(segs, chain, origin, a_tower, 0))), U64.to_i64_wrap(List.len(ItemDraw.tower_base(segs, chain, origin, { map: Frame.chain_map(0), a0: 200.0, x0: 22.0, yaw: 1.0, fwd: 200.0, off: 0.0 }, 0)))]

base_want : List(I64)
base_want = [4, 4]

corner_got : List(F64)
corner_got = ({
	b = ItemDraw.tower_base(segs, chain, origin, a_tower, 0)
	[(List.get(b, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).forward, (List.get(b, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).forward, (List.get(b, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).right, (List.get(b, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).right]
})

corner_want : List(F64)
corner_want = [194.0, 206.0, 14.0, 26.0]

drawn : F64 -> I64
drawn = |a0| U64.to_i64_wrap(List.len(ItemDraw.draw_one_tower(segs, chain, origin, { map: Frame.chain_map(0), a0: a0, x0: 22.0, yaw: 0.0, fwd: a0, off: 0.0 }, 500.0, 0.0)))

tower_got : List(Bool)
tower_got = [(drawn(200.0) > 0), (drawn(1000.0) > 0), (drawn((0.0 - 100.0)) == 0)]

tower_want : List(Bool)
tower_want = [True, True, True]

cluster : List(TreePlan.TreeItem)
cluster = [tree_at(10.0), tree_at(11.0), tree_at(12.0), tree_at(13.0), tree_at(14.0)]

tree_got : List(Bool)
tree_got = ({
	near = ItemDraw.draw_one_tree(cluster, 0, 500.0)
	far = ItemDraw.draw_one_tree(cluster, 4, 500.0)
	near_tier = U64.to_i64_wrap(List.len((List.get(near, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).pts))
	far_tier = U64.to_i64_wrap(List.len((List.get(far, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).pts))
	[(U64.to_i64_wrap(List.len(near)) > 0), (U64.to_i64_wrap(List.len(far)) > 0), (near_tier > far_tier), (far_tier >= 6)]
})

tree_want : List(Bool)
tree_want = [True, True, True, True]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_reals([17, 22, 73, 28, 17, 36, 13, 22, 2], fixed_got, fixed_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([17, 22, 73, 24, 16, 25, 18, 14, 2], count_got, count_want)))
	line!(Text.printed(Grade.grade_ints([17, 22, 73, 14, 17, 13, 2, 2, 2], tie_got, tie_want)))
	line!(Text.printed(Grade.grade_reals([17, 22, 73, 19, 20, 15, 22, 13, 2], shade_got, shade_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([17, 22, 73, 32, 15, 19, 13, 2, 2], base_got, base_want)))
	line!(Text.printed(Grade.grade_reals([17, 22, 73, 24, 16, 21, 18, 13, 21], corner_got, corner_want, 0.0001)))
	line!(Text.printed(Grade.grade_bools([17, 22, 73, 14, 16, 27, 13, 21, 2], tower_got, tower_want)))
	line!(Text.printed(Grade.grade_bools([17, 22, 73, 14, 21, 13, 13, 2, 2], tree_got, tree_want)))
	Ok({})
}
