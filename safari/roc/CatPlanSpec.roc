# CatPlanSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CatPlan
import Frame
import Grade
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

chain : List(I64)
chain = [0, 1, 2]

origin : Frame.Pose
origin = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

has_got : List(Bool)
has_got = [(List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).has_cat, (List.get(segs, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).has_cat, (List.get(segs, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).has_cat]

has_want : List(Bool)
has_want = [False, True, False]

gap_got : List(F64)
gap_got = [CatPlan.chain_gap(segs, chain, 0.0, 0), CatPlan.chain_gap(segs, chain, 0.0, 1), CatPlan.chain_gap(segs, chain, 0.0, 2), CatPlan.chain_gap(segs, chain, 120.0, 0), CatPlan.chain_gap(segs, chain, 120.0, 1), CatPlan.chain_gap(segs, chain, 120.0, 2)]

gap_want : List(F64)
gap_want = [0.0, 500.0, 820.0, (-120.0), 380.0, 700.0]

riding : F64 -> List(CatPlan.CatItem)
riding = |a| CatPlan.walk_cats(segs, chain, { along: a, across: 0.0, yaw: 0.0, hw: 2.0 }, 500.0, a, 1.0, 0)

seen : List(CatPlan.CatItem)
seen = riding(300.0)

count_got : List(I64)
count_got = [U64.to_i64_wrap(List.len(seen)), U64.to_i64_wrap(List.len(CatPlan.seg_cat(segs, chain, origin, 0, 500.0, 0.0, 1.0))), U64.to_i64_wrap(List.len(CatPlan.seg_cat(segs, chain, origin, 2, 500.0, 0.0, 1.0))), CatPlan.max_vis_cats]

count_want : List(I64)
count_want = [1, 0, 0, 8]

place_got : List(F64)
place_got = [(List.get(seen, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).height, (List.get(seen, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).lift]

place_want : List(F64)
place_want = [1.7, 0.0]

pose_got : List(I64)
pose_got = [(List.get(seen, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).pose_idx]

pose_want : List(I64)
pose_want = [0]

closing_got : List(F64)
closing_got = ({
	a = (List.get(riding(200.0), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).fwd
	b = (List.get(riding(300.0), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).fwd
	c = (List.get(riding(400.0), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).fwd
	[(b - a), (c - b), ((List.get(riding(300.0), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).right - (List.get(riding(200.0), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).right)]
})

closing_want : List(F64)
closing_want = [(-100.0), (-100.0), 0.0]

cull_got : List(I64)
cull_got = [U64.to_i64_wrap(List.len(riding(0.0))), U64.to_i64_wrap(List.len(riding(200.0))), U64.to_i64_wrap(List.len(riding(500.0))), U64.to_i64_wrap(List.len(riding(600.0))), U64.to_i64_wrap(List.len(CatPlan.walk_cats(segs, [], origin, 500.0, 0.0, 1.0, 0))), U64.to_i64_wrap(List.len(CatPlan.walk_cats(segs, [0], origin, 500.0, 0.0, 1.0, 0)))]

cull_want : List(I64)
cull_want = [0, 1, 1, 0, 0, 0]

items_got : List(I64)
items_got = [U64.to_i64_wrap(List.len(CatPlan.cat_items(seen, 0))), U64.to_i64_wrap(List.len(CatPlan.cat_items([], 0))), (List.get(CatPlan.cat_items(seen, 0), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).i]

items_want : List(I64)
items_want = [1, 0, 0]

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_bools("cp-has   ", has_got, has_want))
	line!(Grade.grade_reals("cp-gap   ", gap_got, gap_want, 0.0))
	line!(Grade.grade_ints("cp-count ", count_got, count_want))
	line!(Grade.grade_reals("cp-place ", place_got, place_want, 0.0))
	line!(Grade.grade_ints("cp-pose  ", pose_got, pose_want))
	line!(Grade.grade_reals("cp-close ", closing_got, closing_want, 0.0001))
	line!(Grade.grade_ints("cp-cull  ", cull_got, cull_want))
	line!(Grade.grade_ints("cp-items ", items_got, items_want))
	Ok({})
}
